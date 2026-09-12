import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/services/streak_notification_service.dart';
import 'package:muslim_launcher_2/screens/home/achievements_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'points': 50,
      'hasSelectedLanguage': true,
      'languageCode': 'id',
      'hasCompletedOnboarding': true,
      'quranDailyStreak': 3,
      'dzikirDailyStreak': 2,
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
          {'packageName': 'com.android.dialer', 'appName': 'Phone', 'category': 0},
          {'packageName': 'com.whatsapp', 'appName': 'WhatsApp', 'category': 3},
        ];
      }
      return [];
    });
  });

  group('StreakNotificationService Tests', () {
    test('getReminderContent generates correct messages for all completion states and languages', () {
      // 1. Both pending (Indonesian)
      final bothId = StreakNotificationService.getReminderContent(
        hasQuranToday: false,
        hasDzikirToday: false,
        lang: 'id',
      );
      expect(bothId['title'], contains('Jaga Istiqomah Harianmu!'));
      expect(bothId['body'], contains('1 ayat dan zikir 33x'));
      expect(bothId['payload'], 'streak');

      // 2. Both pending (English)
      final bothEn = StreakNotificationService.getReminderContent(
        hasQuranToday: false,
        hasDzikirToday: false,
        lang: 'en',
      );
      expect(bothEn['title'], contains('Keep Your Daily Streak Alive!'));
      expect(bothEn['payload'], 'streak');

      // 3. Both pending (Arabic)
      final bothAr = StreakNotificationService.getReminderContent(
        hasQuranToday: false,
        hasDzikirToday: false,
        lang: 'ar',
      );
      expect(bothAr['title'], contains('حافظ على استقامتك اليومية!'));
      expect(bothAr['payload'], 'streak');

      // 4. Only Quran pending
      final onlyQuran = StreakNotificationService.getReminderContent(
        hasQuranToday: false,
        hasDzikirToday: true,
        lang: 'id',
      );
      expect(onlyQuran['title'], contains('Waktunya Tilawah Hari Ini!'));
      expect(onlyQuran['payload'], 'quran');

      // 5. Only Dzikir pending
      final onlyDzikir = StreakNotificationService.getReminderContent(
        hasQuranToday: true,
        hasDzikirToday: false,
        lang: 'id',
      );
      expect(onlyDzikir['title'], contains('Sempatkan Zikir Hari Ini!'));
      expect(onlyDzikir['payload'], 'dzikir');

      // 6. Both completed (empty content because reminder should be cancelled)
      final bothDone = StreakNotificationService.getReminderContent(
        hasQuranToday: true,
        hasDzikirToday: true,
        lang: 'id',
      );
      expect(bothDone['title'], '');
      expect(bothDone['body'], '');
      expect(bothDone['payload'], '');
    });

    test('AppState tracks streak reminder settings and today completion getters accurately', () async {
      final appState = AppState(prefs);
      final today = DateTime.now().toIso8601String().split('T')[0];
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

      // Default reminder settings
      expect(appState.isStreakReminderEnabled, true);
      expect(appState.streakReminderHour, 20);
      expect(appState.streakReminderMinute, 0);

      // Initially neither read nor dzikir today
      expect(appState.hasReadQuranToday, false);
      expect(appState.hasDzikirToday, false);

      // Simulate Quran read today
      await appState.setQuranStreakForTesting(4, lastDate: today);
      expect(appState.hasReadQuranToday, true);
      expect(appState.hasDzikirToday, false);

      // Simulate Dzikir completed today
      await appState.setDzikirStreakForTesting(3, lastDate: today);
      expect(appState.hasReadQuranToday, true);
      expect(appState.hasDzikirToday, true);

      // Yesterday date means not yet done today
      await appState.setQuranStreakForTesting(4, lastDate: yesterday);
      expect(appState.hasReadQuranToday, false);

      // Test toggling settings
      await appState.setStreakReminderEnabled(false);
      expect(appState.isStreakReminderEnabled, false);
      expect(prefs.getBool('isStreakReminderEnabled'), false);

      await appState.setStreakReminderTime(21, 30);
      expect(appState.streakReminderHour, 21);
      expect(appState.streakReminderMinute, 30);
      expect(prefs.getInt('streakReminderHour'), 21);
      expect(prefs.getInt('streakReminderMinute'), 30);
    });

    testWidgets('AchievementsScreen renders streak daily reminder toggle and updates setting when switched', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify reminder row exists
      expect(find.text('Pengingat Harian (20:00)'), findsOneWidget);
      expect(find.text('Ingatkan jika belum istiqomah'), findsOneWidget);

      // Verify initial switch value is true
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, true);

      // Tap switch to turn off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(appState.isStreakReminderEnabled, false);
      expect(prefs.getBool('isStreakReminderEnabled'), false);
    });
  });
}
