import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reader/main.dart';

void main() {
  testWidgets('Smart Reader app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartReaderApp());
    expect(find.text('Smart Reader'), findsOneWidget);
  });
}
