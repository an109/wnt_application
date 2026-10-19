import 'dart:ui';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';

export 'package:google_mlkit_commons/google_mlkit_commons.dart';

enum FaceDetectorMode { accurate, fast }

class FaceDetectorOptions {
  final bool enableClassification;
  final FaceDetectorMode performanceMode;
  final double minFaceSize;
  FaceDetectorOptions({
    this.enableClassification = false,
    this.performanceMode = FaceDetectorMode.fast,
    this.minFaceSize = 0.1,
  });
}

class Face {
  final Rect boundingBox;
  final double? headEulerAngleY;
  final double? headEulerAngleZ;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  Face(this.boundingBox, {this.headEulerAngleY, this.headEulerAngleZ, this.leftEyeOpenProbability, this.rightEyeOpenProbability});
}

/// Simulator-only stub: never detects a face.
class FaceDetector {
  FaceDetector({required FaceDetectorOptions options});
  Future<List<Face>> processImage(InputImage inputImage) async => <Face>[];
  Future<void> close() async {}
}
