import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nodus_protocol/screens/qr_scanner_screen.dart';

void main() {
  group('firstValidRawValue', () {
    test('returns the raw value of a single decoded barcode', () {
      final barcodes = [const Barcode(rawValue: 'GABCDEF')];
      expect(firstValidRawValue(barcodes), 'GABCDEF');
    });

    test('skips barcodes with a null raw value', () {
      final barcodes = [
        const Barcode(),
        const Barcode(rawValue: 'GABCDEF'),
      ];
      expect(firstValidRawValue(barcodes), 'GABCDEF');
    });

    test('skips barcodes with an empty raw value', () {
      final barcodes = [
        const Barcode(rawValue: ''),
        const Barcode(rawValue: 'GABCDEF'),
      ];
      expect(firstValidRawValue(barcodes), 'GABCDEF');
    });

    test('returns null when nothing decoded to usable text', () {
      final barcodes = [const Barcode(), const Barcode(rawValue: '')];
      expect(firstValidRawValue(barcodes), isNull);
    });

    test('returns null for an empty capture', () {
      expect(firstValidRawValue(const []), isNull);
    });

    test('returns the first valid value when multiple barcodes decode',
        () {
      final barcodes = [
        const Barcode(rawValue: 'FIRST'),
        const Barcode(rawValue: 'SECOND'),
      ];
      expect(firstValidRawValue(barcodes), 'FIRST');
    });
  });
}
