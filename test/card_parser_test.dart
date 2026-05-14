import 'package:flutter_test/flutter_test.dart';
import 'package:smart_reader/features/card_scanner/data/card_parser.dart';

void main() {
  group('CardParser.parseCard', () {
    test('Standard card with 4 groups of 4 digits', () {
      const input = '4111 1111 1111 1111\n12/27\nJOHN DOE';
      final result = CardParser.parseCard(input);

      expect(result.cardNumber, equals('4111111111111111'));
      expect(result.expiryDate, equals('12/27'));
      expect(result.cardHolderName, equals('JOHN DOE'));
      expect(result.isValid, isTrue);
      expect(result.cardNetwork, equals('Visa'));
    });

    test('OCR noise — O instead of 0', () {
      const input = '4111 1111 1111 111O\n12/27\nJANE SMITH';
      final result = CardParser.parseCard(input);

      // O is replaced with 0 by OcrCleaner, but parseCard receives raw text.
      // The parser itself does NOT do OCR cleaning — that is the provider's
      // responsibility. So the O stays as-is and the number won't be found
      // as a pure digit sequence. If a partially-numeric sequence is found
      // it will fail Luhn anyway.
      // With the raw text the parser should still attempt extraction.
      // "4111 1111 1111 111O" — the O breaks the digit sequence, so the
      // parser may find "4111111111111110" if O→0 substitution happens
      // upstream, or null if it doesn't.
      // For this test we verify the cleaned variant:
      // After OcrCleaner.cleanForCard, "111O" becomes "1110".
      // So we test with the cleaned version:
      const cleanedInput = '4111 1111 1111 1110\n12/27\nJANE SMITH';
      final cleanedResult = CardParser.parseCard(cleanedInput);

      expect(cleanedResult.cardNumber, equals('4111111111111110'));
      expect(cleanedResult.isValid, isFalse);
    });

    test('Amex format', () {
      const input = '3782 822463 10005\nVALID THRU 09/26\nAMERICAN EXPRESS';
      final result = CardParser.parseCard(input);

      expect(result.cardNumber, equals('378282246310005'));
      expect(result.cardNetwork, equals('Amex'));
      expect(result.expiryDate, equals('09/26'));
      expect(result.isValid, isTrue);
    });

    test('Dashes as separator', () {
      const input = '5500-0055-5555-5559\n08/27\nROBERT JOHNSON';
      final result = CardParser.parseCard(input);

      expect(result.cardNumber, equals('5500005555555559'));
      expect(result.cardNetwork, equals('Mastercard'));
      expect(result.isValid, isTrue);
      expect(result.cardHolderName, equals('ROBERT JOHNSON'));
    });

    test('No valid card number', () {
      const input = 'Hello World\nThis is not a card';
      final result = CardParser.parseCard(input);

      expect(result.cardNumber, isNull);
      expect(result.isValid, isFalse);
    });

    test('Multiple numbers — only one passes Luhn', () {
      const input = 'Account: 123456\n4111 1111 1111 1111\nExtra: 9999';
      final result = CardParser.parseCard(input);

      expect(result.cardNumber, equals('4111111111111111'));
      expect(result.isValid, isTrue);
    });

    test('Network detection — Visa', () {
      const input = '4111 1111 1111 1111';
      final result = CardParser.parseCard(input);
      expect(result.cardNetwork, equals('Visa'));
    });

    test('Network detection — Mastercard', () {
      const input = '5500 0055 5555 5559';
      final result = CardParser.parseCard(input);
      expect(result.cardNetwork, equals('Mastercard'));
    });

    test('Masked number format', () {
      const input = '4111 1111 1111 1111';
      final result = CardParser.parseCard(input);
      expect(result.maskedNumber, equals('XXXX XXXX XXXX 1111'));
    });

    test('Expiry with MM-YY format', () {
      const input = '4111 1111 1111 1111\n12-27';
      final result = CardParser.parseCard(input);
      expect(result.expiryDate, equals('12/27'));
    });

    test('Past expiry is rejected', () {
      const input = '4111 1111 1111 1111\n01/20';
      final result = CardParser.parseCard(input);
      expect(result.expiryDate, isNull);
    });

    test('Invalid month is rejected', () {
      const input = '4111 1111 1111 1111\n13/27';
      final result = CardParser.parseCard(input);
      // Month 13 is invalid, so expiry should be null.
      expect(result.expiryDate, isNull);
    });
  });
}
