@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Golden baseline tests for core widgets.
//
// These tests are intentionally skipped until their .png baselines are
// committed.  To generate baselines, run:
//
//   flutter test --update-goldens --tags golden
//
// Then remove the `skip:` parameter from each test and commit the generated
// PNG files alongside this file.

void main() {
  group('Golden — PoolCard widget', () {
    testWidgets(
      'renders title and subtitle correctly',
      // ignore: avoid_redundant_argument_values
      skip: true, // Baseline PNG not yet generated; run: flutter test --update-goldens --tags golden
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: Card(
                    child: ListTile(
                      title: const Text('XLM / USDC'),
                      subtitle: const Text('APY: 12.5 %'),
                      trailing: const Text('\$4.2 M TVL'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await expectLater(
          find.byType(Card),
          matchesGoldenFile('goldens/pool_card.png'),
        );
      },
    );
  });

  group('Golden — Bottom navigation bar', () {
    testWidgets(
      'renders all four tabs',
      // ignore: avoid_redundant_argument_values
      skip: true, // Baseline PNG not yet generated; run: flutter test --update-goldens --tags golden
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.waves),
                    label: 'Pools',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.water_drop),
                    label: 'Liquidity',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.swap_horiz),
                    label: 'Swap',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.account_balance_wallet),
                    label: 'Wallet',
                  ),
                ],
              ),
            ),
          ),
        );
        await expectLater(
          find.byType(BottomNavigationBar),
          matchesGoldenFile('goldens/bottom_nav.png'),
        );
      },
    );
  });
}
