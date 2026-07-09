import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/wallet_provider.dart';
import '../utils/validation.dart';
import '../widgets/transaction_button.dart';
import 'qr_scanner_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _secretKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void dispose() {
    _secretKeyController.dispose();
    super.dispose();
  }

  void _onConnect(WalletProvider provider) {
    final key = _secretKeyController.text.trim();
    final error = Validation.stellarSecretKey(key);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    provider.connect(key);
    _secretKeyController.clear();
  }

  Future<void> _onScanQr() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(title: 'Scan Secret Key'),
      ),
    );
    if (scanned == null) return;

    final trimmed = scanned.trim();
    final error = Validation.stellarSecretKey(trimmed);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned code is not a valid secret key: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _secretKeyController.text = trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.state == WalletState.connected) {
            return _ConnectedView(provider: provider);
          }
          return _ConnectView(
            provider: provider,
            controller: _secretKeyController,
            obscureKey: _obscureKey,
            onToggleObscure: () => setState(() => _obscureKey = !_obscureKey),
            onConnect: () => _onConnect(provider),
            onScanQr: _onScanQr,
          );
        },
      ),
    );
  }
}

class _ConnectView extends StatelessWidget {
  const _ConnectView({
    required this.provider,
    required this.controller,
    required this.obscureKey,
    required this.onToggleObscure,
    required this.onConnect,
    required this.onScanQr,
  });

  final WalletProvider provider;
  final TextEditingController controller;
  final bool obscureKey;
  final VoidCallback onToggleObscure;
  final VoidCallback onConnect;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
    final isConnecting = provider.state == WalletState.connecting;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 56),
          const SizedBox(height: 20),
          Text(
            'Connect your Stellar wallet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your Stellar secret key to authenticate via SEP-10. '
            'Your key is used only to sign the challenge on-device and is never sent to any server.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            obscureText: obscureKey,
            enabled: !isConnecting,
            decoration: InputDecoration(
              labelText: 'Secret Key (S...)',
              hintText: 'SXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    tooltip: 'Scan QR code',
                    onPressed: isConnecting ? null : onScanQr,
                  ),
                  IconButton(
                    icon: Icon(obscureKey ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: onToggleObscure,
                  ),
                ],
              ),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          if (provider.state == WalletState.error && provider.error != null) ...[
            const SizedBox(height: 12),
            Text(
              provider.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          TransactionButton(
            label: 'Connect & Authenticate',
            isLoading: isConnecting,
            onSubmit: isConnecting ? null : onConnect,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Your secret key is never stored or transmitted.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({required this.provider});

  final WalletProvider provider;

  String get _shortAddress {
    final addr = provider.address ?? '';
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.account_circle)),
              title: const Text('Connected Account'),
              subtitle: Text(
                _shortAddress,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy address',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: provider.address ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied'), duration: Duration(seconds: 2)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Balances',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.balances.isEmpty
                ? const Center(child: Text('No balances found', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: provider.balances.length,
                    itemBuilder: (context, index) {
                      final entry = provider.balances.entries.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.token_outlined),
                        title: Text(entry.key),
                        trailing: Text(
                          entry.value.toStringAsFixed(4),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => provider.disconnect(),
              icon: const Icon(Icons.logout),
              label: const Text('Disconnect'),
            ),
          ),
        ],
      ),
    );
  }
}
