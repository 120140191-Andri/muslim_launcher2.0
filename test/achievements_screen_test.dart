import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/achievements_screen.dart';
import 'package:muslim_launcher_2/screens/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
      'points': 75,
      'khatmCount': 1,
      'totalDzikirCount': 33,
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

  group('Achievements Screen & Trophy Dock Tests', () {
    testWidgets('AchievementsScreen renders hero card, stats, tabs, and badges', (tester) async {
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Hero Card
      expect(find.text('Pencapaian & Lencana'), findsOneWidget);
      expect(find.textContaining('MAQAM'), findsOneWidget);
      expect(find.text('Khatam'), findsOneWidget);
      expect(find.text('Surah'), findsOneWidget);
      // Dzikir appears in the stat box and in the filter tab
      expect(find.text('Dzikir'), findsNWidgets(2));
      expect(find.text('Poin'), findsOneWidget);

      // Verify Category Filter Chips
      expect(find.textContaining('Semua'), findsOneWidget);
      expect(find.text("Al-Qur'an"), findsOneWidget);
      expect(find.text('Disiplin & Fokus'), findsOneWidget);

      // Switch to Dzikir tab (the second text widget with 'Dzikir')
      await tester.tap(find.text('Dzikir').last);
      await tester.pumpAndSettle();

      // Verify Dzikir badge is shown
      expect(find.text('Basahi Lisan'), findsOneWidget);

      // Ensure Basahi Lisan is visible within scrollview before tapping
      await tester.ensureVisible(find.text('Basahi Lisan'));
      await tester.pumpAndSettle();

      // Tap on a badge to open detail modal dialog
      await tester.tap(find.text('Basahi Lisan'));
      await tester.pumpAndSettle();

      // Verify detail dialog shows fadhilah and Close button
      expect(find.textContaining('Senantiasalah lisanmu basah'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });

    testWidgets('HomeScreen Quick Dock displays trophy icon and navigates to AchievementsScreen', (tester) async {
      final appState = AppState(prefs);
      appState.setIgnorePermissionGuard(true);
      appState.setReadyForTesting();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            navigatorKey: appState.navigatorKey,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify trophy icon is in the Quick Dock
      final trophyFinder = find.byIcon(Icons.emoji_events_rounded);
      expect(trophyFinder, findsOneWidget);

      // Retrieve InkWell of trophy button and trigger tap
      final trophyInkWell = tester.widget<InkWell>(
        find.ancestor(of: trophyFinder, matching: find.byType(InkWell)).first,
      );
      trophyInkWell.onTap?.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify navigation to AchievementsScreen
      expect(find.byType(AchievementsScreen), findsOneWidget);
      expect(find.text('Pencapaian & Lencana'), findsOneWidget);
    });

    testWidgets('AchievementsScreen displays all 5 Khatam tier badges (1x to 5x)', (tester) async {
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Al-Qur'an filter tab
      await tester.tap(find.text("Al-Qur'an"));
      await tester.pumpAndSettle();

      // Verify all 5 Khatam tier badges exist
      expect(find.text('Tingkat 1 • Pejuang Istiqomah'), findsOneWidget);
      expect(find.text('Tingkat 2 • Al-Mubtadi\' Al-Karim'), findsOneWidget);
      expect(find.text('Tingkat 3 • Shahibul Qur\'an'), findsOneWidget);
      expect(find.text('Tingkat 4 • Haafizhun Nuur'), findsOneWidget);
      expect(find.text('Tingkat 5 • Ahlul Qur\'an Al-Mubarok'), findsOneWidget);

      // Verify Tingkat 1 and Tingkat 2 are unlocked (display 'Tercapai' because khatmCount was 1 in setUp)
      expect(find.text('Tercapai'), findsWidgets);
      // Verify Tingkat 3 has progress 1 / 2 Khatam
      expect(find.text('1 / 2 Khatam'), findsOneWidget);
      // Verify Tingkat 4 has progress 1 / 3 Khatam
      expect(find.text('1 / 3 Khatam'), findsOneWidget);
      // Verify Tingkat 5 has progress 1 / 5 Khatam
      expect(find.text('1 / 5 Khatam'), findsOneWidget);
    });

    testWidgets('AchievementsScreen renders Daily Tilawah Streak card and streak badges (3, 7, 14, 30 days)', (tester) async {
      final appState = AppState(prefs);
      await appState.setQuranStreakForTesting(7, maxStreak: 7);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Daily Streak Banner
      expect(find.text('ISTIQOMAH TILAWAH HARIAN'), findsOneWidget);
      expect(find.text('7 Hari Berturut-turut 🔥'), findsOneWidget);
      expect(find.text('Rekor: 7 Hari'), findsOneWidget);

      // Switch to Al-Qur'an filter tab
      await tester.tap(find.text("Al-Qur'an"));
      await tester.pumpAndSettle();

      // Verify streak badges exist
      expect(find.text('Istiqomah 3 Hari'), findsOneWidget);
      expect(find.text('Istiqomah 7 Hari (1 Pekan)'), findsOneWidget);
      expect(find.text('Istiqomah 14 Hari (2 Pekan)'), findsOneWidget);
      expect(find.text('Istiqomah Sebulan Penuh (30 Hari)'), findsOneWidget);

      // With streak of 7, both streak banner target and 14-day badge show '7 / 14 Hari'
      expect(find.text('7 / 14 Hari'), findsWidgets);
      // 30-day badge should show '7 / 30 Hari'
      expect(find.text('7 / 30 Hari'), findsOneWidget);
    });

    test('AppState tracks consecutive day reading streak and max streak correctly', () async {
      final appState = AppState(prefs);

      // Initially zero
      await appState.setQuranStreakForTesting(0, maxStreak: 0, lastDate: '');
      expect(appState.quranDailyStreak, 0);

      // Simulate reading yesterday and today
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

      await appState.setQuranStreakForTesting(3, maxStreak: 3, lastDate: yesterday);
      expect(appState.quranDailyStreak, 3);

      // Simulate saving progress today
      await appState.saveProgress(0, 0, 'Al-Fatihah', 1, 10);
      expect(appState.quranDailyStreak, 4);
      expect(appState.maxQuranDailyStreak, 4);
      expect(appState.lastQuranReadDate, today);

      // Second read on same day should not increment streak further
      await appState.saveProgress(0, 1, 'Al-Fatihah', 2, 10);
      expect(appState.quranDailyStreak, 4);
      expect(appState.maxQuranDailyStreak, 4);
    });
  });
}

