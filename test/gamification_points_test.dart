import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';

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
    test('Surah tier bonus points calculation', () async {
      final appState = AppState(prefs);

      // Initial points
      expect(appState.points, 0);

      // Tier 1 Surah (<= 25 ayahs): +10 points
      final resTier1 = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(resTier1['isNewMilestone'], true);
      expect(resTier1['tier'], 1);
      expect(resTier1['bonusPoints'], 10);
      expect(appState.points, 10);

      // Tier 2 Surah (26-75 ayahs): +25 points
      final resTier2 = await appState.completeSurahMilestone(
        surahNumber: 67,
        surahName: 'Al-Mulk',
        totalAyahs: 30,
      );
      expect(resTier2['tier'], 2);
      expect(resTier2['bonusPoints'], 25);
      expect(appState.points, 35);

      // Tier 3 Surah (76-150 ayahs): +50 points
      final resTier3 = await appState.completeSurahMilestone(
        surahNumber: 36,
        surahName: 'Ya-Sin',
        totalAyahs: 83,
      );
      expect(resTier3['tier'], 3);
      expect(resTier3['bonusPoints'], 50);
      expect(appState.points, 85);

      // Tier 4 Surah (> 150 ayahs): +100 points
      final resTier4 = await appState.completeSurahMilestone(
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        totalAyahs: 286,
      );
      expect(resTier4['tier'], 4);
      expect(resTier4['bonusPoints'], 100);
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

    test('Dzikir 3-round daily cap test (3+3+13 = 19 points max)', () async {
      final appState = AppState(prefs);

      expect(appState.dailyDzikirRounds, 0);
      expect(appState.dailyDzikirPoints, 0);

      // Round 1: 33x Subhanallah -> +3 points
      final r1 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r1['round'], 1);
      expect(r1['pointsEarned'], 3);
      expect(r1['isDailyCapReached'], false);
      expect(appState.dailyDzikirPoints, 3);
      expect(appState.points, 3);

      // Round 2: 33x Alhamdulillah -> +3 points
      final r2 = await appState.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(r2['round'], 2);
      expect(r2['pointsEarned'], 3);
      expect(r2['isDailyCapReached'], false);
      expect(appState.dailyDzikirPoints, 6);
      expect(appState.points, 6);

      // Round 3: 33x Allahu Akbar -> +13 points (bonus)
      final r3 = await appState.saveDzikirProgress('Allahu Akbar', 33, 10);
      expect(r3['round'], 3);
      expect(r3['pointsEarned'], 13);
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

      // Verify that in the new cycle (khatmCount = 1), Al-Fatihah can be completed again!
      final resNewCycle = await appState.completeSurahMilestone(
        surahNumber: 1,
        surahName: 'Al-Fatihah',
        totalAyahs: 7,
      );
      expect(resNewCycle['isNewMilestone'], true);
      expect(resNewCycle['bonusPoints'], 10);
      expect(appState.completedSurahsThisCycle.contains(1), true);
    });
  });
}
