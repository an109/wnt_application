import 'package:google_mlkit_commons/google_mlkit_commons.dart';

export 'package:google_mlkit_commons/google_mlkit_commons.dart';

enum TextRecognitionScript { latin, chinese, devanagiri, japanese, korean }

class TextBlock {}

class RecognizedText {
  final String text;
  final List<TextBlock> blocks;
  RecognizedText(this.text, this.blocks);
}

/// Simulator-only stub: never recognises any text.
class TextRecognizer {
  TextRecognizer({TextRecognitionScript script = TextRecognitionScript.latin});
  Future<RecognizedText> processImage(InputImage inputImage) async => RecognizedText('', <TextBlock>[]);
  Future<void> close() async {}
}
