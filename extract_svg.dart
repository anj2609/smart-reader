import 'dart:io';
import 'dart:convert';

void main() {
  final svgText = File('web/icons/banking-system.svg').readAsStringSync();
  final base64Pattern = RegExp(r'href="data:image/png;base64,([^"]+)"');
  final match = base64Pattern.firstMatch(svgText);
  if (match != null) {
    final base64String = match.group(1)!;
    final bytes = base64Decode(base64String);
    File('web/icons/banking-system-extracted.png').writeAsBytesSync(bytes);
    print('Successfully extracted PNG from SVG.');
  } else {
    print('Failed to find base64 data.');
  }
}
