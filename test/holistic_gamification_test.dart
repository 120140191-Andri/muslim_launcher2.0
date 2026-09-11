import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/milestone/milestone_gallery_screen.dart';
import 'package:muslim_launcher_2/screens/home/blocked_app_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Holistic Gamification & Titration Economy Tests', () {
    late SharedPreferences prefs;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'languageCode': 'id'});
      prefs = await SharedPreferences.getInstance();

      const channelBlock = MethodChannel('com.muslimlauncher/block');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelBlock, (call) async => true);

      const channelApps = MethodChannel('com.muslimlauncher/apps');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelApps, (call) async => true);

      appState = AppState(prefs);
    });

    test('Maqam Spiritual Ranks progress accurately with khatam count', () async {
      // 0x Khatam -> Tier 1: Pejuang Istiqomah
      expect(appState.khatmCount, 0);
      expect(appState.currentMaqamRank.tier, 1);
      expect(appState.currentMaqamRank.title, 'Pejuang Istiqomah');
      expect(appState.currentMaqamRank.crownEmoji, '🌿');

      // 1x Khatam -> Tier 2: Al-Mubtadi' Al-Karim
      await prefs.setInt('khatmCount', 1);
      final s1 = AppState(prefs);
      expect(s1.currentMaqamRank.tier, 2);
      expect(s1.currentMaqamRank.title, "Al-Mubtadi' Al-Karim");
      expect(s1.currentMaqamRank.crownEmoji, '🥉');

      // 2x Khatam -> Tier 3: Sahabat Al-Qur\'an
      await prefs.setInt('khatmCount', 2);
      final s2 = AppState(prefs);
      expect(s2.currentMaqamRank.tier, 3);
      expect(s2.currentMaqamRank.title, 'Sahabat Al-Qur\'an');
      expect(s2.currentMaqamRank.crownEmoji, '🥈');

      // 3x Khatam -> Tier 4: Penjaga Cahaya
      await prefs.setInt('khatmCount', 3);
      final s3 = AppState(prefs);
      expect(s3.currentMaqamRank.tier, 4);
      expect(s3.currentMaqamRank.title, 'Penjaga Cahaya');
      expect(s3.currentMaqamRank.crownEmoji, '🥇');

      // 5x Khatam -> Tier 5: Ahlul Qur\'an Al-Mubarok
      await prefs.setInt('khatmCount', 5);
      final s5 = AppState(prefs);
      expect(s5.currentMaqamRank.tier, 5);
      expect(s5.currentMaqamRank.title, "Ahlul Qur'an Al-Mubarok");
      expect(s5.currentMaqamRank.crownEmoji, '👑💎');
    });

    test('30 Juz Mapping accurately categorizes boundaries and Khatam phases', () async {
      // Al-Fatihah (Surah 1, Ayah 1) -> Juz 1
      expect(AppState.getJuzForSurahAndAyah(1, 1), 1);

      // Al-Baqarah Ayah 142 -> Juz 2
      expect(AppState.getJuzForSurahAndAyah(2, 142), 2);

      // Al-Baqarah Ayah 253 -> Juz 3
      expect(AppState.getJuzForSurahAndAyah(2, 253), 3);

      // An-Naba (Surah 78, Ayah 1) -> Juz 30
      expect(AppState.getJuzForSurahAndAyah(78, 1), 30);

      // An-Nas (Surah 114, Ayah 1) -> Juz 30
      expect(AppState.getJuzForSurahAndAyah(114, 1), 30);

      // Phase tests:
      // Juz 1-6 -> Grand Climb
      await prefs.setInt('highestSurahIndex', 0); // Al-Fatihah (Juz 1)
      final statePhase1 = AppState(prefs);
      expect(statePhase1.currentKhatamPhase, KhatamPhase.grandClimb);
      expect(statePhase1.currentKhatamPhase.nameId, contains('Grand Climb'));

      // Juz 7-27 -> Rhythmic Cadence
      await prefs.setInt('highestSurahIndex', 6); // Al-A'raf (Surah 7 -> Juz 8/9)
      final statePhase2 = AppState(prefs);
      expect(statePhase2.currentKhatamPhase, KhatamPhase.rhythmicCadence);
      expect(statePhase2.currentKhatamPhase.nameId, contains('Rhythmic Cadence'));

      // Juz 28-30 -> Sprint to Summit
      await prefs.setInt('highestSurahIndex', 77); // An-Naba (Surah 78 -> Juz 30)
      final statePhase3 = AppState(prefs);
      expect(statePhase3.currentKhatamPhase, KhatamPhase.sprintSummit);
      expect(statePhase3.currentKhatamPhase.nameId, contains('Sprint to the Summit'));
    });

    test('Decaying Session Length titrates down as Juz advances (45m -> 15m)', () async {
      // Juz 1-5 -> 45 minutes
      await prefs.setInt('highestSurahIndex', 0); // Juz 1
      final s1 = AppState(prefs);
      expect(s1.dynamicUnlockDurationMinutes, 45);

      // Juz 6-15 -> 30 minutes
      await prefs.setInt('highestSurahIndex', 5); // Al-An'am (Juz 7)
      final s2 = AppState(prefs);
      expect(s2.dynamicUnlockDurationMinutes, 30);

      // Juz 16-25 -> 20 minutes
      await prefs.setInt('highestSurahIndex', 18); // Surah 19 Maryam (Juz 16)
      final s3 = AppState(prefs);
      expect(s3.dynamicUnlockDurationMinutes, 20);

      // Juz 26-30 -> 15 minutes
      await prefs.setInt('highestSurahIndex', 77); // Juz 30
      final s4 = AppState(prefs);
      expect(s4.dynamicUnlockDurationMinutes, 15);
    });

    test('Progressive Marginal Cost increases with daily unlock sessions', () async {
      // Session 1 (0 unlocks today) -> 20 pts
      expect(appState.dailyUnlockSessionCount, 0);
      expect(appState.currentUnlockPointCost, 20);

      // Simulate giving 200 points
      await appState.addPoints(200);
      expect(appState.points >= 200, true);

      // Unlock 1st session: costs 20 pts
      final initialPts = appState.points;
      final u1 = await appState.unlockAppWithPoints('com.instagram.android');
      expect(u1, true);
      expect(appState.dailyUnlockSessionCount, 1);
      expect(appState.points, initialPts - 20);
      // Session 2 cost -> 35 pts
      expect(appState.currentUnlockPointCost, 35);

      // Unlock 2nd session: costs 35 pts
      final ptsAfter1 = appState.points;
      final u2 = await appState.unlockAppWithPoints('com.instagram.android');
      expect(u2, true);
      expect(appState.dailyUnlockSessionCount, 2);
      expect(appState.points, ptsAfter1 - 35);
      // Session 3 cost -> 50 pts
      expect(appState.currentUnlockPointCost, 50);

      // Unlock 3rd session: costs 50 pts
      final ptsAfter2 = appState.points;
      final u3 = await appState.unlockAppWithPoints('com.instagram.android');
      expect(u3, true);
      expect(appState.dailyUnlockSessionCount, 3);
      expect(appState.points, ptsAfter2 - 50);
      // Session 4+ cost -> 75 pts
      expect(appState.currentUnlockPointCost, 75);

      // Unlock 4th session: costs 75 pts
      final ptsAfter3 = appState.points;
      final u4 = await appState.unlockAppWithPoints('com.instagram.android');
      expect(u4, true);
      expect(appState.dailyUnlockSessionCount, 4);
      expect(appState.points, ptsAfter3 - 75);
      // Still 75 pts for 5th session
      expect(appState.currentUnlockPointCost, 75);
    });

    testWidgets('MilestoneGalleryScreen renders Maqam header and tabs properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      appState.setQuranDataForTesting([
        {
          'surah_number': 1,
          'surah_name': 'Al-Fatihah',
          'total_ayah': 7,
          'ayahs': List.generate(7, (i) => {'ayah': i + 1}),
        },
        {
          'surah_number': 2,
          'surah_name': 'Al-Baqarah',
          'total_ayah': 286,
          'ayahs': List.generate(286, (i) => {'ayah': i + 1}),
        },
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const MilestoneGalleryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header presence
      expect(find.text('Galeri Pencapaian'), findsOneWidget);
      expect(find.text(appState.currentMaqamRank.title), findsOneWidget);
      expect(find.text(appState.currentMaqamRank.crownEmoji), findsWidgets);

      // Check tab bars
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text("Al-Qur'an"), findsOneWidget);
      expect(find.text('Dzikir'), findsOneWidget);
      expect(find.text('Khatam'), findsOneWidget);

      // Switch to Al-Qur'an tab
      await tester.tap(find.text("Al-Qur'an"));
      await tester.pumpAndSettle();

      // Check Surah 1 Al-Fatihah is rendered
      expect(find.text('Al-Fatihah'), findsOneWidget);

      // Switch to Dzikir tab
      await tester.tap(find.text('Dzikir'));
      await tester.pumpAndSettle();
      expect(find.text('Subhanallah'), findsWidgets);

      // Switch to Khatam tab
      await tester.tap(find.text('Khatam'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Khatam'), findsWidgets);
    });

    testWidgets('BlockedAppScreen renders dynamic session minutes and point costs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      // Give 50 points so unlock button is enabled
      await appState.addPoints(50);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: const BlockedAppScreen(
              packageName: 'com.tiktok.android',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display dynamic duration and point cost
      final duration = appState.dynamicUnlockDurationMinutes;
      final cost = appState.currentUnlockPointCost;

      expect(find.textContaining('$duration Menit'), findsWidgets);
      expect(find.textContaining('$cost Poin'), findsWidgets);
    });
  });
}
