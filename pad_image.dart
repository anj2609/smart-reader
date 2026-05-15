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
  
  // Create Android padded image (generous padding to prevent zooming/cropping)
  // Android adaptive icons have a 108dp canvas and 72dp safe zone. 
  // Canvas = 2.0x means icon is 50% of the canvas, fitting nicely in the safe zone.
  int androidWidth = (original.width * 2.0).round();
  int androidHeight = (original.height * 2.0).round();
  final androidPadded = img.Image(width: androidWidth, height: androidHeight, numChannels: 4);
  img.fill(androidPadded, color: img.ColorRgba8(255, 255, 255, 255));
  int androidDstX = (androidWidth - original.width) ~/ 2;
  int androidDstY = (androidHeight - original.height) ~/ 2;
  img.compositeImage(androidPadded, original, dstX: androidDstX, dstY: androidDstY);
  File('web/icons/banking-system-android.png').writeAsBytesSync(img.encodePng(androidPadded));
  
  // Create iOS padded image (moderate padding)
  // Canvas = 1.35x means icon is 74% of the canvas, fitting iOS squircles well.
  int iosWidth = (original.width * 1.35).round();
  int iosHeight = (original.height * 1.35).round();
  final iosPadded = img.Image(width: iosWidth, height: iosHeight, numChannels: 4);
  img.fill(iosPadded, color: img.ColorRgba8(255, 255, 255, 255));
  int iosDstX = (iosWidth - original.width) ~/ 2;
  int iosDstY = (iosHeight - original.height) ~/ 2;
  img.compositeImage(iosPadded, original, dstX: iosDstX, dstY: iosDstY);
  File('web/icons/banking-system-ios.png').writeAsBytesSync(img.encodePng(iosPadded));
  
  print('Android and iOS padded images saved.');
}
