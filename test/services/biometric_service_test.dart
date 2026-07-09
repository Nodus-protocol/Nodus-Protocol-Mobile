import 'package:flutter_test/flutter_test.dart';
import 'package:nodus_protocol/services/biometric_service.dart';

class _FakeAuthenticator implements BiometricAuthenticator {
  _FakeAuthenticator({
    this.supported = true,
    this.authenticateResult = true,
    this.throwOnIsSupported = false,
    this.throwOnAuthenticate = false,
  });

  final bool supported;
  final bool authenticateResult;
  final bool throwOnIsSupported;
  final bool throwOnAuthenticate;
  int authenticateCalls = 0;

  @override
  Future<bool> isSupported() async {
    if (throwOnIsSupported) throw StateError('platform error');
    return supported;
  }

  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    if (throwOnAuthenticate) throw StateError('platform error');
    return authenticateResult;
  }
}

void main() {
  group('BiometricService.isAvailable', () {
    test('reflects the authenticator when supported', () async {
      final service =
          BiometricService(authenticator: _FakeAuthenticator());
      expect(await service.isAvailable(), isTrue);
    });

    test('reflects the authenticator when unsupported', () async {
      final service = BiometricService(
        authenticator: _FakeAuthenticator(supported: false),
      );
      expect(await service.isAvailable(), isFalse);
    });

    test('fails closed to false when the authenticator throws', () async {
      final service = BiometricService(
        authenticator: _FakeAuthenticator(throwOnIsSupported: true),
      );
      expect(await service.isAvailable(), isFalse);
    });
  });

  group('BiometricService.authenticate', () {
    test('returns true on a successful prompt', () async {
      final service = BiometricService(authenticator: _FakeAuthenticator());
      expect(await service.authenticate(), isTrue);
    });

    test('returns false when the prompt is denied or cancelled', () async {
      final service = BiometricService(
        authenticator: _FakeAuthenticator(authenticateResult: false),
      );
      expect(await service.authenticate(), isFalse);
    });

    test('fails closed to false when the authenticator throws', () async {
      final service = BiometricService(
        authenticator: _FakeAuthenticator(throwOnAuthenticate: true),
      );
      expect(await service.authenticate(), isFalse);
    });

    test('delegates every call through to the authenticator', () async {
      final authenticator = _FakeAuthenticator();
      final service = BiometricService(authenticator: authenticator);

      await service.authenticate();
      await service.authenticate();

      expect(authenticator.authenticateCalls, 2);
    });
  });
}
