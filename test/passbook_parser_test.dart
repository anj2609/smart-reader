import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reader/features/passbook_scanner/data/passbook_parser.dart';

void main() {
  group('PassbookParser.parsePassbook', () {
    test('Clean passbook text', () {
      const input = '''
STATE BANK OF INDIA
Name: RAMESH KUMAR
Account No: 12345678901
IFSC Code: SBIN0001234
''';
      final result = PassbookParser.parsePassbook(input);

      expect(result.accountHolderName, equals('RAMESH KUMAR'));
      expect(result.accountNumber, equals('12345678901'));
      expect(result.ifscCode, equals('SBIN0001234'));
      expect(result.bankName, equals('State Bank of India'));
    });

    test('Noisy text with multiple numbers', () {
      const input = '''
Branch Code: 001234
HDFC0001234
PRIYA SHARMA
Acc No: 9876543210
Phone: 9876543210
''';
      final result = PassbookParser.parsePassbook(input);

      expect(result.ifscCode, equals('HDFC0001234'));
      expect(result.accountNumber, equals('9876543210'));
      expect(result.accountHolderName, contains('PRIYA SHARMA'));
    });

    test('No IFSC present', () {
      const input = 'Name: AMIT SINGH\nA/C No: 987654321';
      final result = PassbookParser.parsePassbook(input);

      expect(result.ifscCode, isNull);
      expect(result.accountNumber, equals('987654321'));
    });

    test('Account number masking', () {
      const input = '''
Name: TEST USER
Account No: 12345678901
IFSC Code: SBIN0001234
''';
      final result = PassbookParser.parsePassbook(input);

      expect(result.maskedAccount, isNotNull);
      expect(result.maskedAccount!.startsWith('XXXXXXX'), isTrue);
      expect(result.maskedAccount!.endsWith('8901'), isTrue);
    });

    test('Bank name derived from IFSC prefix — HDFC', () {
      const input = 'HDFC0001234\nAccount No: 123456789';
      final result = PassbookParser.parsePassbook(input);

      expect(result.bankName, equals('HDFC Bank'));
    });

    test('Bank name derived from IFSC prefix — ICICI', () {
      const input = 'ICIC0001234\nAccount No: 123456789';
      final result = PassbookParser.parsePassbook(input);

      expect(result.bankName, equals('ICICI Bank'));
    });

    test('Phone number excluded when labelled account exists', () {
      // 9876543210 appears twice — once labelled, once as phone.
      // The labelled one should be picked.
      const input = '''
Acc No: 12345678901234
Mobile: 9876543210
''';
      final result = PassbookParser.parsePassbook(input);

      expect(result.accountNumber, equals('12345678901234'));
    });

    test('No data found returns all nulls', () {
      const input = 'Hello World\nNothing here';
      final result = PassbookParser.parsePassbook(input);

      expect(result.accountNumber, isNull);
      expect(result.ifscCode, isNull);
      expect(result.accountHolderName, isNull);
    });
  });
}
