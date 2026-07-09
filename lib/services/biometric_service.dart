import 'package:local_auth/local_auth.dart';

/// Abstraction over [LocalAuthentication] so [BiometricService] can be
/// exercised in tests with a fake instead of local_auth's platform channel.
abstract class BiometricAuthenticator {
  Future<bool> isSupported();

  Future<bool> authenticate();
}

/// Default [BiometricAuthenticator] backed by the real local_auth plugin.
class LocalAuthAuthenticator implements BiometricAuthenticator {
  LocalAuthAuthenticator() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> isSupported() async {
    final deviceSupported = await _localAuth.isDeviceSupported();
    final hasBiometrics = await _localAuth.canCheckBiometrics;
    return deviceSupported && hasBiometrics;
  }

  @override
  Future<bool> authenticate() {
    return _localAuth.authenticate(
      localizedReason: 'Unlock Nodus Protocol to access your wallet',
      options: const AuthenticationOptions(stickyAuth: true),
    );
  }
}
