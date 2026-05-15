import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final file = File('web/icons/banking-system.png');
  if (!file.existsSync()) {
    print('File not found.');
    return;
  }
  final bytes = file.readAsBytesSync();
  final original = img.decodeImage(bytes);
  if (original == null) {
    print('Failed to decode image.');
    return;
  }
  
  // 1. Crop original into a perfect circle
  final size = min(original.width, original.height);
  final circularOriginal = img.Image(width: size, height: size, numChannels: 4);
  img.fill(circularOriginal, color: img.ColorRgba8(255, 255, 255, 0)); // Transparent
  
  final r = size / 2.0;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - r + 0.5;
      final dy = y - r + 0.5;
      if (dx * dx + dy * dy <= r * r) {
        circularOriginal.setPixel(x, y, original.getPixel(x, y));
      }
    }
  }

  // 2. Create Android foreground:
  // Android adaptive mask is a 72dp circle inside a 108dp canvas (which is 66.6% or 1/1.5).
  // If we want the circular image to EXACTLY fit the circular mask, 
  // we use a canvas exactly 1.5x larger than the image.
  int androidSize = (size * 1.5).round();
  final androidPadded = img.Image(width: androidSize, height: androidSize, numChannels: 4);
  img.fill(androidPadded, color: img.ColorRgba8(255, 255, 255, 0)); // Transparent background
  int androidDst = (androidSize - size) ~/ 2;
  img.compositeImage(androidPadded, circularOriginal, dstX: androidDst, dstY: androidDst);
  File('web/icons/banking-system-android.png').writeAsBytesSync(img.encodePng(androidPadded));
  
  // 3. Create iOS padded image:
  // iOS doesn't allow transparency. So we will give it a white background.
  // We'll pad it very slightly (e.g. 1.05x) so the circle doesn't hit the squircle edges.
  int iosSize = (size * 1.05).round();
  final iosPadded = img.Image(width: iosSize, height: iosSize, numChannels: 4);
  img.fill(iosPadded, color: img.ColorRgba8(255, 255, 255, 255)); // White background
  int iosDst = (iosSize - size) ~/ 2;
  img.compositeImage(iosPadded, circularOriginal, dstX: iosDst, dstY: iosDst);
  File('web/icons/banking-system-ios.png').writeAsBytesSync(img.encodePng(iosPadded));
  
  print('Circular padded images saved.');
}
