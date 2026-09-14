import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/permission_blocked_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getDeviceInfo') {
        return {'manufacturer': 'Samsung', 'model': 'Galaxy S24', 'sdkInt': 34};
      }
      if (call.method == 'getAppStoragePath') {
        return '/mock/storage';
      }
      return true;
    });
  });

  group('Strict Mode State & Logic Tests', () {
    test('Default mode state defaults to strict mode with 30 days', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);

      expect(state.isStrictMode, isTrue);
      expect(state.strictModeDays, equals(30));
    });

    test('enableStrictMode calculates untilMs and persists correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);

      await state.enableStrictMode(60);

      expect(state.isStrictMode, isTrue);
      expect(state.strictModeDays, equals(60));
      expect(state.isStrictActiveNow, isTrue);
      expect(state.remainingStrictDuration.inDays, inInclusiveRange(59, 60));
      expect(prefs.getBool('is_strict_mode'), isTrue);
      expect(prefs.getInt('strict_mode_days'), equals(60));
    });

    test('enableStandardMode deactivates strict mode', () async {
      SharedPreferences.setMockInitialValues({
        'is_strict_mode': true,
        'strict_mode_days': 30,
        'strict_mode_until_ms': DateTime.now().millisecondsSinceEpoch + 100000,
      });
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);

      expect(state.isStrictActiveNow, isTrue);

      await state.enableStandardMode();

      expect(state.isStrictMode, isFalse);
      expect(state.isStrictActiveNow, isFalse);
      expect(prefs.getBool('is_strict_mode'), isFalse);
    });

    testWidgets('PermissionBlockedOverlay hides continue without protection button in Strict Mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'hasCompletedOnboarding': true,
        'is_strict_mode': true,
        'strict_mode_days': 30,
        'strict_mode_until_ms': DateTime.now().millisecondsSinceEpoch + 86400000,
      });
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionBlockedOverlay(
              appState: state,
              child: const Text('Child Content'),
            ),
          ),
        ),
      );

      // In strict mode, the "Lanjutkan tanpa perlindungan" button must NOT be present
      expect(find.text('Lanjutkan tanpa perlindungan'), findsNothing);
      expect(find.text('Continue without protection'), findsNothing);
    });
  });
}
