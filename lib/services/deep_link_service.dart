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
