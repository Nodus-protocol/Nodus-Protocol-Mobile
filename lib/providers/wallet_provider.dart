import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';

import '../models/auth_token.dart';
import '../services/auth_service.dart';

enum WalletState { disconnected, connecting, connected, error }

class WalletProvider extends ChangeNotifier {
  WalletProvider() {
    _restoreSession();
  }

  static const _keyAddress = 'stellar_address';
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  WalletState _state = WalletState.disconnected;
  String? _address;
  String? _accessToken;
  String? _error;
  Map<String, double> _balances = {};
  bool _isRestoring = true;

  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  WalletState get state => _state;
  String? get address => _address;
  String? get accessToken => _accessToken;
  String? get error => _error;
  Map<String, double> get balances => _balances;

  /// True until the initial secure-storage lookup on startup resolves.
  /// Callers gating sensitive UI (e.g. the biometric lock screen) should
  /// wait for this to go false before deciding what to show, so a restored
  /// session is never rendered unprotected for even one frame.
  bool get isRestoring => _isRestoring;

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_keyAddress);
    final token = await _secureStorage.read(key: _keyAccess);

    if (address != null && token != null) {
      _address = address;
      _accessToken = token;
      _state = WalletState.connected;
    }
    _isRestoring = false;
    notifyListeners();
  }

  /// Authenticates via SEP-10 using the provided Stellar secret key.
  /// The secret key is used locally only to sign the challenge — it is never
  /// transmitted to the server or stored on device.
  Future<void> connect(String secretKey) async {
    _state = WalletState.connecting;
    _error = null;
    notifyListeners();

    try {
      final keypair = KeyPair.fromSecretSeed(secretKey);
      final AuthToken token = await _authService.authenticateWithStellar(keypair);

      // Store address in SharedPreferences (non-sensitive)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAddress, keypair.accountId);
      
      // Store tokens in secure storage (sensitive)
      await _secureStorage.write(key: _keyAccess, value: token.accessToken);
      await _secureStorage.write(key: _keyRefresh, value: token.refreshToken);

      _address = keypair.accountId;
      _accessToken = token.accessToken;
      _balances = {'XLM': 0.0, 'USDC': 0.0};
      _state = WalletState.connected;
    } on ArgumentError {
      _error = 'Invalid secret key. Make sure you entered a valid Stellar secret key (starts with S).';
      _state = WalletState.error;
    } on FormatException {
      _error = 'Invalid secret key. Make sure you entered a valid Stellar secret key (starts with S).';
      _state = WalletState.error;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _state = WalletState.error;
    }

    notifyListeners();
  }

  /// Disconnects the wallet by:
  /// 1. Calling backend logout to invalidate the JWT token
  /// 2. Clearing secure storage (tokens)
  /// 3. Clearing SharedPreferences (non-sensitive data)
  /// 4. Resetting local state
  Future<void> disconnect() async {
    // 1. Notify backend first (while we still have the token)
    // This blacklists the JWT to prevent unauthorized access
    if (_accessToken != null) {
      await _authService.logout(_accessToken!);
    }

    // 2. Clear secure storage (tokens)
    await _secureStorage.delete(key: _keyAccess);
    await _secureStorage.delete(key: _keyRefresh);

    // 3. Clear non-sensitive SharedPreferences  
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAddress);

    // 4. Reset local state
    _address = null;
    _accessToken = null;
    _balances = {};
    _error = null;
    _state = WalletState.disconnected;
    notifyListeners();
  }
}
