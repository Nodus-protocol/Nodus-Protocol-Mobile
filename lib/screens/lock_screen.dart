import 'package:flutter/material.dart';

import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

/// Full-screen biometric gate. Auto-prompts once when first shown; on
/// cancellation or failure it falls back to a manual retry button rather
/// than looping the system prompt.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.biometricService,
  });

  final VoidCallback onUnlocked;
  final BiometricService? biometricService;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final BiometricService _biometricService =
      widget.biometricService ?? BiometricService();
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptUnlock());
  }

  Future<void> _attemptUnlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });

    final success = await _biometricService.authenticate();
    if (!mounted) return;

    if (success) {
      setState(() => _authenticating = false);
      widget.onUnlocked();
      return;
    }
    setState(() {
      _authenticating = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nodus Protocol is locked',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? 'Authentication failed. Try again to continue.'
                      : 'Verify your identity to access your wallet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _authenticating ? null : _attemptUnlock,
                  icon: _authenticating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: Text(_authenticating ? 'Verifying...' : 'Unlock'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
