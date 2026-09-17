import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/utils/quran_progress_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getApps') {
        return [];
      }
      return true;
    });
  });

  group('Gamification Points & Bonus Economy Tests', () {
    test('Surah tier bonus points calculation at Level 1 (1.0x)', () async {
      final appState = AppState(prefs);

      // Initial points
      expect(appState.points, 0);
      expect(appState.maqamLevel, 1);
      expect(appState.maqamBoostMultiplier, 1.0);
      expect(appState.maqamBoostPercent, 0);

      // Tier 1 Surah (<= 25 ayahs): +10 points
      final resTier1 = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(resTier1['isNewMilestone'], true);
      expect(resTier1['tier'], 1);
      expect(resTier1['bonusPoints'], 10);
      expect(resTier1['bonusPoints'], isA<int>());
      expect(appState.points, 10);

      // Tier 2 Surah (26-75 ayahs): +25 points
      final resTier2 = await appState.completeSurahMilestone(
        surahNumber: 67,
        surahName: 'Al-Mulk',
        totalAyahs: 30,
      );
      expect(resTier2['tier'], 2);
      expect(resTier2['bonusPoints'], 25);
      expect(resTier2['bonusPoints'], isA<int>());
      expect(appState.points, 35);

      // Tier 3 Surah (76-150 ayahs): +50 points
      final resTier3 = await appState.completeSurahMilestone(
        surahNumber: 36,
        surahName: 'Ya-Sin',
        totalAyahs: 83,
      );
      expect(resTier3['tier'], 3);
      expect(resTier3['bonusPoints'], 50);
      expect(resTier3['bonusPoints'], isA<int>());
      expect(appState.points, 85);

      // Tier 4 Surah (> 150 ayahs): +100 points
      final resTier4 = await appState.completeSurahMilestone(
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        totalAyahs: 286,
      );
      expect(resTier4['tier'], 4);
      expect(resTier4['bonusPoints'], 100);
      expect(resTier4['bonusPoints'], isA<int>());
      expect(appState.points, 185);

      // Non-renewable check in the same cycle: reading Al-Fatihah again gives 0 bonus
      final resDup = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(resDup['isNewMilestone'], false);
      expect(resDup['bonusPoints'], 0);
      expect(appState.points, 185);
    });

    test('Dzikir per-preset 1-round daily reward (5 pts fresh, 1 pt repeat at Level 1)', () async {
      final appState = AppState(prefs);

      expect(appState.dailyDzikirRounds, 0);
      expect(appState.dailyDzikirPoints, 0);

      // Round 1: 33x Subhanallah (fresh preset) -> +5 points
      final r1 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r1['round'], 1);
      expect(r1['presetRound'], 1);
      expect(r1['isFirstPresetRound'], true);
      expect(r1['pointsEarned'], 5);
      expect(r1['pointsEarned'], isA<int>());
      expect(appState.dailyDzikirPoints, 5);
      expect(appState.points, 5);
      expect(appState.getDzikirPresetRounds('Subhanallah'), 1);

      // Round 2: 33x Alhamdulillah (fresh preset) -> +5 points
      final r2 = await appState.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(r2['round'], 2);
      expect(r2['presetRound'], 1);
      expect(r2['isFirstPresetRound'], true);
      expect(r2['pointsEarned'], 5);
      expect(r2['pointsEarned'], isA<int>());
      expect(appState.dailyDzikirPoints, 10);
      expect(appState.points, 10);
      expect(appState.getDzikirPresetRounds('Alhamdulillah'), 1);

      // Round 3: 33x Allahu Akbar (fresh preset) -> +5 points
      final r3 = await appState.saveDzikirProgress('Allahu Akbar', 33, 10);
      expect(r3['round'], 3);
      expect(r3['presetRound'], 1);
      expect(r3['isFirstPresetRound'], true);
      expect(r3['pointsEarned'], 5);
      expect(r3['pointsEarned'], isA<int>());
      expect(appState.dailyDzikirPoints, 15);
      expect(appState.points, 15);

      // Round 4: 33x Subhanallah (repeat of Subhanallah) -> reduced to +2 points
      final r4 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r4['round'], 4);
      expect(r4['presetRound'], 2);
      expect(r4['isFirstPresetRound'], false);
      expect(r4['pointsEarned'], 2); // Reduced points (2 pts), not 0
      expect(r4['pointsEarned'], isA<int>());
      expect(appState.dailyDzikirPoints, 17);
      expect(appState.points, 17);
      expect(appState.getDzikirPresetRounds('Subhanallah'), 2);

      // Round 5: 33x Astaghfirullah (fresh preset) -> +5 points
      final r5 = await appState.saveDzikirProgress('Astaghfirullah', 33, 10);
      expect(r5['round'], 5);
      expect(r5['presetRound'], 1);
      expect(r5['isFirstPresetRound'], true);
      expect(r5['pointsEarned'], 5);
      expect(appState.dailyDzikirPoints, 22);
      expect(appState.points, 22);
    });

    test('Khatam 30 Juz completion, level increment, +500 bonus, and cycle reset', () async {
      final appState = AppState(prefs);

      expect(appState.khatmCount, 0);
      expect(appState.completedSurahsThisCycle.length, 0);

      // Simulate completing surahs 1 to 113
      for (int i = 1; i <= 113; i++) {
        await appState.completeSurahMilestone(
          surahNumber: i,
          surahName: 'Surah $i',
          totalAyahs: 10,
        );
      }

      expect(appState.completedSurahsThisCycle.length, 113);
      expect(appState.khatmCount, 0);
      final currentPointsBeforeKhatm = appState.points;

      // Now complete the final surah (Surah 114 An-Nas)
      final resKhatam = await appState.completeSurahMilestone(
        surahNumber: 114,
        surahName: 'An-Nas',
        totalAyahs: 6,
      );

      // Verifications:
      expect(resKhatam['isKhatam'], true);
      expect(resKhatam['isNewMilestone'], true);
      // Khatam level increments from 0 to 1
      expect(appState.khatmCount, 1);
      // Grand bonus +500 points (plus Tier 1 10 pts for An-Nas)
      expect(appState.points, currentPointsBeforeKhatm + 10 + 500);
      // Reading cycle resets: completedSurahsThisCycle is cleared for the next cycle
      expect(appState.completedSurahsThisCycle.length, 0);

      // Verify that in the new cycle (khatmCount = 1, Level 2, 1.25x boost):
      // Al-Fatihah (Tier 1 base 10 pts) yields: (10 * 1.25).round() = 13 points!
      final resNewCycle = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(resNewCycle['isNewMilestone'], true);
      expect(resNewCycle['bonusPoints'], 13);
      expect(resNewCycle['bonusPoints'], isA<int>());
      expect(resNewCycle['boostPercent'], 25);
      expect(appState.completedSurahsThisCycle.contains(1), true);
    });

    test('Reading Surah 114 alone awards Tier bonus but does NOT trigger premature Khatam 30 Juz', () async {
      final appState = AppState(prefs);

      expect(appState.khatmCount, 0);
      expect(appState.completedSurahsThisCycle.length, 0);

      // Complete only Surah 114 (An-Nas) without completing the other 113 surahs
      final res = await appState.completeSurahMilestone(
        surahNumber: 114,
        surahName: 'An-Nas',
        totalAyahs: 6,
      );

      // It should be a milestone with normal tier bonus (+10 pts at Level 1)
      expect(res['isNewMilestone'], true);
      expect(res['isKhatam'], false);
      expect(res['bonusPoints'], 10);

      // Crucial: Khatm count must stay 0, completed surahs must contain 114 (length 1), not reset!
      expect(appState.khatmCount, 0);
      expect(appState.completedSurahsThisCycle.length, 1);
      expect(appState.completedSurahsThisCycle.contains(114), true);
    });

    test('Maqam Boost Multipliers and Percentages for all 5 levels', () {
      // Level 1: 0 Khatam
      expect(QuranProgressHelper.getMaqamLevel(0), 1);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(0), 1.0);
      expect(QuranProgressHelper.getMaqamBoostPercent(0), 0);

      // Level 2: 1x Khatam
      expect(QuranProgressHelper.getMaqamLevel(1), 2);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(1), 1.25);
      expect(QuranProgressHelper.getMaqamBoostPercent(1), 25);

      // Level 3: 2x Khatam
      expect(QuranProgressHelper.getMaqamLevel(2), 3);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(2), 1.50);
      expect(QuranProgressHelper.getMaqamBoostPercent(2), 50);

      // Level 4: 3-4x Khatam
      expect(QuranProgressHelper.getMaqamLevel(3), 4);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(3), 1.75);
      expect(QuranProgressHelper.getMaqamBoostPercent(3), 75);
      expect(QuranProgressHelper.getMaqamLevel(4), 4);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(4), 1.75);
      expect(QuranProgressHelper.getMaqamBoostPercent(4), 75);

      // Level 5: 5x+ Khatam
      expect(QuranProgressHelper.getMaqamLevel(5), 5);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(5), 2.00);
      expect(QuranProgressHelper.getMaqamBoostPercent(5), 100);
      expect(QuranProgressHelper.getMaqamLevel(10), 5);
      expect(QuranProgressHelper.getMaqamBoostMultiplier(10), 2.00);
      expect(QuranProgressHelper.getMaqamBoostPercent(10), 100);
    });

    test('Quran Ayah points calculation strictly whole integers (no decimals/commas)', () {
      const shortAyahLen = 40;
      const longAyahLen = 120;

      // Level 1 (0 Khatam): 3 pts short, 5 pts long
      final t1Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 0);
      final t1Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 0);
      expect(t1Short, 3);
      expect(t1Long, 5);
      expect(t1Short, isA<int>());
      expect(t1Long, isA<int>());

      // Level 2 (1 Khatam): 4 pts short, 6 pts long
      final t2Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 1);
      final t2Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 1);
      expect(t2Short, 4);
      expect(t2Long, 6);
      expect(t2Short, isA<int>());
      expect(t2Long, isA<int>());

      // Level 3 (2 Khatam): 5 pts short, 8 pts long
      final t3Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 2);
      final t3Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 2);
      expect(t3Short, 5);
      expect(t3Long, 8);
      expect(t3Short, isA<int>());
      expect(t3Long, isA<int>());

      // Level 4 (3-4 Khatam): 6 pts short, 9 pts long
      final t4Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 3);
      final t4Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 4);
      expect(t4Short, 6);
      expect(t4Long, 9);
      expect(t4Short, isA<int>());
      expect(t4Long, isA<int>());

      // Level 5 (5+ Khatam): 7 pts short, 10 pts long (Double points!)
      final t5Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 5);
      final t5Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 12);
      expect(t5Short, 7);
      expect(t5Long, 10);
      expect(t5Short, isA<int>());
      expect(t5Long, isA<int>());
    });

    test('Surah milestone points scaling at Level 5 (2.0x Double Points)', () async {
      await prefs.setInt('khatmCount', 5);
      final appState = AppState(prefs);

      expect(appState.maqamLevel, 5);
      expect(appState.maqamBoostMultiplier, 2.0);
      expect(appState.maqamBoostPercent, 100);

      // Tier 1 (base 10) * 2.0 = 20
      final r1 = await appState.completeSurahMilestone(surahNumber: 1, surahName: 'Al-Fatihah', totalAyahs: 7);
      expect(r1['bonusPoints'], 20);
      expect(r1['bonusPoints'], isA<int>());

      // Tier 2 (base 25) * 2.0 = 50
      final r2 = await appState.completeSurahMilestone(surahNumber: 67, surahName: 'Al-Mulk', totalAyahs: 30);
      expect(r2['bonusPoints'], 50);
      expect(r2['bonusPoints'], isA<int>());

      // Tier 3 (base 50) * 2.0 = 100
      final r3 = await appState.completeSurahMilestone(surahNumber: 36, surahName: 'Ya-Sin', totalAyahs: 83);
      expect(r3['bonusPoints'], 100);
      expect(r3['bonusPoints'], isA<int>());

      // Tier 4 (base 100) * 2.0 = 200
      final r4 = await appState.completeSurahMilestone(surahNumber: 2, surahName: 'Al-Baqarah', totalAyahs: 286);
      expect(r4['bonusPoints'], 200);
      expect(r4['bonusPoints'], isA<int>());

      // All points in AppState are strictly whole integers
      expect(appState.points, 20 + 50 + 100 + 200);
      expect(appState.points, isA<int>());
    });

    test('Dzikir points scaling and rounding at Level 2 (1.25x) and Level 5 (2.0x)', () async {
      // Test at Level 2 (1.25x boost)
      await prefs.setInt('khatmCount', 1);
      final appStateLevel2 = AppState(prefs);

      // Round 1 (Subhanallah fresh): (5 * 1.25).round() = 6
      final l2r1 = await appStateLevel2.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l2r1['pointsEarned'], 6);
      expect(l2r1['pointsEarned'], isA<int>());

      // Round 2 (Subhanallah repeat): (2 * 1.25).round() = 3
      final l2r2 = await appStateLevel2.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l2r2['pointsEarned'], 3);
      expect(l2r2['pointsEarned'], isA<int>());

      // Round 3 (Alhamdulillah fresh): (5 * 1.25).round() = 6
      final l2r3 = await appStateLevel2.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(l2r3['pointsEarned'], 6);
      expect(l2r3['pointsEarned'], isA<int>());

      // Total daily points = 6 + 3 + 6 = 15
      expect(appStateLevel2.dailyDzikirPoints, 15);
      expect(appStateLevel2.points, 15);

      // Test at Level 5 (2.0x double points)
      final prefsL5 = await SharedPreferences.getInstance();
      await prefsL5.clear();
      await prefsL5.setInt('khatmCount', 5);
      final appStateLevel5 = AppState(prefsL5);

      // Round 1 (Subhanallah fresh): (5 * 2.0).round() = 10
      final l5r1 = await appStateLevel5.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l5r1['pointsEarned'], 10);
      expect(l5r1['pointsEarned'], isA<int>());

      // Round 2 (Subhanallah repeat): (2 * 2.0).round() = 4
      final l5r2 = await appStateLevel5.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l5r2['pointsEarned'], 4);
      expect(l5r2['pointsEarned'], isA<int>());

      // Round 3 (Alhamdulillah fresh): (5 * 2.0).round() = 10
      final l5r3 = await appStateLevel5.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(l5r3['pointsEarned'], 10);
      expect(l5r3['pointsEarned'], isA<int>());

      // Total daily points = 10 + 4 + 10 = 24
      expect(appStateLevel5.dailyDzikirPoints, 24);
      expect(appStateLevel5.points, 24);
    });

    test('Progressive Grand Khatam Bonus helper returns progressive rewards', () {
      expect(QuranProgressHelper.getGrandKhatamBonus(0), 500);
      expect(QuranProgressHelper.getGrandKhatamBonus(1), 500);
      expect(QuranProgressHelper.getGrandKhatamBonus(2), 750);
      expect(QuranProgressHelper.getGrandKhatamBonus(3), 1000);
      expect(QuranProgressHelper.getGrandKhatamBonus(4), 1250);
      expect(QuranProgressHelper.getGrandKhatamBonus(5), 1500);
      expect(QuranProgressHelper.getGrandKhatamBonus(10), 1500);
    });

    test('Daily 10-Ayahs Boost adds +2 pts bonus for first 10 ayahs and resets daily', () async {
      final appState = AppState(prefs);

      expect(appState.dailyAyahsReadCount, 0);
      expect(appState.dailyAyahsBoostRemaining, 10);

      // Level 1 base for short ayah (len 30) is 3 pts. With boost: 3 + 2 = 5 pts.
      for (int i = 0; i < 10; i++) {
        expect(appState.dailyAyahsBoostRemaining, 10 - i);
        final pts = appState.calculateAndConsumeAyahPoints(30);
        expect(pts, 5); // 3 base + 2 boost
        expect(appState.dailyAyahsReadCount, i + 1);
      }

      expect(appState.dailyAyahsReadCount, 10);
      expect(appState.dailyAyahsBoostRemaining, 0);

      // 11th ayah: boost consumed, returns standard base 3 pts
      final pts11 = appState.calculateAndConsumeAyahPoints(30);
      expect(pts11, 3);
      expect(appState.dailyAyahsReadCount, 10);
      expect(appState.dailyAyahsBoostRemaining, 0);

      // Simulate day reset
      appState.setDailyAyahsReadForTesting(10, date: '2026-01-01');
      expect(appState.dailyAyahsBoostRemaining, 10);
      expect(appState.dailyAyahsReadCount, 0);
    });

    test('Scaling Unlock Cost scales from 50 to 75 to 100 pts and resets daily', () async {
      final appState = AppState(prefs);

      expect(appState.dailyUnlocksCount, 0);
      expect(appState.currentUnlockCost, 50);

      // Add points to test unlocking
      appState.addPoints(500);
      expect(appState.points, 500);

      // Unlock 1: costs 50 pts
      final u1 = await appState.unlockAppWithPoints('com.test.app1');
      expect(u1, true);
      expect(appState.points, 450);
      expect(appState.dailyUnlocksCount, 1);
      expect(appState.currentUnlockCost, 75);

      // Unlock 2: costs 75 pts
      final u2 = await appState.unlockAppWithPoints('com.test.app2');
      expect(u2, true);
      expect(appState.points, 375);
      expect(appState.dailyUnlocksCount, 2);
      expect(appState.currentUnlockCost, 100);

      // Unlock 3: costs 100 pts
      final u3 = await appState.unlockAppWithPoints('com.test.app3');
      expect(u3, true);
      expect(appState.points, 275);
      expect(appState.dailyUnlocksCount, 3);
      expect(appState.currentUnlockCost, 100);

      // Simulate day reset
      appState.setDailyUnlocksForTesting(3, date: '2026-01-01');
      expect(appState.dailyUnlocksCount, 0);
      expect(appState.currentUnlockCost, 50);
    });
  });
}
