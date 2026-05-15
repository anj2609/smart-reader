import 'dart:io';
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
  
  // Create a canvas that is 1.6x larger to provide generous padding
  int newWidth = (original.width * 1.6).round();
  int newHeight = (original.height * 1.6).round();
  
  // Create a new image with a white background
  final padded = img.Image(width: newWidth, height: newHeight, numChannels: 4);
  img.fill(padded, color: img.ColorRgba8(255, 255, 255, 255));
  
  // Draw the original image into the center
  int dstX = (newWidth - original.width) ~/ 2;
  int dstY = (newHeight - original.height) ~/ 2;
  
  // compositeImage handles alpha blending
  img.compositeImage(padded, original, dstX: dstX, dstY: dstY);
  
  File('web/icons/banking-system-padded.png').writeAsBytesSync(img.encodePng(padded));
  print('Padded image saved.');
}
