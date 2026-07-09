import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodus_protocol/screens/lock_screen.dart';
import 'package:nodus_protocol/services/biometric_service.dart';

class _ScriptedAuthenticator implements BiometricAuthenticator {
  _ScriptedAuthenticator(this._results);

  final List<bool> _results;
  int authenticateCalls = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<bool> authenticate() async {
    final result = _results[authenticateCalls < _results.length
        ? authenticateCalls
        : _results.length - 1];
    authenticateCalls++;
    return result;
  }
}

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('auto-prompts once on first show and unlocks on success',
      (tester) async {
    final authenticator = _ScriptedAuthenticator([true]);
    var unlocked = false;

    await tester.pumpWidget(
      _wrap(
        LockScreen(
          biometricService: BiometricService(authenticator: authenticator),
          onUnlocked: () => unlocked = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 1);
    expect(unlocked, isTrue);
  });

  testWidgets('shows a retry button and failure message on denial',
      (tester) async {
    final authenticator = _ScriptedAuthenticator([false]);

    await tester.pumpWidget(
      _wrap(
        LockScreen(
          biometricService: BiometricService(authenticator: authenticator),
          onUnlocked: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nodus Protocol is locked'), findsOneWidget);
    expect(
      find.text('Authentication failed. Try again to continue.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ElevatedButton, 'Unlock'), findsOneWidget);
  });

  testWidgets('tapping retry re-prompts and unlocks on the second success',
      (tester) async {
    final authenticator = _ScriptedAuthenticator([false, true]);
    var unlocked = false;

    await tester.pumpWidget(
      _wrap(
        LockScreen(
          biometricService: BiometricService(authenticator: authenticator),
          onUnlocked: () => unlocked = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(unlocked, isFalse);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Unlock'));
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 2);
    expect(unlocked, isTrue);
  });
}
