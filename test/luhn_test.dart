import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reader/core/utils/luhn_validator.dart';

void main() {
  group('LuhnValidator.isValidCard', () {
    test('Visa test number is valid', () {
      expect(LuhnValidator.isValidCard('4111111111111111'), isTrue);
    });

    test('Visa test number with spaces is valid', () {
      expect(LuhnValidator.isValidCard('4111 1111 1111 1111'), isTrue);
    });

    test('Amex test number is valid', () {
      expect(LuhnValidator.isValidCard('378282246310005'), isTrue);
    });

    test('Invalid number fails Luhn', () {
      expect(LuhnValidator.isValidCard('1234567890123456'), isFalse);
    });

    test('Empty string returns false', () {
      expect(LuhnValidator.isValidCard(''), isFalse);
    });

    test('Letter O instead of digit returns false', () {
      expect(LuhnValidator.isValidCard('411111111111111O'), isFalse);
    });

    test('Mastercard test number is valid', () {
      expect(LuhnValidator.isValidCard('5500005555555559'), isTrue);
    });

    test('Too short number returns false', () {
      expect(LuhnValidator.isValidCard('123'), isFalse);
    });

    test('Number with dashes is valid', () {
      expect(LuhnValidator.isValidCard('4111-1111-1111-1111'), isTrue);
    });
  });
}
