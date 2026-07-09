import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pool_provider.dart';
import '../screens/payment_request_screen.dart';
import '../screens/pool_detail_screen.dart';
import '../services/deep_link_service.dart';

/// Reacts to deep links by pushing the relevant screen. Deliberately
/// placed as [AppLockGate]'s child rather than wrapping it: this widget
/// -- and its subscription -- doesn't exist in the tree until the gate
/// has actually unlocked, so a deep link can never navigate past the
/// biometric lock. DeepLinkService itself is still constructed early
/// (see main()) so the cold-start launch link isn't lost while the app
/// is still locked; it's buffered there and only acted on once this
/// widget mounts.
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({
    super.key,
    required this.child,
    this.linkStream,
  });

  final Widget child;
  final Stream<AppDeepLink>? linkStream;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  StreamSubscription<AppDeepLink>? _subscription;

  @override
  void initState() {
    super.initState();
    final stream = widget.linkStream ?? DeepLinkService().links;
    _subscription = stream.listen(_onLink);
  }

  Future<void> _onLink(AppDeepLink link) async {
    if (!mounted) return;
    switch (link) {
      case PoolPositionLink():
        final poolProvider = context.read<PoolProvider>();
        if (poolProvider.pools.isEmpty) {
          await poolProvider.loadPools();
        }
        if (!mounted || poolProvider.pools.isEmpty) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PoolDetailScreen(pool: poolProvider.pools.first),
          ),
        );

      case PaymentRequestLink(:final to, :final amount, :final token):
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                PaymentRequestScreen(to: to, amount: amount, token: token),
          ),
        );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
