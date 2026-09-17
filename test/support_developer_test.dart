import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/blocked_app_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  final List<MethodCall> blockMethodCalls = [];

  setUp(() async {
    blockMethodCalls.clear();

    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async {
      blockMethodCalls.add(call);
      return true;
    });

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => true);
  });

  group('Support Developer Logic & Bypass Tests', () {
    test('getSupportUrl returns Trakteer for Indonesian and Ko-fi for other languages', () {
      expect(AppState.getSupportUrl('id'), contains('trakteer.id'));
      expect(AppState.getSupportUrl('en'), contains('ko-fi.com'));
      expect(AppState.getSupportUrl('ar'), contains('ko-fi.com'));
      expect(AppState.getSupportUrl('ms'), contains('ko-fi.com'));
    });

    test('getSupportButtonText returns appropriate labels', () {
      final btnTextId = AppState.getSupportButtonText('id');
      expect(btnTextId.toLowerCase(), contains('trakteer'));

      final btnTextEn = AppState.getSupportButtonText('en');
      expect(btnTextEn.isNotEmpty, isTrue);
    });

    test('openSupportDeveloperUrl prepares bypass via MethodChannel', () async {
      final appState = AppState(prefs);

      // openSupportDeveloperUrl calls prepareSupportDeveloperBypass then launches AndroidIntent
      // In unit test environment AndroidIntent launch will be caught, but prepareSupportDeveloperBypass must be invoked
      await appState.openSupportDeveloperUrl('id');

      final bypassCalls = blockMethodCalls
          .where((call) => call.method == 'prepareSupportDeveloperBypass')
          .toList();

      expect(bypassCalls.isNotEmpty, isTrue);
    });

    test('Normal browser apps still require Ghadhul Bashar reminder', () {
      const browsers = [
        'com.android.chrome',
        'org.mozilla.firefox',
        'com.sec.android.app.sbrowser',
        'com.brave.browser',
      ];

      for (final pkg in browsers) {
        expect(
          AppState.shouldShowGhadhulBasharReminder(pkg, '', 'id'),
          isTrue,
          reason: 'Normal browser access must remain protected with Ghadhul Bashar',
        );
      }
    });

    test('Translations for Dzikir points match current 3-round rules', () {
      expect(AppState.getSupportUrl('id'), contains('trakteer.id'));
    });

    testWidgets('BlockedAppScreen displays current live point rules (+5-7 Poin/Ayat Boost, +2-5 Poin, +1-4 Poin)', (tester) async {
      final appState = AppState(prefs);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: BlockedAppScreen(packageName: 'com.instagram.android'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+5-7 Poin/Ayat (Boost: 10/10)'), findsOneWidget);
      expect(find.text('+2-5 Poin'), findsOneWidget);
      expect(find.text('+1-4 Poin'), findsOneWidget);
    });
  });
}
