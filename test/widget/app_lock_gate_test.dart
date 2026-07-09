import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodus_protocol/providers/wallet_provider.dart';
import 'package:nodus_protocol/widgets/app_lock_gate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Same MethodChannel mock as wallet_provider_test.dart: no platform
  // implementation exists in the test environment, so _restoreSession()
  // must resolve to "no session found" instead of throwing.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (_) async => null);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Widget wrap(WalletProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        home: AppLockGate(child: Text('protected content')),
      ),
    );
  }

  testWidgets('shows a loading state before the session restore resolves',
      (tester) async {
    final provider = WalletProvider();

    // Deliberately a single pumpWidget with no follow-up pump: the very
    // first frame is built synchronously, before _restoreSession()'s first
    // await has had a chance to resolve, so isRestoring must still be true.
    await tester.pumpWidget(wrap(provider));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('protected content'), findsNothing);

    // Let the pending restore future resolve so it doesn't leak a
    // microtask into the next test.
    await tester.pumpAndSettle();
  });

  testWidgets(
      'passes straight through to the child when no session is restored',
      (tester) async {
    final provider = WalletProvider();

    await tester.pumpWidget(wrap(provider));
    await tester.pumpAndSettle();

    expect(provider.state, WalletState.disconnected);
    expect(find.text('protected content'), findsOneWidget);
  });
}
