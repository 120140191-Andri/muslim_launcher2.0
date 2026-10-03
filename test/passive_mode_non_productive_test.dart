import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/app_list_screen.dart';
import 'package:muslim_launcher_2/screens/home/blocked_app_screen.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  final List<String> openedApps = [];

  setUp(() async {
    openedApps.clear();
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
      'launcher_mode': 'passive',
      'blockedApps': ['com.instagram.android'],
      'cached_installed_apps': json.encode([
        {
          'packageName': 'com.instagram.android',
          'appName': 'Instagram',
          'category': 4, // Category Social -> Non-productive
        },
        {
          'packageName': 'com.android.calculator2',
          'appName': 'Calculator',
          'category': 7, // Category Productivity -> Productive app
        },
      ]),
    });
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getApps') {
        return [
          {
            'packageName': 'com.instagram.android',
            'appName': 'Instagram',
            'category': 4,
          },
          {
            'packageName': 'com.android.calculator2',
            'appName': 'Calculator',
            'category': 7,
          },
        ];
      }
      if (call.method == 'getAppIcon') {
        return null;
      }
      if (call.method == 'openApp') {
        final pkg = call.arguments['packageName'] as String;
        openedApps.add(pkg);
        return true;
      }
      return true;
    });

    await AppListScreen.initFromDisk(prefs);
  });

  tearDown(() {
    AppListScreen.invalidateFull();
  });

  group('Passive Mode (Mode Paling Rendah) Non-Productive App Handling', () {
    testWidgets(
        'Tapping non-productive app in passive mode pushes BlockedAppScreen as in-app route and does not trigger overlay',
        (tester) async {
      final appState = AppState(prefs);
      await appState.enablePassiveMode();
      expect(appState.isPassiveMode, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AppListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Instagram (non-productive app)
      expect(find.text('Instagram'), findsOneWidget);

      // Tap Instagram
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      // BlockedAppScreen should be presented as a route in the app
      expect(find.byType(BlockedAppScreen), findsOneWidget);
      // Overlay state should NOT be set because passive mode avoids overlay
      expect(appState.lastAttemptedBlockedPackage, isNull);
      // App should not have been opened directly
      expect(openedApps, isEmpty);

      // Tap Kembali / go back
      final goBackButton = find.text(Translations.get('id', 'go_back'));
      expect(goBackButton, findsOneWidget);
      await tester.ensureVisible(goBackButton);
      await tester.tap(goBackButton);
      await tester.pumpAndSettle();

      // BlockedAppScreen should be popped, returning to AppListScreen
      expect(find.byType(BlockedAppScreen), findsNothing);
      expect(find.text('Instagram'), findsOneWidget);
    });

    testWidgets(
        'Tapping productive app in passive mode opens the app normally',
        (tester) async {
      final appState = AppState(prefs);
      await appState.enablePassiveMode();
      expect(appState.isPassiveMode, isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AppListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Calculator (productive app)
      expect(find.text('Calculator'), findsOneWidget);

      // Tap Calculator
      await tester.tap(find.text('Calculator'));
      await tester.pumpAndSettle();

      // Should not push BlockedAppScreen
      expect(find.byType(BlockedAppScreen), findsNothing);
      // MethodChannel openApp should have been called
      expect(openedApps, contains('com.android.calculator2'));
    });

    testWidgets(
        'In Standard Mode, tapping non-productive app sets blocked package for overlay',
        (tester) async {
      final appState = AppState(prefs);
      await appState.enableStandardMode();
      expect(appState.isPassiveMode, isFalse);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AppListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Instagram
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      // Standard mode sets lastAttemptedBlockedPackage for root overlay
      expect(appState.lastAttemptedBlockedPackage, equals('com.instagram.android'));
      // Does not push BlockedAppScreen as separate Navigator route on AppListScreen
      expect(find.byType(BlockedAppScreen), findsNothing);
    });
  });
}
