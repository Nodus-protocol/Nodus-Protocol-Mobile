/// Abstraction over local_auth's `LocalAuthentication` so [BiometricService]
/// can be exercised in tests with a fake instead of a platform channel.
abstract class BiometricAuthenticator {
  Future<bool> isSupported();

  Future<bool> authenticate();
}
