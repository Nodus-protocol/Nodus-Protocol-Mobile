import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown when the app is opened via a `nodusprotocol://pay` deep link.
/// This app has no peer-to-peer send flow yet, so this is a read-only
/// preview of the request -- amount, token, and requester address, with
/// a copy action -- rather than something that can be fulfilled in-app.
class PaymentRequestScreen extends StatelessWidget {
  const PaymentRequestScreen({
    super.key,
    required this.to,
    required this.amount,
    required this.token,
  });

  final String to;
  final String amount;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Request')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.request_page_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              "You've been asked to send:",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$amount $token',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              'To address',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white60),
            ),
            const SizedBox(height: 4),
            SelectableText(
              to,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy address'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: to));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address copied'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
