import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Opens the [direction] camera with a frame format ML Kit can read.
/// Throws [CameraException] (e.g. `CameraAccessDenied`) when unavailable.
Future<CameraController> openVisaCamera(CameraLensDirection direction, {ResolutionPreset? preset}) async {
  final cameras = await availableCameras();
  if (cameras.isEmpty) throw CameraException('NoCamera', 'No camera found on this device.');
  final camera = cameras.firstWhere((c) => c.lensDirection == direction, orElse: () => cameras.first);
  final controller = CameraController(
    camera,
    preset ?? ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
  );
  await controller.initialize();
  await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
  return controller;
}

InputImage? visaInputImage(CameraImage image, CameraDescription camera) {
  final rotation =
      InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  if (rotation == null) return null;
  if (image.planes.isEmpty) return null;

  final size = Size(image.width.toDouble(), image.height.toDouble());

  if (Platform.isIOS) {
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // Android — handle both NV21 (1 plane) and YUV_420_888 (3 planes).
  final rawFormat = image.format.raw;
  final parsed = InputImageFormatValue.fromRawValue(rawFormat);

  if (parsed == InputImageFormat.nv21 && image.planes.length == 1) {
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // YUV_420_888 or any multi-plane format: concatenate all planes.
  final allBytes = WriteBuffer();
  for (final plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  return InputImage.fromBytes(
    bytes: allBytes.done().buffer.asUint8List(),
    metadata: InputImageMetadata(
      size: size,
      rotation: rotation,
      format: parsed ?? InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
    ),
  );
}
/// Why a selfie is not a usable visa photo, or null when it is.
String? visaSelfieProblem(List<Face> faces, Size imageSize) {
  if (faces.isEmpty) return 'No face found. Use a clear photo of your face.';
  if (faces.length > 1) return 'Only one person should be in the photo.';
  final f = faces.first;
  final box = f.boundingBox;
  final shortSide = imageSize.width < imageSize.height ? imageSize.width : imageSize.height;
  if (box.width < shortSide * 0.25) return 'Move closer so your face fills the circle.';
  if ((f.headEulerAngleY ?? 0).abs() > 12 || (f.headEulerAngleZ ?? 0).abs() > 12) {
    return 'Look straight at the camera.';
  }
  final left = f.leftEyeOpenProbability, right = f.rightEyeOpenProbability;
  if (left != null && right != null && (left < 0.5 || right < 0.5)) return 'Keep both eyes open.';
  return null;
}

FaceDetector visaFaceDetector({bool accurate = false}) => FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: accurate ? FaceDetectorMode.accurate : FaceDetectorMode.fast,
        minFaceSize: 0.2,
      ),
    );
