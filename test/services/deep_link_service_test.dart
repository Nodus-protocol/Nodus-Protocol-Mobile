import 'package:flutter_test/flutter_test.dart';
import 'package:nodus_protocol/services/deep_link_service.dart';

void main() {
  group('parseDeepLink', () {
    test('rejects a different scheme', () {
      expect(parseDeepLink(Uri.parse('https://pool')), isNull);
    });

    test('parses nodusprotocol://pool', () {
      final link = parseDeepLink(Uri.parse('nodusprotocol://pool'));
      expect(link, isA<PoolPositionLink>());
    });

    test('rejects an unrecognized host', () {
      expect(parseDeepLink(Uri.parse('nodusprotocol://unknown')), isNull);
    });

    test('parses a well-formed payment request', () {
      final validAddress = 'G${'A' * 55}';
      final link = parseDeepLink(
        Uri.parse(
          'nodusprotocol://pay?to=$validAddress&amount=25.5&token=USDC',
        ),
      );

      expect(link, isA<PaymentRequestLink>());
      final request = link! as PaymentRequestLink;
      expect(request.to, validAddress);
      expect(request.amount, '25.5');
      expect(request.token, 'USDC');
    });

    test('rejects a payment request missing a required parameter', () {
      final validAddress = 'G${'A' * 55}';
      expect(
        parseDeepLink(
          Uri.parse('nodusprotocol://pay?to=$validAddress&amount=25.5'),
        ),
        isNull,
      );
    });

    test('rejects a payment request with an invalid Stellar address', () {
      expect(
        parseDeepLink(
          Uri.parse('nodusprotocol://pay?to=not-an-address&amount=25.5&token=USDC'),
        ),
        isNull,
      );
    });

    test('rejects a payment request with a non-numeric amount', () {
      final validAddress = 'G${'A' * 55}';
      expect(
        parseDeepLink(
          Uri.parse(
            'nodusprotocol://pay?to=$validAddress&amount=not-a-number&token=USDC',
          ),
        ),
        isNull,
      );
    });

    test('rejects a payment request with a zero or negative amount', () {
      final validAddress = 'G${'A' * 55}';
      expect(
        parseDeepLink(
          Uri.parse('nodusprotocol://pay?to=$validAddress&amount=0&token=USDC'),
        ),
        isNull,
      );
      expect(
        parseDeepLink(
          Uri.parse('nodusprotocol://pay?to=$validAddress&amount=-5&token=USDC'),
        ),
        isNull,
      );
    });
  });
}
