import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/widgets/milestone_celebration_dialog.dart';
import 'package:muslim_launcher_2/widgets/milestone_share_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Gamification & Milestone Economy Tests', () {
    late SharedPreferences prefs;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      const channelBlock = MethodChannel('com.muslimlauncher/block');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelBlock, (call) async => true);

      const channelApps = MethodChannel('com.muslimlauncher/apps');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelApps, (call) async => true);

      appState = AppState(prefs);
    });

    test('User Name can be set, updated, and prompted properly', () async {
      expect(appState.userName, '');
      expect(appState.hasPromptedUserName, false);

      await appState.setUserName('Farhan');
      expect(appState.userName, 'Farhan');
      expect(prefs.getString('userName'), 'Farhan');

      await appState.setHasPromptedUserName(true);
      expect(appState.hasPromptedUserName, true);
      expect(prefs.getBool('hasPromptedUserName'), true);
    });

    test('Surah Milestone calculates correct tiered bonus points', () async {
      final initialPoints = appState.points;

      // Tier 1 (1-25 ayat): +10 Poin (e.g. Al-Fatihah, 7 ayat)
      final t1 = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(t1['isNewMilestone'], true);
      expect(t1['tier'], 1);
      expect(t1['bonusPoints'], 10);
      expect(appState.points, initialPoints + 10);

      // Duplicate completion of same surah in same cycle -> 0 bonus
      final t1Dup = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(t1Dup['isNewMilestone'], false);
      expect(t1Dup['bonusPoints'], 0);
      expect(appState.points, initialPoints + 10);

      // Tier 2 (26-75 ayat): +25 Poin (e.g. Al-Mulk, 30 ayat)
      final t2 = await appState.completeSurahMilestone(
        surahNumber: 67,
        surahName: 'Al-Mulk',
        totalAyahs: 30,
      );
      expect(t2['tier'], 2);
      expect(t2['bonusPoints'], 25);
      expect(appState.points, initialPoints + 10 + 25);

      // Tier 4 (>150 ayat): +100 Poin (e.g. Al-Baqarah, 286 ayat)
      final t4 = await appState.completeSurahMilestone(
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        totalAyahs: 286,
      );
      expect(t4['tier'], 4);
      expect(t4['bonusPoints'], 100);
      expect(appState.points, initialPoints + 10 + 25 + 100);
    });

    test('Khatam 30 Juz triggers +500 grand bonus and cycle reset', () async {
      final initialPoints = appState.points;
      final initialKhatm = appState.khatmCount;

      // Completing Surah 114 triggers Khatam!
      final result = await appState.completeSurahMilestone(
        surahNumber: 114,
        surahName: 'An-Nas',
        totalAyahs: 6,
      );

      expect(result['isKhatam'], true);
      expect(appState.khatmCount, initialKhatm + 1);
      // 10 base tier bonus + 500 grand bonus = 510 points
      expect(appState.points, initialPoints + 10 + 500);
      // Completed surahs are reset for next cycle
      expect(appState.completedSurahsThisCycle.isEmpty, true);
    });

    test('Daily Dzikir is strictly capped at 3 rounds (99 butir = 19 points max)', () async {
      final initialPoints = appState.points;

      // Round 1 (33x): +3 pts
      final r1 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r1['round'], 1);
      expect(r1['pointsEarned'], 3);
      expect(appState.dailyDzikirPoints, 3);
      expect(appState.points, initialPoints + 3);

      // Round 2 (66x): +3 pts
      final r2 = await appState.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(r2['round'], 2);
      expect(r2['pointsEarned'], 3);
      expect(appState.dailyDzikirPoints, 6);
      expect(appState.points, initialPoints + 6);

      // Round 3 (99x): +13 pts (3 + 10 bonus)
      final r3 = await appState.saveDzikirProgress('Allahu Akbar', 33, 10);
      expect(r3['round'], 3);
      expect(r3['pointsEarned'], 13);
      expect(r3['isDailyCapReached'], true);
      expect(appState.dailyDzikirPoints, 19);
      expect(appState.points, initialPoints + 19);

      // Round 4+: 0 pts (Anti-addiction cap enforced)
      final r4 = await appState.saveDzikirProgress('Astaghfirullah', 33, 10);
      expect(r4['round'], 4);
      expect(r4['pointsEarned'], 0);
      expect(appState.dailyDzikirPoints, 19);
      expect(appState.points, initialPoints + 19);
    });

    test('Emergency Grace Pass can only be used once per day', () async {
      expect(appState.canUseEmergencyGracePass, true);

      final success = await appState.useEmergencyGracePass('com.instagram.android');
      expect(success, true);
      expect(appState.canUseEmergencyGracePass, false);

      // Second attempt rejected on the same day
      final failAttempt = await appState.useEmergencyGracePass('com.instagram.android');
      expect(failAttempt, false);
    });
  });

  group('MilestoneShareCard Widget Rendering', () {
    testWidgets('MilestoneShareCard renders successfully in all 4 themes', (tester) async {
      const sampleData = MilestoneCardData(
        type: MilestoneCardType.surah,
        title: 'Al-Kahfi',
        arabicTitle: 'الكهف',
        subtitle: 'Cahaya di Antara Dua Jumat',
        surahNumber: 18,
        ayahCount: 110,
        durationMinutes: 28,
        userName: 'Farhan',
        khatamProgressJuz: 15,
        khatamCount: 1,
        dateStr: '11 September 2026',
        bonusPoints: 50,
      );

      for (final theme in MilestoneCardTheme.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: MilestoneShareCard(
                    data: sampleData,
                    theme: theme,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Al-Kahfi'), findsOneWidget);
        expect(find.text('Farhan'), findsOneWidget);
        expect(find.text('110 Ayat'), findsOneWidget);
      }
    });

    testWidgets('MilestoneCelebrationDialog renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      const surahData = MilestoneCardData(
        type: MilestoneCardType.surah,
        title: 'Al-Kahfi',
        arabicTitle: 'الكهف',
        subtitle: 'Menuntaskan 110 Ayat Al-Qur\'an',
        surahNumber: 18,
        ayahCount: 110,
        durationMinutes: 28,
        userName: 'Farhan',
        khatamProgressJuz: 15,
        khatamCount: 1,
        dateStr: '11 September 2026',
        bonusPoints: 50,
        quote: 'Barangsiapa membaca Surah Al-Kahfi di hari Jumat, maka akan dipancarkan cahaya baginya...',
        quoteSource: '(HR. Hakim & Baihaqi)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MilestoneCelebrationDialog.show(context, data: surahData),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Pencapaian Berkah'), findsOneWidget);
      expect(find.text('Al-Kahfi'), findsOneWidget);
    });

    testWidgets('MilestoneCelebrationDialog renders on small screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const khatamData = MilestoneCardData(
        type: MilestoneCardType.khatam,
        title: "Khatam 30 Juz Al-Qur'an",
        arabicTitle: 'ختم القرآن الكريم',
        subtitle: 'Maha Benar Allah dengan Segala Firman-Nya',
        surahNumber: 114,
        ayahCount: 6236,
        durationMinutes: 120,
        userName: 'Muhammad Farhan Al-Ghifari',
        khatamProgressJuz: 30,
        khatamCount: 2,
        dateStr: '11 September 2026',
        bonusPoints: 500,
        quote: 'Sebaik-baik kalian adalah yang mempelajari Al-Qur\'an dan mengajarkannya.',
        quoteSource: '(HR. Bukhari)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MilestoneCelebrationDialog.show(context, data: khatamData),
                child: const Text('Open Khatam Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Khatam Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Mubarak! Khatam 30 Juz'), findsOneWidget);
      expect(find.text("Khatam 30 Juz Al-Qur'an"), findsOneWidget);
    });
  });
}
