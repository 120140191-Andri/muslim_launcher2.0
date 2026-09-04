import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class EyeTrackerService {
  static final EyeTrackerService _instance = EyeTrackerService._internal();
  factory EyeTrackerService() => _instance;
  EyeTrackerService._internal();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  InputImageRotation _cameraRotation = InputImageRotation.rotation270deg;
  bool _isBusy = false;
  bool _isFocused = false;
  bool _isFacePresent = false;
  bool _isInitializing = false;
  int _lastProcessTime = 0;
  int _consecutiveUnfocusedFrames = 0;
  // ~750ms grace period (3 frames at 250ms interval) to allow natural human blinks (150-300ms)
  // without fluttering or interrupting reading
  static const int _unfocusedGraceFrames = 3;

  Future<void>? _lock;
  StreamController<bool>? _focusController;
  StreamController<bool>? _facePresenceController;

  Stream<bool>? get focusStream => _focusController?.stream;
  Stream<bool>? get facePresenceStream => _facePresenceController?.stream;
  bool get isFocused => _isFocused;
  bool get isFacePresent => _isFacePresent;
  bool get isCameraReady => _cameraController != null && _cameraController!.value.isInitialized;

  static InputImageRotation _rotationFromSensorOrientation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
      default:
        return InputImageRotation.rotation270deg;
    }
  }

  /// Evaluates whether a detected face is actively focused on reading the screen.
  /// Specially calibrated to be inclusive of all facial geometries and eye shapes,
  /// particularly monolid / epicanthic fold / narrow eyes ("mata sipit") looking downward
  /// at a phone screen.
  static bool evaluateFaceFocus({
    double? eulerY,
    double? eulerZ,
    double? leftEyeOpenProb,
    double? rightEyeOpenProb,
    bool hasEyeLandmarks = false,
    bool facePresent = true,
  }) {
    if (!facePresent) return false;

    // 1. Head Orientation:
    // Natural reading posture allows up to 28° yaw (reading left to right / right to left)
    // and up to 25° roll (relaxed head tilt).
    // If Euler angles are null, treat as acceptable.
    final bool yawOk = eulerY == null || eulerY.abs() <= 28.0;
    final bool rollOk = eulerZ == null || eulerZ.abs() <= 25.0;
    if (!yawOk || !rollOk) return false;

    // 2. Eye Openness Evaluation:
    // Normal wide open eyes: 0.70 - 0.99
    // Open narrow/monolid eyes looking downward: 0.15 - 0.38
    // Monocular vision (keterbatasan 1 mata / eye patch): one eye is open, other eye is 0.00 or null
    // Truly closed eyes (sleeping, prolonged eye closure): both < 0.12
    if (leftEyeOpenProb != null && rightEyeOpenProb != null) {
      final double maxProb = math.max(leftEyeOpenProb, rightEyeOpenProb);
      final double avgProb = (leftEyeOpenProb + rightEyeOpenProb) / 2.0;

      // Regular check: either eye is clearly open (>= 0.18)
      // This automatically supports 1-eye users because maxProb evaluates the working eye!
      if (maxProb >= 0.18) return true;

      // Inclusivity for narrow eyes or 1-eye users with downward gaze:
      // If landmarks are confirmed and the working eye reaches >= 0.14, user is focused.
      if (hasEyeLandmarks && (maxProb >= 0.14 || avgProb >= 0.13)) return true;

      // Both eyes (or the single working eye) are closed (< 0.14)
      return false;
    } else if (leftEyeOpenProb != null) {
      // Single eye detected (e.g. eye patch covering other eye)
      return leftEyeOpenProb >= (hasEyeLandmarks ? 0.14 : 0.18);
    } else if (rightEyeOpenProb != null) {
      return rightEyeOpenProb >= (hasEyeLandmarks ? 0.14 : 0.18);
    }

    // Fallback if device does not support classification:
    // Rely on eye landmarks or face presence facing the screen
    return hasEyeLandmarks || facePresent;
  }

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    // Ensure we wait for any existing operations (like a pending dispose)
    if (_lock != null) {
      try {
        await _lock!.timeout(const Duration(seconds: 3));
      } catch (_) {} // Ignore timeout
    }

    final Completer<void> completer = Completer<void>();
    _lock = completer.future;

    try {
      // 1. Verify/Request camera permission
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final req = await Permission.camera.request();
        if (!req.isGranted) {
          debugPrint("EyeTrackerService: Camera permission not granted ($req)");
          _isFacePresent = true; // Graceful fallback mode if permission denied
          return;
        }
      }

      // Release existing resources if any (synchronous check)
      if (_cameraController != null || _faceDetector != null) {
        await _disposeInternal();
      }
      
      _isFocused = false;
      _isFacePresent = false;
      _isBusy = false;
      _consecutiveUnfocusedFrames = 0;
      
      _focusController = StreamController<bool>.broadcast();
      _facePresenceController = StreamController<bool>.broadcast();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _isFacePresent = true;
        return;
      }

      final frontCam = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraRotation = _rotationFromSensorOrientation(frontCam.sensorOrientation);

      // Medium resolution gives significantly better facial landmark & eye resolution
      // for monolid/narrow eyes without noticeable CPU impact at 4 FPS.
      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

      await _cameraController?.initialize();
      await _cameraController?.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("EyeTrackerService init error: $e");
      await _disposeInternal();
    } finally {
      completer.complete();
      _lock = null;
      _isInitializing = false;
    }
  }

  void _processCameraImage(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // Throttle to ~4 FPS (250ms) to drastically save CPU/GPU and battery
    if (now - _lastProcessTime < 250) return;
    if (_isBusy || _focusController == null || _focusController!.isClosed) return;
    _isBusy = true;
    _lastProcessTime = now;

    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes[0].bytes;
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    }

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _cameraRotation,
      format:
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    try {
      final faces = await _faceDetector?.processImage(inputImage);
      final bool facePresent = faces != null && faces.isNotEmpty;

      // Update Face Presence (for Dzikir mode where eyes can be closed)
      if (_isFacePresent != facePresent) {
        _isFacePresent = facePresent;
        if (_facePresenceController != null && !_facePresenceController!.isClosed) {
          _facePresenceController!.add(_isFacePresent);
        }
      }

      final bool rawFocused;
      if (faces != null && faces.isNotEmpty) {
        final face = faces.first;
        final bool hasEyeLandmarks =
            face.landmarks[FaceLandmarkType.leftEye] != null ||
            face.landmarks[FaceLandmarkType.rightEye] != null;

        rawFocused = evaluateFaceFocus(
          eulerY: face.headEulerAngleY,
          eulerZ: face.headEulerAngleZ,
          leftEyeOpenProb: face.leftEyeOpenProbability,
          rightEyeOpenProb: face.rightEyeOpenProbability,
          hasEyeLandmarks: hasEyeLandmarks,
          facePresent: true,
        );
      } else {
        rawFocused = false;
      }

      // Hysteresis / debouncing:
      // When focused: immediate transition so reading starts/continues with zero lag
      // When unfocused: require 3 consecutive unfocused frames (~750ms) to allow natural blinks
      if (rawFocused) {
        _consecutiveUnfocusedFrames = 0;
        if (!_isFocused) {
          _isFocused = true;
          if (_focusController != null && !_focusController!.isClosed) {
            _focusController!.add(true);
          }
        }
      } else {
        _consecutiveUnfocusedFrames++;
        if (_consecutiveUnfocusedFrames >= _unfocusedGraceFrames) {
          if (_isFocused) {
            _isFocused = false;
            if (_focusController != null && !_focusController!.isClosed) {
              _focusController!.add(false);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    }

    _isBusy = false;
  }

  Future<void> dispose() async {
    // Ensure we wait for any pending init
    int attempts = 0;
    while (_lock != null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    final Completer<void> completer = Completer<void>();
    _lock = completer.future;
    
    try {
      await _disposeInternal();
    } finally {
      completer.complete();
      _lock = null;
    }
  }

  Future<void> _disposeInternal() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          try {
            await _cameraController!.stopImageStream();
          } catch (_) {}
        }
        await _cameraController!.dispose();
      }
      await _faceDetector?.close();
      await _focusController?.close();
      await _facePresenceController?.close();
    } catch (e) {
      debugPrint("EyeTrackerService internal dispose error: $e");
    } finally {
      _cameraController = null;
      _faceDetector = null;
      _focusController = null;
      _facePresenceController = null;
      _isFocused = false;
      _isFacePresent = false;
      _isBusy = false;
      _consecutiveUnfocusedFrames = 0;
      _lastProcessTime = 0;
    }
  }
}

