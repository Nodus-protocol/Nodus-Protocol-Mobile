import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../screens/lock_screen.dart';
import '../services/biometric_service.dart';
import 'loading_overlay.dart';

enum _GateStatus { checking, locked, unlocked }

/// Wraps the app shell and, on launch, requires biometric authentication
/// before revealing it if a wallet session was restored from secure
/// storage. New/disconnected users, and devices with no biometrics
/// enrolled, pass straight through. Fails closed: [child] is only ever
/// shown once the gate has positively decided it doesn't need to lock.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child, this.biometricService});

  final Widget child;
  final BiometricService? biometricService;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  late final BiometricService _biometricService =
      widget.biometricService ?? BiometricService();
  _GateStatus _status = _GateStatus.checking;
  bool _decisionStarted = false;

  Future<void> _decide(WalletState walletState) async {
    if (walletState != WalletState.connected) {
      if (mounted) setState(() => _status = _GateStatus.unlocked);
      return;
    }
    final available = await _biometricService.isAvailable();
    if (!mounted) return;
    setState(() {
      _status = available ? _GateStatus.locked : _GateStatus.unlocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    if (wallet.isRestoring) {
      return const Scaffold(body: LoadingOverlay());
    }

    if (!_decisionStarted) {
      _decisionStarted = true;
      // Deferred a frame: _decide()'s disconnected branch has no `await`
      // before its setState, so calling it inline here would sometimes
      // run synchronously during this very build and crash.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _decide(wallet.state));
    }

    switch (_status) {
      case _GateStatus.checking:
        return const Scaffold(body: LoadingOverlay());
      case _GateStatus.locked:
        return LockScreen(
          biometricService: _biometricService,
          onUnlocked: () => setState(() => _status = _GateStatus.unlocked),
        );
      case _GateStatus.unlocked:
        return widget.child;
    }
  }
}
