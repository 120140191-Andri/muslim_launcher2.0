import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class EyeTrackerService {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  bool _isFocused = false;
  final _focusController = StreamController<bool>.broadcast();

  Stream<bool> get focusStream => _focusController.stream;
  bool get isFocused => _isFocused;

  Future<void> initialize() async {
    final cameras = await availableCameras();
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
        enableClassification: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    await _cameraController?.initialize();
    _cameraController?.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
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
        // Simple heuristic: Euler Y (horizontal rotation) near 0 means looking forward
        // Stricter heuristic: Euler Y (horizontal) and Z (tilt) < 12 degrees
        final double? eulerY = face.headEulerAngleY; // Rotation around Y axis
        final double? eulerZ = face.headEulerAngleZ; // Tilt around Z axis

        final bool currentlyFocused =
            (eulerY != null && eulerY.abs() < 5) &&
            (eulerZ != null && eulerZ.abs() < 5);

        if (_isFocused != currentlyFocused) {
          _isFocused = currentlyFocused;
          _focusController.add(_isFocused);
        }
      } else {
        // No face detected at all
        if (_isFocused) {
          _isFocused = false;
          _focusController.add(false);
        }
      }
    } catch (e) {
      debugPrint("Face detection error: $e");
    }

    _isBusy = false;
  }

  Future<void> dispose() async {
    if (_cameraController?.value.isStreamingImages ?? false) {
      await _cameraController?.stopImageStream();
    }
    await _cameraController?.dispose();
    await _faceDetector?.close();
    await _focusController.close();
  }
}
