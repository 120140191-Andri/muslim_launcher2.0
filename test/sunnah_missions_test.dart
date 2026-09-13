import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/utils/sunnah_mission_helper.dart';
import 'package:muslim_launcher_2/screens/home/achievements_screen.dart';
import 'package:muslim_launcher_2/screens/home/home_screen.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

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

  group('Prophet\'s Sunnah Missions & Time Windows Tests', () {
    test('Friday Al-Kahf window detection (Thursday 18:00 to Friday 18:30)', () {
      // Thursday 17:59 -> inactive
      final thursBefore = DateTime(2026, 9, 10, 17, 59); // 2026-09-10 is Thursday
      expect(SunnahMissionHelper.isFridayKahfActive(thursBefore), isFalse);

      // Thursday 18:00 -> active
      final thursActive = DateTime(2026, 9, 10, 18, 0);
      expect(SunnahMissionHelper.isFridayKahfActive(thursActive), isTrue);

      // Friday 12:00 -> active
      final fridayNoon = DateTime(2026, 9, 11, 12, 0);
      expect(SunnahMissionHelper.isFridayKahfActive(fridayNoon), isTrue);

      // Friday 18:30 -> active
      final fridaySunset = DateTime(2026, 9, 11, 18, 30);
      expect(SunnahMissionHelper.isFridayKahfActive(fridaySunset), isTrue);

      // Friday 18:31 -> inactive
      final fridayAfter = DateTime(2026, 9, 11, 18, 31);
      expect(SunnahMissionHelper.isFridayKahfActive(fridayAfter), isFalse);

      // Saturday 10:00 -> inactive
      final sat = DateTime(2026, 9, 12, 10, 0);
      expect(SunnahMissionHelper.isFridayKahfActive(sat), isFalse);
    });

    test('Night window detection (19:00 to 23:59)', () {
      // 18:59 -> inactive
      final beforeNight = DateTime(2026, 9, 12, 18, 59);
      expect(SunnahMissionHelper.isNightActive(beforeNight), isFalse);

      // 19:00 -> active
      final nightStart = DateTime(2026, 9, 12, 19, 0);
      expect(SunnahMissionHelper.isNightActive(nightStart), isTrue);

      // 21:00 -> active
      final midNight = DateTime(2026, 9, 12, 21, 0);
      expect(SunnahMissionHelper.isNightActive(midNight), isTrue);

      // 23:59 -> active
      final lateNight = DateTime(2026, 9, 12, 23, 59);
      expect(SunnahMissionHelper.isNightActive(lateNight), isTrue);

      // 00:00 (ganti hari) -> inactive
      final pastMidnight = DateTime(2026, 9, 13, 0, 0);
      expect(SunnahMissionHelper.isNightActive(pastMidnight), isFalse);

      // 02:00 next morning -> inactive
      final earlyMorning = DateTime(2026, 9, 13, 2, 0);
      expect(SunnahMissionHelper.isNightActive(earlyMorning), isFalse);
    });

    test('Fajr window detection (04:00 to 06:30)', () {
      // 03:59 -> inactive
      final beforeFajr = DateTime(2026, 9, 13, 3, 59);
      expect(SunnahMissionHelper.isFajrActive(beforeFajr), isFalse);

      // 04:00 -> active
      final fajrStart = DateTime(2026, 9, 13, 4, 0);
      expect(SunnahMissionHelper.isFajrActive(fajrStart), isTrue);

      // 05:15 -> active
      final fajrMid = DateTime(2026, 9, 13, 5, 15);
      expect(SunnahMissionHelper.isFajrActive(fajrMid), isTrue);

      // 06:30 -> active
      final fajrEnd = DateTime(2026, 9, 13, 6, 30);
      expect(SunnahMissionHelper.isFajrActive(fajrEnd), isTrue);

      // 06:31 -> inactive
      final afterFajr = DateTime(2026, 9, 13, 6, 31);
      expect(SunnahMissionHelper.isFajrActive(afterFajr), isFalse);
    });

    test('Anti-gaming claim key per night session (19:00 to 23:59)', () {
      // 21:00 on Saturday night
      final satNight1 = DateTime(2026, 9, 12, 21, 0);
      final key1 = SunnahMissionHelper.getAntiGamingClaimKey('almulk_malam', satNight1);

      // 23:30 on Saturday night (same night before day change)
      final satNight2 = DateTime(2026, 9, 12, 23, 30);
      final key2 = SunnahMissionHelper.getAntiGamingClaimKey('almulk_malam', satNight2);

      expect(key1, equals(key2),
          reason: 'Both timestamps on the same night before midnight map to the same claim session');

      // Next Sunday night (21:00) -> should be a new claim key
      final nextNight = DateTime(2026, 9, 13, 21, 0);
      final key3 = SunnahMissionHelper.getAntiGamingClaimKey('almulk_malam', nextNight);
      expect(key1, isNot(equals(key3)));
    });

    test('Friday Kahf anti-gaming claim key maps Thursday night & Friday to same Friday date', () {
      final thursNight = DateTime(2026, 9, 10, 20, 0);
      final friNoon = DateTime(2026, 9, 11, 14, 0);

      final keyThurs = SunnahMissionHelper.getAntiGamingClaimKey('alkahf_jumat', thursNight);
      final keyFri = SunnahMissionHelper.getAntiGamingClaimKey('alkahf_jumat', friNoon);

      expect(keyThurs, equals(keyFri));
    });
  });

  group('Sunnah Mission Points & Anti-Gaming Execution Tests', () {
    test('Completing Al-Mulk awards +50 pts bonus once, rejects duplicate farming', () async {
      final appState = AppState(prefs);
      final nightTime = DateTime(2026, 9, 12, 21, 0);

      expect(appState.points, 0);
      expect(appState.isSunnahMissionCompletedToday('almulk_malam', nightTime), isFalse);

      // First completion -> marks milestone completed, points awarded via Achievements claim
      final res1 = await appState.completeSunnahMission(
        missionId: 'almulk_malam',
        missionTitle: 'Surah Al-Mulk',
        pointsReward: 50,
        dateTime: nightTime,
      );

      expect(res1['isNewMilestone'], isTrue);
      expect(res1['alreadyClaimed'], isFalse);
      expect(res1['pointsEarned'], 50);
      // Points must NOT be added directly upon reading (prevents double points)
      expect(appState.points, 0);
      expect(appState.isSunnahMissionCompletedToday('almulk_malam', nightTime), isTrue);
      expect(appState.isSunnahMissionCompletedLifetime('almulk_malam'), isTrue);

      // User claims badge reward in AchievementsScreen
      final claimed = await appState.claimBadgeReward('sunnah_almulk', 50, 'Surah Al-Mulk');
      expect(claimed, isTrue);
      expect(appState.points, 50);

      // Attempt second completion at 23:30 (same night before day change) -> rejected, 0 pts
      final lateNightTime = DateTime(2026, 9, 12, 23, 30);
      final res2 = await appState.completeSunnahMission(
        missionId: 'almulk_malam',
        missionTitle: 'Surah Al-Mulk',
        pointsReward: 50,
        dateTime: lateNightTime,
      );

      expect(res2['isNewMilestone'], isFalse);
      expect(res2['alreadyClaimed'], isTrue);
      expect(res2['pointsEarned'], 0);
      expect(appState.points, 50, reason: 'Points balance must not increase on duplicate claim');
    });

    test('Non-sequential reading earns 0 base points, but Sunnah bonus is claimable in Achievements', () async {
      final appState = AppState(prefs);
      // User is at Surah 1 (Al-Fatihah), index 0
      // Surah 67 (Al-Mulk) is out of sequence
      expect(appState.canEarnPoints(66, 0), isFalse);

      final nightTime = DateTime(2026, 9, 12, 21, 0);
      final res = await appState.completeSunnahMission(
        missionId: 'almulk_malam',
        missionTitle: 'Surah Al-Mulk',
        pointsReward: 50,
        dateTime: nightTime,
      );

      expect(res['isNewMilestone'], isTrue);
      expect(res['pointsEarned'], 50);
      expect(appState.points, 0, reason: 'Must not add points directly before claiming');

      // Claiming adds points
      await appState.claimBadgeReward('sunnah_almulk', 50, 'Surah Al-Mulk');
      expect(appState.points, 50);
    });

    test('Sunnah badge claim status resets when a new period mission is completed', () async {
      final appState = AppState(prefs);
      final friday1 = DateTime(2026, 9, 11, 10, 0); // Friday 1
      await appState.completeSunnahMission(
        missionId: 'alkahf_jumat',
        missionTitle: 'Surah Al-Kahf',
        pointsReward: 75,
        dateTime: friday1,
      );

      // Claim for Friday 1
      await appState.claimBadgeReward('sunnah_alkahf', 75, 'Surah Al-Kahf');
      expect(appState.isBadgeClaimed('sunnah_alkahf'), isTrue);
      expect(appState.points, 75);

      // Next Friday comes
      final friday2 = DateTime(2026, 9, 18, 10, 0); // Friday 2
      final res2 = await appState.completeSunnahMission(
        missionId: 'alkahf_jumat',
        missionTitle: 'Surah Al-Kahf',
        pointsReward: 75,
        dateTime: friday2,
      );

      expect(res2['isNewMilestone'], isTrue);
      // Badge claim status must be reset so user can claim for Friday 2!
      expect(appState.isBadgeClaimed('sunnah_alkahf'), isFalse);

      // Claim for Friday 2
      await appState.claimBadgeReward('sunnah_alkahf', 75, 'Surah Al-Kahf');
      expect(appState.isBadgeClaimed('sunnah_alkahf'), isTrue);
      expect(appState.points, 150);
    });
  });

  group('Achievements Screen Sunnah Badges Tests', () {
    test('Achievements list contains the 5 Sunnah badges with correct category', () async {
      final appState = AppState(prefs);
      final allBadges = AchievementsScreen.getBadges(appState, 'id');

      final sunnahBadges = allBadges.where((b) => b.category == 'sunnah').toList();
      expect(sunnahBadges.length, 5);

      final ids = sunnahBadges.map((b) => b.id).toSet();
      expect(ids, containsAll([
        'sunnah_alkahf',
        'sunnah_almulk',
        'sunnah_ayat_kursi',
        'sunnah_albaqarah_akhir',
        'sunnah_fajar',
      ]));

      // Initially locked
      for (final b in sunnahBadges) {
        expect(b.isUnlocked, isFalse);
        expect(b.progress, 0.0);
      }

      // After completing Al-Kahf
      await appState.completeSunnahMission(
        missionId: 'alkahf_jumat',
        missionTitle: 'Surah Al-Kahf',
        pointsReward: 75,
      );

      final updatedBadges = AchievementsScreen.getBadges(appState, 'id');
      final kahfBadge = updatedBadges.firstWhere((b) => b.id == 'sunnah_alkahf');
      expect(kahfBadge.isUnlocked, isTrue);
      expect(kahfBadge.progress, 1.0);
    });
  });

  group('6-Language Full Localization Parity Tests', () {
    const supportedLanguages = ['id', 'en', 'ms', 'ar', 'af', 'sw'];
    const requiredKeys = [
      'sunnah_mission_header',
      'switch_to_regular',
      'switch_to_sunnah',
      'active_sunnah_badge',
      'view_hadith_and_start',
      'sunnah_event_badge',
      'virtue_and_hadith',
      'sunnah_outside_sequence_note',
      'sunnah_completed_today_claimed',
      'start_recitation_now',
      'sunnah_mission_completed_msg',
      'claim_now_action',
      'pts_bonus_label',
      'sunnah_filter',
      'badge_completed',
      'badge_not_yet',
      'juz_label',
    ];

    test('All 6 languages have required translation keys defined and non-empty', () {
      for (final lang in supportedLanguages) {
        for (final key in requiredKeys) {
          final translated = Translations.get(lang, key);
          expect(translated, isNotEmpty,
              reason: 'Key "$key" must not be empty in language "$lang"');
          expect(translated, isNot(equals(key)),
              reason: 'Key "$key" must be translated in language "$lang"');
        }
      }
    });

    test('All 5 Sunnah missions provide distinct localized strings across all 6 languages', () {
      for (final mission in SunnahMissionHelper.allMissions) {
        for (final lang in supportedLanguages) {
          final title = mission.getTitle(lang);
          final subtitle = mission.getSubtitle(lang);
          final timeBadge = mission.getTimeBadge(lang);
          final pillLabel = mission.getPillLabel(lang);
          final badgeTitle = mission.getBadgeTitle(lang);
          final badgeDesc = mission.getBadgeDesc(lang);
          final hadith = mission.getFadhilahHadith(lang);
          final ayahRange = mission.getAyahRangeText(lang);

          expect(title, isNotEmpty, reason: '${mission.id} title empty in $lang');
          expect(subtitle, isNotEmpty, reason: '${mission.id} subtitle empty in $lang');
          expect(timeBadge, isNotEmpty, reason: '${mission.id} timeBadge empty in $lang');
          expect(pillLabel, isNotEmpty, reason: '${mission.id} pillLabel empty in $lang');
          expect(badgeTitle, isNotEmpty, reason: '${mission.id} badgeTitle empty in $lang');
          expect(badgeDesc, isNotEmpty, reason: '${mission.id} badgeDesc empty in $lang');
          expect(hadith, isNotEmpty, reason: '${mission.id} hadith empty in $lang');
          expect(ayahRange, isNotEmpty, reason: '${mission.id} ayahRange empty in $lang');
        }
      }
    });

    test('Sunnah badges in AchievementsScreen adapt to each of the 6 languages', () {
      final appState = AppState(prefs);
      for (final lang in supportedLanguages) {
        final badges = AchievementsScreen.getBadges(appState, lang);
        final sunnahBadges = badges.where((b) => b.category == 'sunnah').toList();
        expect(sunnahBadges.length, 5);

        for (final b in sunnahBadges) {
          expect(b.title, isNotEmpty, reason: 'Badge ${b.id} title empty in $lang');
          expect(b.description, isNotEmpty, reason: 'Badge ${b.id} desc empty in $lang');
          expect(b.progressLabel, Translations.get(lang, 'badge_not_yet'));
        }
      }
    });
  });

  group('HomeScreen Sunnah Mission Card Badge Tests', () {
    testWidgets('SunnahMissionCard displays Sunnah Nabi badge and does not display Khatam Maqam badge', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SunnahMissionHelper.debugSimulatedTime = DateTime(2026, 9, 12, 21, 0);
      addTearDown(() {
        SunnahMissionHelper.debugSimulatedTime = null;
      });

      await prefs.setString('languageCode', 'id');
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

      // Header section outside card: SUNNAH NABI ﷺ
      expect(find.text('SUNNAH NABI ﷺ'), findsOneWidget);
      // Badge inside card displays the active event badge title (e.g. Pelindung Kubur (Surah Al-Mulk))
      expect(find.text(SunnahMissionHelper.nightMulk.getBadgeTitle('id')), findsOneWidget);
      expect(find.byIcon(Icons.stars_rounded), findsWidgets);
      // Khatam level badge (e.g. "Tingkat 1: Pemula") must NOT be rendered on Sunnah card
      expect(find.textContaining('Tingkat 1'), findsNothing);
    });

    testWidgets('Thursday night renders all 4 mission pills in a scrollable view without overflow', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Thursday 20:00 (Malam Jum'at)
      SunnahMissionHelper.debugSimulatedTime = DateTime(2026, 9, 10, 20, 0); // 2026-09-10 is Thursday
      addTearDown(() {
        SunnahMissionHelper.debugSimulatedTime = null;
      });

      await prefs.setString('languageCode', 'id');
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

      // Check all 4 pills are present
      expect(find.text('Al-Kahf'), findsWidgets);
      expect(find.text('Al-Mulk'), findsWidgets);
      expect(find.text('Ayat Kursi'), findsWidgets);
      expect(find.text('2 Ayat Baqarah'), findsWidgets);

      // Ensure SingleChildScrollView horizontal exists and is scrollable
      final scrollViewFinder = find.byWidgetPredicate(
        (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(scrollViewFinder, findsWidgets);

      // Verify no Flutter error / RenderFlex overflow occurred
      expect(tester.takeException(), isNull);
    });
  });

  group('Sunnah Installment Reading & Verse Markers Tests', () {
    test('Records read ayahs per session and retrieves accurate count and last read ayah', () async {
      final appState = AppState(prefs);
      final fridayTime = DateTime(2026, 9, 11, 10, 0);

      // Initially no ayahs read
      expect(appState.getSunnahReadAyahs('alkahf_jumat', fridayTime), isEmpty);
      expect(appState.getSunnahProgressCount('alkahf_jumat', fridayTime), 0);
      expect(appState.getSunnahLastReadAyah('alkahf_jumat', fridayTime), isNull);

      // Read ayahs 1, 2, 3 in installments
      await appState.recordSunnahAyahRead('alkahf_jumat', 1, fridayTime);
      await appState.recordSunnahAyahRead('alkahf_jumat', 2, fridayTime);
      await appState.recordSunnahAyahRead('alkahf_jumat', 3, fridayTime);

      expect(appState.getSunnahReadAyahs('alkahf_jumat', fridayTime), equals({1, 2, 3}));
      expect(appState.getSunnahProgressCount('alkahf_jumat', fridayTime), 3);
      expect(appState.getSunnahLastReadAyah('alkahf_jumat', fridayTime), 3);

      // Duplicate read of ayah 2 does not increment count
      await appState.recordSunnahAyahRead('alkahf_jumat', 2, fridayTime);
      expect(appState.getSunnahProgressCount('alkahf_jumat', fridayTime), 3);
      expect(appState.getSunnahLastReadAyah('alkahf_jumat', fridayTime), 2);
    });

    test('Session reset: Reading progress naturally resets across session boundaries', () async {
      final appState = AppState(prefs);

      // Saturday night: Read 10 ayahs of Al-Mulk
      final satNight = DateTime(2026, 9, 12, 21, 0);
      for (int i = 1; i <= 10; i++) {
        await appState.recordSunnahAyahRead('almulk_malam', i, satNight);
      }
      expect(appState.getSunnahProgressCount('almulk_malam', satNight), 10);
      expect(appState.getSunnahLastReadAyah('almulk_malam', satNight), 10);

      // Next Sunday night: Progress starts fresh at 0
      final sunNight = DateTime(2026, 9, 13, 21, 0);
      expect(appState.getSunnahProgressCount('almulk_malam', sunNight), 0);
      expect(appState.getSunnahLastReadAyah('almulk_malam', sunNight), isNull);
    });

    test('Thursday night and Friday morning share the same Al-Kahf session', () async {
      final appState = AppState(prefs);

      // Thursday night: Read ayahs 1 to 20
      final thursNight = DateTime(2026, 9, 10, 20, 0);
      for (int i = 1; i <= 20; i++) {
        await appState.recordSunnahAyahRead('alkahf_jumat', i, thursNight);
      }
      expect(appState.getSunnahProgressCount('alkahf_jumat', thursNight), 20);

      // Friday noon: Seamlessly resumes with ayahs 1 to 20 already marked
      final friNoon = DateTime(2026, 9, 11, 12, 0);
      expect(appState.getSunnahProgressCount('alkahf_jumat', friNoon), 20);
      expect(appState.getSunnahLastReadAyah('alkahf_jumat', friNoon), 20);
      expect(appState.getSunnahReadAyahs('alkahf_jumat', friNoon).contains(20), isTrue);
      expect(appState.getSunnahReadAyahs('alkahf_jumat', friNoon).contains(21), isFalse);
    });

    test('getActiveMissionForAyah correctly identifies matching active missions', () {
      final friNoon = DateTime(2026, 9, 11, 12, 0);
      final monNoon = DateTime(2026, 9, 14, 12, 0);
      final satNight = DateTime(2026, 9, 12, 21, 0);

      // Surah 18, Ayah 1..110 on Friday -> Al-Kahf
      expect(SunnahMissionHelper.getActiveMissionForAyah(18, 1, friNoon)?.id, 'alkahf_jumat');
      expect(SunnahMissionHelper.getActiveMissionForAyah(18, 110, friNoon)?.id, 'alkahf_jumat');
      // Surah 18 on Monday -> null (inactive)
      expect(SunnahMissionHelper.getActiveMissionForAyah(18, 1, monNoon), isNull);

      // Surah 67, Ayah 1..30 at Night -> Al-Mulk
      expect(SunnahMissionHelper.getActiveMissionForAyah(67, 15, satNight)?.id, 'almulk_malam');
      // Surah 67 at Noon -> null
      expect(SunnahMissionHelper.getActiveMissionForAyah(67, 15, friNoon), isNull);

      // Surah 2, Ayah 255 at Night -> Ayat Kursi
      expect(SunnahMissionHelper.getActiveMissionForAyah(2, 255, satNight)?.id, 'ayat_kursi_malam');
      // Surah 2, Ayahs 285 & 286 at Night -> Baqarah End
      expect(SunnahMissionHelper.getActiveMissionForAyah(2, 285, satNight)?.id, 'albaqarah_akhir_malam');
      expect(SunnahMissionHelper.getActiveMissionForAyah(2, 286, satNight)?.id, 'albaqarah_akhir_malam');
    });

    test('6-Language parity for new installment reading keys', () {
      final languages = ['id', 'en', 'ms', 'ar', 'af', 'sw'];
      final keys = [
        'sunnah_ayah_read',
        'sunnah_last_read',
        'continue_reading_ayah',
        'progress_ayah_count',
      ];

      for (final lang in languages) {
        for (final key in keys) {
          final val = Translations.get(lang, key);
          expect(val, isNotEmpty, reason: 'Key $key must exist and not be empty in $lang');
          expect(val, isNot(equals(key)), reason: 'Key $key must have a valid translation in $lang');
        }
      }
    });

    testWidgets('Home card renders installment progress when reading is in progress', (tester) async {
      final nightTime = DateTime(2026, 9, 12, 21, 0);
      SunnahMissionHelper.debugSimulatedTime = nightTime;
      addTearDown(() {
        SunnahMissionHelper.debugSimulatedTime = null;
      });

      await prefs.setString('languageCode', 'id');
      final appState = AppState(prefs);
      appState.setIgnorePermissionGuard(true);
      appState.setReadyForTesting();

      // Simulate user having read 15 of 30 ayahs of Al-Mulk
      for (int i = 1; i <= 15; i++) {
        await appState.recordSunnahAyahRead('almulk_malam', i, nightTime);
      }

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

      // Verify installment progress is displayed: "15 dari 30 Ayat" and "50%"
      expect(find.text('15 dari 30 Ayat'), findsWidgets);
      expect(find.text('50%'), findsWidgets);
    });
  });
}

