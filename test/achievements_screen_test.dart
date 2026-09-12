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
      await tester.pumpAndSettle();

      // Verify Header & Hero Card
      expect(find.text('Pencapaian & Lencana'), findsOneWidget);
      expect(find.textContaining('MAQAM'), findsOneWidget);
      expect(find.text('Khatam'), findsOneWidget);
      expect(find.text('Surah'), findsOneWidget);
      // Dzikir appears in the stat box and in the filter tab
      expect(find.text('Dzikir'), findsNWidgets(2));
      expect(find.text('Poin'), findsOneWidget);

      // Verify Category Filter Chips & Claim Banner
      expect(find.textContaining('Semua ('), findsOneWidget);
      expect(find.text('Klaim Semua'), findsOneWidget);
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

    testWidgets('HomeScreen renders _HomeStreakCard below Quick Dock with Tilawah and Zikir streaks', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await prefs.setInt('quranDailyStreak', 5);
      await prefs.setInt('dzikirDailyStreak', 3);
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('lastQuranReadDate', today);
      await prefs.setString('lastDzikirDate', today);

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

      expect(find.text('ISTIQOMAH HARIAN'), findsOneWidget);
      expect(find.text('Lencana & Hadiah'), findsOneWidget);
      expect(find.text('Tilawah'), findsWidgets);
      expect(find.text('Zikir'), findsWidgets);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Sudah'), findsWidgets);
    });


    testWidgets('AchievementsScreen displays all 5 Khatam tier badges (1x to 5x)', (tester) async {
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

    testWidgets('AchievementsScreen renders Daily Tilawah & Dzikir Streak card and streak badges', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState(prefs);
      await appState.setQuranStreakForTesting(7, maxStreak: 7);
      await appState.setDzikirStreakForTesting(3, maxStreak: 5);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Daily Tilawah Streak Banner by default
      expect(find.text('ISTIQOMAH TILAWAH HARIAN'), findsOneWidget);
      expect(find.text('7 Hari Berturut-turut 🔥'), findsOneWidget);
      expect(find.text('Rekor: 7 Hari'), findsOneWidget);

      // Switch to Al-Qur'an filter tab
      await tester.tap(find.text("Al-Qur'an"));
      await tester.pumpAndSettle();

      // Verify Qur'an streak badges exist (1, 3, 7, 14, 30, 365)
      expect(find.text('Istiqomah 1 Hari'), findsOneWidget);
      expect(find.text('Istiqomah 3 Hari'), findsOneWidget);
      expect(find.text('Istiqomah 7 Hari (1 Pekan)'), findsOneWidget);
      expect(find.text('Istiqomah 14 Hari (2 Pekan)'), findsOneWidget);
      expect(find.text('Istiqomah Sebulan Penuh (30 Hari)'), findsOneWidget);
      expect(find.text('Istiqomah 1 Tahun Penuh (365 Hari)'), findsOneWidget);

      // Now toggle streak card to Dzikir
      await tester.tap(find.textContaining('Zikir (3h)'));
      await tester.pumpAndSettle();

      // Verify Dzikir Streak Banner is shown
      expect(find.text('ISTIQOMAH ZIKIR HARIAN'), findsOneWidget);
      expect(find.text('3 Hari Berturut-turut ✨'), findsOneWidget);
      expect(find.text('Rekor: 5 Hari'), findsOneWidget);

      // Switch filter category to Dzikir tab
      await tester.tap(find.text('Dzikir').last);
      await tester.pumpAndSettle();

      // Verify all 6 Dzikir streak badges exist
      expect(find.text('Istiqomah Zikir 1 Hari'), findsOneWidget);
      expect(find.text('Istiqomah Zikir 3 Hari'), findsOneWidget);
      expect(find.text('Istiqomah Zikir 7 Hari (1 Pekan)'), findsOneWidget);
      expect(find.text('Istiqomah Zikir 14 Hari (2 Pekan)'), findsOneWidget);
      expect(find.text('Istiqomah Zikir Sebulan (30 Hari)'), findsOneWidget);
      expect(find.text('Istiqomah Zikir 1 Tahun (365 Hari)'), findsOneWidget);
    });

    test('AppState tracks consecutive day reading streak and resets correctly when day missed', () async {
      final appState = AppState(prefs);

      // Initially zero
      await appState.setQuranStreakForTesting(0, maxStreak: 0, lastDate: '');
      expect(appState.quranDailyStreak, 0);

      // Simulate reading yesterday and today
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      final twoDaysAgo = now.subtract(const Duration(days: 2)).toIso8601String().split('T')[0];

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

      // Missing a day: simulate last read was 2 days ago
      await appState.setQuranStreakForTesting(4, maxStreak: 4, lastDate: twoDaysAgo);
      // Because 2 days ago is not today or yesterday, getter returns 0 active streak
      expect(appState.quranDailyStreak, 0);
      expect(appState.maxQuranDailyStreak, 4);

      // Reading today resets current streak to 1, while preserving max streak of 4!
      await appState.saveProgress(0, 2, 'Al-Fatihah', 3, 10);
      expect(appState.quranDailyStreak, 1);
      expect(appState.maxQuranDailyStreak, 4);
    });

    test('AppState tracks consecutive day dzikir streak and resets correctly when day missed', () async {
      final appState = AppState(prefs);

      // Initially zero
      await appState.setDzikirStreakForTesting(0, maxStreak: 0, lastDate: '');
      expect(appState.dzikirDailyStreak, 0);

      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
      final twoDaysAgo = now.subtract(const Duration(days: 2)).toIso8601String().split('T')[0];

      // Simulate dzikir yesterday
      await appState.setDzikirStreakForTesting(5, maxStreak: 5, lastDate: yesterday);
      expect(appState.dzikirDailyStreak, 5);

      // Partial dzikir (< 33) does NOT activate streak yet
      await appState.addDzikirCount(15);
      expect(appState.dailyDzikirCount, 15);
      expect(appState.lastDzikirDate, yesterday); // Still yesterday
      expect(appState.dzikirDailyStreak, 5); // Still 5, not yet completed today

      // Completing the remainder (18 taps, total 33) reaches minimum 1 round (33x) and increments streak to 6
      await appState.addDzikirCount(18);
      expect(appState.dailyDzikirCount, 33);
      expect(appState.dzikirDailyStreak, 6);
      expect(appState.maxDzikirDailyStreak, 6);
      expect(appState.lastDzikirDate, today);

      // Additional dzikir on same day via saveDzikirProgress does not double increment
      await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(appState.dailyDzikirCount, 66);
      expect(appState.dzikirDailyStreak, 6);
      expect(appState.maxDzikirDailyStreak, 6);

      // Missing a day: last dzikir was 2 days ago
      await appState.setDzikirStreakForTesting(6, maxStreak: 6, lastDate: twoDaysAgo);
      expect(appState.dzikirDailyStreak, 0);
      expect(appState.maxDzikirDailyStreak, 6);

      // Doing partial dzikir (10x) does not reset streak to 1 yet
      await appState.addDzikirCount(10);
      expect(appState.dzikirDailyStreak, 0);

      // Finishing 33x round resets streak to 1, while best record remains 6!
      await appState.addDzikirCount(23);
      expect(appState.dzikirDailyStreak, 1);
      expect(appState.maxDzikirDailyStreak, 6);
    });

    test('AppState allows claiming badge rewards, prevents duplicate claims, and supports batch claim', () async {
      final appState = AppState(prefs);
      final initialPoints = appState.points; // 75 from setUp

      expect(appState.isBadgeClaimed('quran_streak_7'), false);

      // Claim single badge reward (+50 points)
      final success = await appState.claimBadgeReward('quran_streak_7', 50, 'Istiqomah 7 Hari');
      expect(success, true);
      expect(appState.points, initialPoints + 50);
      expect(appState.isBadgeClaimed('quran_streak_7'), true);

      // Duplicate claim must be rejected
      final duplicateSuccess = await appState.claimBadgeReward('quran_streak_7', 50, 'Istiqomah 7 Hari');
      expect(duplicateSuccess, false);
      expect(appState.points, initialPoints + 50);

      // Batch claim all rewards
      final batchList = [
        {'id': 'quran_streak_7', 'points': 50, 'title': 'Istiqomah 7 Hari'}, // already claimed, should skip
        {'id': 'dzikir_streak_7', 'points': 50, 'title': 'Istiqomah Zikir 7 Hari'}, // new
        {'id': 'quran_maqam_1', 'points': 15, 'title': 'Tingkat 1'}, // new
      ];
      final totalClaimed = await appState.claimAllBadgeRewards(batchList);
      expect(totalClaimed, 65); // 50 + 15
      expect(appState.points, initialPoints + 50 + 65);
      expect(appState.isBadgeClaimed('dzikir_streak_7'), true);
      expect(appState.isBadgeClaimed('quran_maqam_1'), true);

      // History should record these claimed badges
      final history = appState.readingHistory;
      expect(history.any((e) => ((e['surah'] as String?) ?? '').contains('Istiqomah 7 Hari')), true);
      expect(history.any((e) => ((e['surah'] as String?) ?? '').contains('Tingkat 1')), true);
    });

    testWidgets('AchievementsScreen allows claiming badge reward directly from card and modal', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState(prefs);
      // Khatm count = 1, so Tingkat 1 (15 pts) and Tingkat 2 (500 pts) are unlocked
      await appState.setClaimedBadgesForTesting({});
      final startPoints = appState.points;

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: AchievementsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Claim All button is present
      expect(find.text('Klaim Semua'), findsOneWidget);

      // Switch to Al-Qur'an tab
      await tester.tap(find.text("Al-Qur'an"));
      await tester.pumpAndSettle();

      // Find Tingkat 1 claim button
      expect(find.text('Klaim +15'), findsOneWidget);

      // Tap claim on Tingkat 1
      await tester.tap(find.text('Klaim +15'));
      await tester.pumpAndSettle();

      // Verify points increased by 15
      expect(appState.points, startPoints + 15);
      expect(appState.isBadgeClaimed('quran_maqam_1'), true);

      // Now tap on Tingkat 2 card to open modal dialog
      await tester.tap(find.text('Tingkat 2 • Al-Mubtadi\' Al-Karim'));
      await tester.pumpAndSettle();

      // Verify modal has "Klaim Hadiah (+500 Poin)" button
      expect(find.text('Klaim Hadiah (+500 Poin)'), findsOneWidget);

      // Tap the modal claim button
      await tester.tap(find.text('Klaim Hadiah (+500 Poin)'));
      await tester.pumpAndSettle();

      // Verify points increased by 500
      expect(appState.points, startPoints + 15 + 500);
      expect(appState.isBadgeClaimed('quran_maqam_2'), true);
    });
  });
}

