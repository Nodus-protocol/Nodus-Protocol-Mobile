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

/// Gates access behind the device's biometric (Face ID / fingerprint)
/// enrollment. Every method fails closed to `false` on error rather than
/// throwing, so callers can treat "unavailable" and "denied" the same way.
class BiometricService {
  BiometricService({BiometricAuthenticator? authenticator})
      : _authenticator = authenticator ?? LocalAuthAuthenticator();

  final BiometricAuthenticator _authenticator;

  /// Whether this device has biometrics enrolled and usable right now.
  Future<bool> isAvailable() async {
    try {
      return await _authenticator.isSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user for biometric authentication. Returns `false` on
  /// cancellation, lockout, or any platform error instead of throwing, so
  /// the caller can offer a retry rather than crash the lock screen.
  Future<bool> authenticate() async {
    try {
      return await _authenticator.authenticate();
    } catch (_) {
      return false;
    }
  }
}
