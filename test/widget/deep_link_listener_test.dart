import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodus_protocol/screens/payment_request_screen.dart';
import 'package:nodus_protocol/services/deep_link_service.dart';
import 'package:nodus_protocol/widgets/deep_link_listener.dart';

// Only the payment-request path is covered here: the pool-position path
// reads PoolProvider, which has no test seam (it always constructs a
// real, network-backed PoolService), so it isn't exercised at the
// widget level -- reviewed by hand instead.
void main() {
  testWidgets('pushes PaymentRequestScreen for a payment request link',
      (tester) async {
    final controller = StreamController<AppDeepLink>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DeepLinkListener(
          linkStream: controller.stream,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );

    controller.add(
      const PaymentRequestLink(to: 'GABC', amount: '10', token: 'XLM'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PaymentRequestScreen), findsOneWidget);
    expect(find.text('10 XLM'), findsOneWidget);
  });

  testWidgets('does not navigate when no link has arrived', (tester) async {
    final controller = StreamController<AppDeepLink>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        home: DeepLinkListener(
          linkStream: controller.stream,
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.byType(PaymentRequestScreen), findsNothing);
  });
}
