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
}
