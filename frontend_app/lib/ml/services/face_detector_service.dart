import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FaceDetectorService {
  FaceDetector? _faceDetector;
  bool _isProcessing = false;

  void initialize() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Face>> detectFacesFromCameraImage(
      CameraImage image, 
      CameraController controller, 
      List<CameraDescription> cameras
  ) async {
    if (_faceDetector == null || _isProcessing) return [];
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image, controller, cameras);
      if (inputImage == null) {
        _isProcessing = false;
        return [];
      }
      
      final faces = await _faceDetector!.processImage(inputImage);
      _isProcessing = false;
      return faces;
    } catch (e) {
      print("Error detecting faces: $e");
      _isProcessing = false;
      return [];
    }
  }

  InputImage? _inputImageFromCameraImage(
      CameraImage image, 
      CameraController controller, 
      List<CameraDescription> cameras
  ) {
    try {
      final camera = controller.description.lensDirection == CameraLensDirection.back 
          ? cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back)
          : cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);
          
      final sensorOrientation = camera.sensorOrientation;
      
      InputImageRotation rotation = InputImageRotationValue.fromRawValue(sensorOrientation) 
          ?? InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) 
          ?? InputImageFormat.nv21;

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (e) {
      print("Error converting camera image: $e");
      return null;
    }
  }

  void dispose() {
    _faceDetector?.close();
  }
}
