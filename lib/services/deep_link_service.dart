import 'dart:async';

import 'package:app_links/app_links.dart';

import '../utils/validation.dart';

/// A recognized `nodusprotocol://` deep link. Sealed so every handler
/// switch is exhaustively checked by the analyzer.
sealed class AppDeepLink {
  const AppDeepLink();
}

/// `nodusprotocol://pool` — open the (single) AMM pool's detail screen.
class PoolPositionLink extends AppDeepLink {
  const PoolPositionLink();
}

/// `nodusprotocol://pay?to=<address>&amount=<decimal>&token=<symbol>`
class PaymentRequestLink extends AppDeepLink {
  const PaymentRequestLink({
    required this.to,
    required this.amount,
    required this.token,
  });

  final String to;
  final String amount;
  final String token;
}

/// Parses a URI into a recognized [AppDeepLink], or null if it isn't one
/// of ours or is missing/has invalid required data. Pure function, kept
/// separate from [DeepLinkService] so it's unit testable without a real
/// platform channel.
AppDeepLink? parseDeepLink(Uri uri) {
  if (uri.scheme != 'nodusprotocol') return null;

  switch (uri.host) {
    case 'pool':
      return const PoolPositionLink();

    case 'pay':
      final to = uri.queryParameters['to'];
      final amount = uri.queryParameters['amount'];
      final token = uri.queryParameters['token'];
      if (to == null || amount == null || token == null) return null;
      if (Validation.stellarPublicKey(to) != null) return null;
      final parsedAmount = double.tryParse(amount);
      if (parsedAmount == null || parsedAmount <= 0) return null;
      return PaymentRequestLink(to: to, amount: amount, token: token);

    default:
      return null;
  }
}

/// Wraps app_links so the app can react to `nodusprotocol://` links.
/// Constructed once, early (see main()), so the plugin can capture the
/// link that launched the app from a cold start; every link received
/// since construction -- including that one -- is buffered and replayed
/// once to whoever first listens to [links], so a listener created later
/// (e.g. only after the user unlocks the app) still sees it.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks() {
    _subscription = _appLinks.uriLinkStream.listen(_onUri);
  }

  final AppLinks _appLinks;
  final List<AppDeepLink> _buffered = [];
  final _controller = StreamController<AppDeepLink>.broadcast();
  late final StreamSubscription<Uri> _subscription;

  void _onUri(Uri uri) {
    final link = parseDeepLink(uri);
    if (link == null) return;
    _buffered.add(link);
    _controller.add(link);
  }

  /// Every deep link received since this service was created, replayed
  /// once, followed by any new ones as they arrive.
  Stream<AppDeepLink> get links async* {
    for (final link in List.of(_buffered)) {
      yield link;
    }
    yield* _controller.stream;
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}
