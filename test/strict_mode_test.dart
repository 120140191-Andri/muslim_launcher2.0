import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/permission_blocked_overlay.dart';
import 'package:provider/provider.dart';
import 'package:muslim_launcher_2/screens/onboarding/mode_selection_screen.dart';

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

    test('Standard Mode reflection state defaults to false and reacts to dismiss and clear', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);

      expect(state.isStandardReflectionActive, isFalse);
      expect(state.hasActiveOverlay, isFalse);

      // Dismiss and skip
      await state.dismissStandardReflectionAndSkip(durationMillis: 60000);
      expect(state.isStandardReflectionActive, isFalse);

      state.clearStandardReflection();
      expect(state.isStandardReflectionActive, isFalse);
    });

    testWidgets('ModeSelectionScreen prevents switching to Standard Mode when Strict Mode is active', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_strict_mode': true,
        'strict_mode_days': 30,
        'strict_mode_until_ms': DateTime.now().millisecondsSinceEpoch + (30 * 24 * 60 * 60 * 1000),
        'languageCode': 'id',
      });
      final prefs = await SharedPreferences.getInstance();
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: ModeSelectionScreen(isOnboarding: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final standardCard = find.text('Mode Standar');
      await tester.scrollUntilVisible(standardCard, 200);
      await tester.pumpAndSettle();
      expect(standardCard, findsOneWidget);

      await tester.tap(standardCard);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Mode Ketat sedang aktif'), findsOneWidget);
    });

    test('enablePassiveMode deactivates strict mode, sets launcherMode to passive and isAccessibilityRequired to false', () async {
      SharedPreferences.setMockInitialValues({'is_strict_mode': true});
      final prefs = await SharedPreferences.getInstance();
      final state = AppState(prefs);

      await state.enablePassiveMode();
      expect(state.isStrictMode, isFalse);
      expect(state.isPassiveMode, isTrue);
      expect(state.launcherMode, 'passive');
      expect(state.isAccessibilityRequired, isFalse);
      expect(state.hasSelectedMode, isTrue);
      expect(prefs.getString('launcher_mode'), 'passive');
    });

    testWidgets('PermissionBlockedOverlay bypasses blocking completely in Passive Mode', (tester) async {
      SharedPreferences.setMockInitialValues({
        'launcher_mode': 'passive',
        'has_completed_onboarding': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final appState = AppState(prefs);

      await tester.pumpWidget(
        MaterialApp(
          home: PermissionBlockedOverlay(
            appState: appState,
            child: const Text('Normal HomeScreen Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Normal HomeScreen Content'), findsOneWidget);
      expect(find.text('Tindakan Diperlukan'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('ModeSelectionScreen prevents switching to Passive Mode when Strict Mode is active', (tester) async {
      SharedPreferences.setMockInitialValues({
        'is_strict_mode': true,
        'strict_mode_days': 30,
        'strict_mode_until_ms': DateTime.now().millisecondsSinceEpoch + (30 * 24 * 60 * 60 * 1000),
        'languageCode': 'id',
      });
      final prefs = await SharedPreferences.getInstance();
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: ModeSelectionScreen(isOnboarding: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final passiveCard = find.text('Mode Pasif');
      await tester.scrollUntilVisible(passiveCard, 200);
      await tester.pumpAndSettle();
      expect(passiveCard, findsOneWidget);

      await tester.tap(passiveCard);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Mode Ketat sedang aktif'), findsOneWidget);
    });

    testWidgets('ModeSelectionScreen renders Mode Pasif card with SANGAT TIDAK DIREKOMENDASIKAN badge', (tester) async {
      SharedPreferences.setMockInitialValues({
        'languageCode': 'id',
      });
      final prefs = await SharedPreferences.getInstance();
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: ModeSelectionScreen(isOnboarding: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final badge = find.text('SANGAT TIDAK DIREKOMENDASIKAN');
      await tester.scrollUntilVisible(badge, 200);
      await tester.pumpAndSettle();
      expect(badge, findsOneWidget);
      expect(find.text('Mode Pasif'), findsOneWidget);
    });
  });
}
