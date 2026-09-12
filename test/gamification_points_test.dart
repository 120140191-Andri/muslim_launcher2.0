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

    test('Dzikir 3-round daily cap test (3+3+13 = 19 points max at Level 1)', () async {
      final appState = AppState(prefs);

      expect(appState.dailyDzikirRounds, 0);
      expect(appState.dailyDzikirPoints, 0);

      // Round 1: 33x Subhanallah -> +3 points
      final r1 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r1['round'], 1);
      expect(r1['pointsEarned'], 3);
      expect(r1['pointsEarned'], isA<int>());
      expect(r1['isDailyCapReached'], false);
      expect(appState.dailyDzikirPoints, 3);
      expect(appState.points, 3);

      // Round 2: 33x Alhamdulillah -> +3 points
      final r2 = await appState.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(r2['round'], 2);
      expect(r2['pointsEarned'], 3);
      expect(r2['pointsEarned'], isA<int>());
      expect(r2['isDailyCapReached'], false);
      expect(appState.dailyDzikirPoints, 6);
      expect(appState.points, 6);

      // Round 3: 33x Allahu Akbar -> +13 points (bonus)
      final r3 = await appState.saveDzikirProgress('Allahu Akbar', 33, 10);
      expect(r3['round'], 3);
      expect(r3['pointsEarned'], 13);
      expect(r3['pointsEarned'], isA<int>());
      expect(r3['isDailyCapReached'], true);
      expect(appState.dailyDzikirPoints, 19);
      expect(appState.points, 19);

      // Round 4 (exceeding 3 rounds): 0 points, but count recorded
      final r4 = await appState.saveDzikirProgress('Astaghfirullah', 33, 10);
      expect(r4['round'], 4);
      expect(r4['pointsEarned'], 0);
      expect(r4['isDailyCapReached'], true);
      expect(appState.dailyDzikirPoints, 19); // unchanged
      expect(appState.points, 19); // unchanged
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

      // Level 1 (0 Khatam): 2 pts short, 3 pts long
      final t1Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 0);
      final t1Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 0);
      expect(t1Short, 2);
      expect(t1Long, 3);
      expect(t1Short, isA<int>());
      expect(t1Long, isA<int>());

      // Level 2 (1 Khatam): 3 pts short, 4 pts long
      final t2Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 1);
      final t2Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 1);
      expect(t2Short, 3);
      expect(t2Long, 4);
      expect(t2Short, isA<int>());
      expect(t2Long, isA<int>());

      // Level 3 (2 Khatam): 4 pts short, 5 pts long
      final t3Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 2);
      final t3Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 2);
      expect(t3Short, 4);
      expect(t3Long, 5);
      expect(t3Short, isA<int>());
      expect(t3Long, isA<int>());

      // Level 4 (3-4 Khatam): 4 pts short, 6 pts long
      final t4Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 3);
      final t4Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 4);
      expect(t4Short, 4);
      expect(t4Long, 6);
      expect(t4Short, isA<int>());
      expect(t4Long, isA<int>());

      // Level 5 (5+ Khatam): 5 pts short, 7 pts long (Double points!)
      final t5Short = QuranProgressHelper.calculateAyahPoints(arabicLength: shortAyahLen, khatmCount: 5);
      final t5Long = QuranProgressHelper.calculateAyahPoints(arabicLength: longAyahLen, khatmCount: 12);
      expect(t5Short, 5);
      expect(t5Long, 7);
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

      // Round 1: (3 * 1.25).round() = 4
      final l2r1 = await appStateLevel2.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l2r1['pointsEarned'], 4);
      expect(l2r1['pointsEarned'], isA<int>());

      // Round 2: (3 * 1.25).round() = 4
      final l2r2 = await appStateLevel2.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(l2r2['pointsEarned'], 4);
      expect(l2r2['pointsEarned'], isA<int>());

      // Round 3: (13 * 1.25).round() = 16
      final l2r3 = await appStateLevel2.saveDzikirProgress('Allahu Akbar', 33, 10);
      expect(l2r3['pointsEarned'], 16);
      expect(l2r3['pointsEarned'], isA<int>());

      // Total daily points = 4 + 4 + 16 = 24
      expect(appStateLevel2.dailyDzikirPoints, 24);
      expect(appStateLevel2.points, 24);

      // Test at Level 5 (2.0x double points)
      final prefsL5 = await SharedPreferences.getInstance();
      await prefsL5.clear();
      await prefsL5.setInt('khatmCount', 5);
      final appStateLevel5 = AppState(prefsL5);

      // Round 1: (3 * 2.0).round() = 6
      final l5r1 = await appStateLevel5.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l5r1['pointsEarned'], 6);
      expect(l5r1['pointsEarned'], isA<int>());

      // Round 2: (3 * 2.0).round() = 6
      final l5r2 = await appStateLevel5.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(l5r2['pointsEarned'], 6);
      expect(l5r2['pointsEarned'], isA<int>());

      // Round 3: (13 * 2.0).round() = 26
      final l5r3 = await appStateLevel5.saveDzikirProgress('Allahu Akbar', 33, 10);
      expect(l5r3['pointsEarned'], 26);
      expect(l5r3['pointsEarned'], isA<int>());

      // Total daily points = 6 + 6 + 26 = 38 (Under 50 pts anchor, maintaining digital detox)
      expect(appStateLevel5.dailyDzikirPoints, 38);
      expect(appStateLevel5.points, 38);
    });
  });
}
