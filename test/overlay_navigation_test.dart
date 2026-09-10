import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/prohibited_app_overlay.dart';
import 'package:muslim_launcher_2/screens/home/blocked_app_screen.dart';
import 'package:muslim_launcher_2/screens/home/ghadhul_bashar_overlay.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
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
          {'packageName': 'com.opera.browser', 'appName': 'Opera', 'category': 7},
          {'packageName': 'com.instagram.android', 'appName': 'Instagram', 'category': 3},
          {'packageName': 'com.android.chrome', 'appName': 'Chrome', 'category': 7},
        ];
      }
      return true;
    });
  });

  group('AppState Overlay Navigation Methods', () {
    test('clearAllOverlays resets all 3 overlay states', () {
      final appState = AppState(prefs);
      appState.setProhibitedPackage('com.opera.browser');
      appState.setBlockedPackage('com.instagram.android');
      appState.setGhadhulBasharPackage('com.android.chrome');

      expect(appState.lastAttemptedProhibitedPackage, equals('com.opera.browser'));
      expect(appState.lastAttemptedBlockedPackage, equals('com.instagram.android'));
      expect(appState.lastAttemptedGhadhulBasharPackage, equals('com.android.chrome'));

      appState.clearAllOverlays();

      expect(appState.lastAttemptedProhibitedPackage, isNull);
      expect(appState.lastAttemptedBlockedPackage, isNull);
      expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
      expect(appState.hasActiveOverlay, isFalse);
    });

    test('hasActiveOverlay correctly reflects any overlay status', () {
      final appState = AppState(prefs);
      expect(appState.hasActiveOverlay, isFalse);

      appState.setProhibitedPackage('com.opera.browser');
      expect(appState.hasActiveOverlay, isTrue);
      appState.clearProhibitedPackage();
      expect(appState.hasActiveOverlay, isFalse);

      appState.setBlockedPackage('com.instagram.android');
      expect(appState.hasActiveOverlay, isTrue);
      appState.clearBlockedApp();
      expect(appState.hasActiveOverlay, isFalse);

      appState.setGhadhulBasharPackage('com.android.chrome');
      expect(appState.hasActiveOverlay, isTrue);
      appState.clearGhadhulBashar();
      expect(appState.hasActiveOverlay, isFalse);
    });
  });

  group('ProhibitedAppOverlay Navigation', () {
    testWidgets('Kembali button and top back button clear prohibited state', (tester) async {
      final appState = AppState(prefs);
      appState.setProhibitedPackage('com.opera.browser');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: ProhibitedAppOverlay(packageName: 'com.opera.browser'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar icons exist
      expect(find.byIcon(Icons.arrow_back_rounded), findsWidgets);
      expect(find.byIcon(Icons.home_rounded), findsWidgets);

      // Tap bottom Kembali button
      await tester.ensureVisible(find.text(Translations.get('id', 'go_back')));
      await tester.tap(find.text(Translations.get('id', 'go_back')));
      await tester.pumpAndSettle();

      expect(appState.lastAttemptedProhibitedPackage, isNull);
    });

    testWidgets('Top back and home icon buttons work on ProhibitedAppOverlay', (tester) async {
      final appState = AppState(prefs);
      appState.setProhibitedPackage('com.opera.browser');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: ProhibitedAppOverlay(packageName: 'com.opera.browser'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap top back icon
      final backIcon = find.byIcon(Icons.arrow_back_rounded).first;
      await tester.tap(backIcon);
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedProhibitedPackage, isNull);

      // Re-set and tap top home icon
      appState.setProhibitedPackage('com.opera.browser');
      await tester.pumpAndSettle();
      final homeIcon = find.byIcon(Icons.home_rounded).first;
      await tester.tap(homeIcon);
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedProhibitedPackage, isNull);
    });
  });

  group('BlockedAppScreen Navigation', () {
    testWidgets('Kembali button clears blocked state', (tester) async {
      final appState = AppState(prefs);
      appState.setBlockedPackage('com.instagram.android');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: BlockedAppScreen(packageName: 'com.instagram.android'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kembali button is present at bottom
      expect(find.text(Translations.get('id', 'go_back')), findsOneWidget);

      // Tap Kembali
      await tester.ensureVisible(find.text(Translations.get('id', 'go_back')));
      await tester.tap(find.text(Translations.get('id', 'go_back')));
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedBlockedPackage, isNull);
    });

    testWidgets('Top back and home icon buttons work on BlockedAppScreen', (tester) async {
      final appState = AppState(prefs);
      appState.setBlockedPackage('com.instagram.android');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: BlockedAppScreen(packageName: 'com.instagram.android'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap top back icon
      final backIcon = find.byIcon(Icons.arrow_back_rounded).first;
      await tester.tap(backIcon);
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedBlockedPackage, isNull);

      // Re-set and tap top home icon
      appState.setBlockedPackage('com.instagram.android');
      await tester.pumpAndSettle();
      final homeIcon = find.byIcon(Icons.home_rounded).first;
      await tester.tap(homeIcon);
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedBlockedPackage, isNull);
    });
  });

  group('GhadhulBasharOverlay Navigation', () {
    testWidgets('Batal and Kembali buttons work on GhadhulBasharOverlay', (tester) async {
      final appState = AppState(prefs);
      appState.setGhadhulBasharPackage('com.android.chrome');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: GhadhulBasharOverlay(packageName: 'com.android.chrome'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Translations.get('id', 'cancel')), findsOneWidget);
      expect(find.text(Translations.get('id', 'go_back')), findsOneWidget);

      // Tap Kembali
      await tester.ensureVisible(find.text(Translations.get('id', 'go_back')));
      await tester.tap(find.text(Translations.get('id', 'go_back')));
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
    });

    testWidgets('Top back and home icon buttons work on GhadhulBasharOverlay', (tester) async {
      final appState = AppState(prefs);
      appState.setGhadhulBasharPackage('com.android.chrome');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: GhadhulBasharOverlay(packageName: 'com.android.chrome'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap top back icon
      final backIcon = find.byIcon(Icons.arrow_back_rounded).first;
      await tester.tap(backIcon);
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedGhadhulBasharPackage, isNull);

      // Re-set and tap top home icon
      appState.setGhadhulBasharPackage('com.android.chrome');
      await tester.pumpAndSettle();
      final homeIcon = find.byIcon(Icons.home_rounded).first;
      await tester.tap(homeIcon);
      await tester.pumpAndSettle();
      expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
    });
  });
}
