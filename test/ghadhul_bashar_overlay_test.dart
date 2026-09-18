import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
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
          {'packageName': 'com.android.chrome', 'appName': 'Chrome', 'category': 7},
        ];
      }
      return true;
    });
  });

  testWidgets('GhadhulBasharOverlay renders verse, app title, and action buttons', (tester) async {
    final appState = AppState(prefs);

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

    expect(find.text(Translations.get('id', 'ghadhul_bashar_title')), findsOneWidget);
    expect(find.text(Translations.get('id', 'ghadhul_bashar_subtitle')), findsOneWidget);
    expect(find.text(Translations.get('id', 'cancel')), findsOneWidget);
    expect(find.text(Translations.get('id', 'ok')), findsOneWidget);
  });

  testWidgets('GhadhulBasharOverlay Cancel button clears ghadhul bashar state', (tester) async {
    final appState = AppState(prefs);
    appState.setGhadhulBasharPackage('com.android.chrome');
    expect(appState.lastAttemptedGhadhulBasharPackage, equals('com.android.chrome'));

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

    await tester.ensureVisible(find.text(Translations.get('id', 'cancel')));
    await tester.tap(find.text(Translations.get('id', 'cancel')));
    await tester.pumpAndSettle();

    expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
  });

  testWidgets('GhadhulBasharOverlay Proceed button triggers confirm and clears state', (tester) async {
    final appState = AppState(prefs);
    appState.setGhadhulBasharPackage('com.android.chrome');
    expect(appState.lastAttemptedGhadhulBasharPackage, equals('com.android.chrome'));

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

    await tester.ensureVisible(find.text(Translations.get('id', 'ok')));
    await tester.tap(find.text(Translations.get('id', 'ok')));
    await tester.pumpAndSettle();

    expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
  });

  testWidgets('GhadhulBasharOverlay social group link activates 5s countdown, warning badge, and locks proceed button until 0s', (tester) async {
    final appState = AppState(prefs);
    appState.setGhadhulBasharPackage('com.whatsapp', 'social_group_link');
    expect(appState.lastAttemptedGhadhulBasharPackage, equals('com.whatsapp'));
    expect(appState.lastAttemptedGhadhulBasharExtra, equals('social_group_link'));

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(
            body: GhadhulBasharOverlay(packageName: 'com.whatsapp'),
          ),
        ),
      ),
    );
    // Initial pump (at start of countdown)
    await tester.pump();

    // Verify warning badge appears
    expect(find.text(Translations.get('id', 'social_group_warning_title')), findsOneWidget);
    expect(find.text(Translations.get('id', 'social_group_warning_subtitle')), findsOneWidget);

    // Initial countdown label is 5s
    expect(find.text('${Translations.get('id', 'ok')} (5s)'), findsOneWidget);

    // Tap at 5s should NOT proceed because button is disabled
    await tester.ensureVisible(find.text('${Translations.get('id', 'ok')} (5s)'));
    await tester.tap(find.text('${Translations.get('id', 'ok')} (5s)'));
    await tester.pump();
    expect(appState.lastAttemptedGhadhulBasharPackage, equals('com.whatsapp'));

    // Advance 2 seconds
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('${Translations.get('id', 'ok')} (3s)'), findsOneWidget);

    // Advance remaining 3 seconds to complete countdown
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Now button displays normal text and is enabled
    expect(find.text(Translations.get('id', 'ok')), findsOneWidget);
    await tester.ensureVisible(find.text(Translations.get('id', 'ok')));
    await tester.tap(find.text(Translations.get('id', 'ok')));
    await tester.pumpAndSettle();

    expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
  });

  testWidgets('GhadhulBasharOverlay social group link allows immediate Cancel during countdown', (tester) async {
    final appState = AppState(prefs);
    appState.setGhadhulBasharPackage('org.telegram.messenger', 'social_group_link');

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: Scaffold(
            body: GhadhulBasharOverlay(packageName: 'org.telegram.messenger'),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify countdown is running
    expect(find.text('${Translations.get('id', 'ok')} (5s)'), findsOneWidget);

    // Immediate Cancel button is active and dismisses safely
    await tester.ensureVisible(find.text(Translations.get('id', 'cancel')));
    await tester.tap(find.text(Translations.get('id', 'cancel')));
    await tester.pumpAndSettle();

    expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
  });
}
