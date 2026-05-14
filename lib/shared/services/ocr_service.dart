import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Exception thrown when OCR processing fails.
class OcrException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Creates an [OcrException] with the given [message].
  const OcrException(this.message);

  @override
  String toString() => 'OcrException: $message';
}

/// Wraps Google ML Kit's text recognition to provide a simple OCR interface.
///
/// Usage:
/// ```dart
/// final text = await OcrService.extractText('/path/to/image.jpg');
/// ```
class OcrService {
  OcrService._();

  /// Extracts text from the image at [imagePath] using ML Kit.
  ///
  /// Returns the recognised text as a single string with newlines preserved.
  /// Throws [OcrException] if recognition fails.
  static Future<String> extractText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognisedText = await textRecognizer.processImage(inputImage);
      return recognisedText.text;
    } catch (e) {
      throw OcrException('Text recognition failed: $e');
    } finally {
      textRecognizer.close();
    }
  }

  /// Convenience wrapper that extracts text from an [XFile]
  /// (e.g. returned by [ImagePicker]).
  static Future<String> extractTextFromXFile(XFile file) async {
    return extractText(file.path);
  }
}
