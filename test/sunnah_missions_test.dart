import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/utils/sunnah_mission_helper.dart';
import 'package:muslim_launcher_2/screens/home/achievements_screen.dart';
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

    test('Night window detection (19:00 to 04:30)', () {
      // 18:59 -> inactive
      final beforeNight = DateTime(2026, 9, 12, 18, 59);
      expect(SunnahMissionHelper.isNightActive(beforeNight), isFalse);

      // 19:00 -> active
      final nightStart = DateTime(2026, 9, 12, 19, 0);
      expect(SunnahMissionHelper.isNightActive(nightStart), isTrue);

      // 23:30 -> active
      final lateNight = DateTime(2026, 9, 12, 23, 30);
      expect(SunnahMissionHelper.isNightActive(lateNight), isTrue);

      // 02:00 next morning -> active
      final pastMidnight = DateTime(2026, 9, 13, 2, 0);
      expect(SunnahMissionHelper.isNightActive(pastMidnight), isTrue);

      // 04:30 -> active
      final dawnEdge = DateTime(2026, 9, 13, 4, 30);
      expect(SunnahMissionHelper.isNightActive(dawnEdge), isTrue);

      // 04:31 -> inactive
      final afterDawn = DateTime(2026, 9, 13, 4, 31);
      expect(SunnahMissionHelper.isNightActive(afterDawn), isFalse);
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

    test('Anti-gaming claim key continuity across midnight for night missions', () {
      // 23:00 on Saturday night
      final satNight = DateTime(2026, 9, 12, 23, 0);
      final key1 = SunnahMissionHelper.getAntiGamingClaimKey('almulk_malam', satNight);

      // 02:30 on Sunday morning (same continuous night session)
      final sunMorning = DateTime(2026, 9, 13, 2, 30);
      final key2 = SunnahMissionHelper.getAntiGamingClaimKey('almulk_malam', sunMorning);

      expect(key1, equals(key2),
          reason: 'Both timestamps must map to the same night claim session');

      // Next Sunday evening (19:30) -> should be a new claim key
      final nextNight = DateTime(2026, 9, 13, 19, 30);
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

      // First completion -> success +50 pts
      final res1 = await appState.completeSunnahMission(
        missionId: 'almulk_malam',
        missionTitle: 'Surah Al-Mulk',
        pointsReward: 50,
        dateTime: nightTime,
      );

      expect(res1['isNewMilestone'], isTrue);
      expect(res1['alreadyClaimed'], isFalse);
      expect(res1['pointsEarned'], 50);
      expect(appState.points, 50);
      expect(appState.isSunnahMissionCompletedToday('almulk_malam', nightTime), isTrue);
      expect(appState.isSunnahMissionCompletedLifetime('almulk_malam'), isTrue);

      // Attempt second completion at 01:30 (past midnight same night) -> rejected, 0 pts
      final lateNightTime = DateTime(2026, 9, 13, 1, 30);
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

    test('Non-sequential reading earns 0 base points, but Sunnah bonus is awarded', () async {
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
      expect(appState.points, 50);
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

          expect(title, isNotEmpty, reason: '${mission.id} title empty in $lang');
          expect(subtitle, isNotEmpty, reason: '${mission.id} subtitle empty in $lang');
          expect(timeBadge, isNotEmpty, reason: '${mission.id} timeBadge empty in $lang');
          expect(pillLabel, isNotEmpty, reason: '${mission.id} pillLabel empty in $lang');
          expect(badgeTitle, isNotEmpty, reason: '${mission.id} badgeTitle empty in $lang');
          expect(badgeDesc, isNotEmpty, reason: '${mission.id} badgeDesc empty in $lang');
          expect(hadith, isNotEmpty, reason: '${mission.id} hadith empty in $lang');
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
}
