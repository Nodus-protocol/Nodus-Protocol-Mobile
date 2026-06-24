import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nodus_protocol/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke tests', () {
    testWidgets('app launches and renders bottom navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Home screen renders the bottom nav bar with all four tabs.
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Pools'), findsOneWidget);
      expect(find.text('Liquidity'), findsOneWidget);
      expect(find.text('Swap'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
    });

    testWidgets('navigating to Swap tab renders swap screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Swap'));
      await tester.pumpAndSettle();

      // The Swap tab index becomes active — verify bottom nav reflects it.
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(2));
    });

    testWidgets('navigating to Liquidity tab renders liquidity screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Liquidity'));
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(1));
    });

    testWidgets('navigating to Wallet tab renders wallet screen',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, equals(3));
    });
  });
}
