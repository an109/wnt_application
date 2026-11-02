import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Prepared copies of a passport photo for OCR, best first:
/// upright full photo, the passport window enlarged, the MRZ band enlarged,
/// then the photo turned a quarter either way (phone held sideways).
///
/// Rotation is taken from the photo's EXIF data, so Android and iOS
/// pictures come out the same way up. Runs in a background isolate.
Future<List<String>> passportOcrVariants(String path) async {
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().microsecondsSinceEpoch;
  return compute(_build, (path, '${dir.path}/passport_$stamp'));
}

List<String> _build((String, String) args) {
  final (path, prefix) = args;
  final decoded = img.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) return const [];
  var upright = img.bakeOrientation(decoded);
  final longest = upright.width > upright.height ? upright.width : upright.height;
  if (longest > 2400) {
    upright = upright.width >= upright.height
        ? img.copyResize(upright, width: 2400, interpolation: img.Interpolation.average)
        : img.copyResize(upright, height: 2400, interpolation: img.Interpolation.average);
  }

  final out = <String>[];
  void save(String name, img.Image image) {
    final file = File('${prefix}_$name.jpg')..writeAsBytesSync(img.encodeJpg(image, quality: 92));
    out.add(file.path);
  }

  save('full', upright);

  // The on-screen frame is a passport-shaped window centred in the preview,
  // 88% of its width; the photo covers at least that area.
  final w = upright.width, h = upright.height;
  final cropW = (w * 0.94).round();
  final cropH = (cropW / 1.42).round().clamp(1, h);
  final window = img.copyCrop(upright, x: (w - cropW) ~/ 2, y: (h - cropH) ~/ 2, width: cropW, height: cropH);
  save('window', img.copyResize(window, width: 2000, interpolation: img.Interpolation.cubic));

  // Bottom 32% of the window: the two MRZ lines, enlarged.
  final bandH = (cropH * 0.32).round();
  final band = img.copyCrop(window, x: 0, y: cropH - bandH, width: cropW, height: bandH);
  save('mrz', img.copyResize(band, width: 2400, interpolation: img.Interpolation.cubic));

  save('rot90', img.copyRotate(upright, angle: 90));
  save('rot270', img.copyRotate(upright, angle: 270));
  return out;
}

/// Deletes the prepared copies once they are no longer needed.
void deletePassportVariants(List<String> paths) {
  for (final p in paths) {
    try {
      File(p).deleteSync();
    } catch (_) {}
  }
}
