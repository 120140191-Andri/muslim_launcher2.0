import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EyeTrackerService {
  static final EyeTrackerService _instance = EyeTrackerService._internal();
  factory EyeTrackerService() => _instance;
  EyeTrackerService._internal();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  bool _isFocused = false;
  bool _isInitializing = false;
  Future<void>? _lock;
  StreamController<bool>? _focusController;

  Stream<bool>? get focusStream => _focusController?.stream;
  bool get isFocused => _isFocused;

  Future<void> initialize() async {
    if (_isInitializing) return;
    _isInitializing = true;

    // Ensure we wait for any existing operations (like a pending dispose)
    // Adding a safety timeout to prevent permanent deadlocks on faulty hardware
    int attempts = 0;
    while (_lock != null && attempts < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    final Completer<void> completer = Completer<void>();
    _lock = completer.future;

    try {
      // Release existing resources if any (synchronous check)
      if (_cameraController != null || _faceDetector != null) {
        await _disposeInternal();
      }
      
      _isFocused = false;
      _isBusy = false;
      
      _focusController = StreamController<bool>.broadcast();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }

      final frontCam = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
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
    if (_isBusy || _focusController == null || _focusController!.isClosed) return;
    _isBusy = true;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation270deg,
      format:
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    try {
      final faces = await _faceDetector?.processImage(inputImage);
      if (faces != null && faces.isNotEmpty) {
        final face = faces.first;
        final double? eulerY = face.headEulerAngleY;
        final double? eulerZ = face.headEulerAngleZ;
        
        final double leftEyeOpenProb = face.leftEyeOpenProbability ?? 1.0;
        final double rightEyeOpenProb = face.rightEyeOpenProbability ?? 1.0;

        // Currently focused if:
        // 1. Face orientation is within 12 degrees (Yaw & Roll)
        // 2. Both eyes are open (Probability > 0.4)
        final bool currentlyFocused =
            (eulerY != null && eulerY.abs() < 12) &&
            (eulerZ != null && eulerZ.abs() < 12) &&
            (leftEyeOpenProb > 0.4 && rightEyeOpenProb > 0.4);

        if (_isFocused != currentlyFocused) {
          _isFocused = currentlyFocused;
          if (_focusController != null && !_focusController!.isClosed) {
            _focusController!.add(_isFocused);
          }
        }
      } else {
        if (_isFocused) {
          _isFocused = false;
          if (_focusController != null && !_focusController!.isClosed) {
            _focusController!.add(false);
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
    } catch (e) {
      debugPrint("EyeTrackerService internal dispose error: $e");
    } finally {
      _cameraController = null;
      _faceDetector = null;
      _focusController = null;
      _isFocused = false;
      _isBusy = false;
    }
  }
}
