import 'dart:typed_data';
import 'dart:ui';

enum InputImageRotation { rotation0deg, rotation90deg, rotation180deg, rotation270deg }

extension InputImageRotationValue on InputImageRotation {
  static InputImageRotation? fromRawValue(int rawValue) {
    switch (rawValue) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
    }
    return null;
  }
}

enum InputImageFormat { nv21, yv12, yuv_420_888, yuv420, bgra8888 }

extension InputImageFormatValue on InputImageFormat {
  static InputImageFormat? fromRawValue(int rawValue) {
    switch (rawValue) {
      case 17:
        return InputImageFormat.nv21;
      case 842094169:
        return InputImageFormat.yv12;
      case 35:
        return InputImageFormat.yuv_420_888;
      case 875704438:
        return InputImageFormat.yuv420;
      case 1111970369:
        return InputImageFormat.bgra8888;
    }
    return null;
  }
}

class InputImageMetadata {
  final Size size;
  final InputImageRotation rotation;
  final InputImageFormat format;
  final int bytesPerRow;
  InputImageMetadata({required this.size, required this.rotation, required this.format, required this.bytesPerRow});
}

class InputImage {
  final String? filePath;
  final Uint8List? bytes;
  final InputImageMetadata? metadata;
  InputImage._(this.filePath, this.bytes, this.metadata);
  factory InputImage.fromFilePath(String path) => InputImage._(path, null, null);
  factory InputImage.fromBytes({required Uint8List bytes, required InputImageMetadata metadata}) =>
      InputImage._(null, bytes, metadata);
}
