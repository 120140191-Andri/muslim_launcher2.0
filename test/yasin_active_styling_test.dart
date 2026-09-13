import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/quran/surah_list_screen.dart';
import 'package:muslim_launcher_2/screens/quran/surah_detail_screen.dart';
import 'package:muslim_launcher_2/utils/sunnah_mission_helper.dart';

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

  group('Surah Ya-Sin (Surah 36) Always Active Styling Tests', () {
    testWidgets('SurahListScreen renders Ya-Sin with 1.0 opacity and without lock icon when future', (tester) async {
      final appState = AppState(prefs);
      // User is at Surah 1 (highestSurahIndex = 0), so Surah 36 (index 35) is future
      final mockSurahs = List.generate(40, (i) => {
        'surah_number': i + 1,
        'surah_name': i == 35 ? 'Ya-Sin' : 'Surah ${i + 1}',
        'total_ayah': 10,
        'ayahs': List.generate(10, (a) => {
          'ayah_number': a + 1,
          'arabic': 'بِسْمِ اللَّهِ',
          'latin': 'Bismillah',
          'translation_id': 'Dengan nama Allah',
          'translation_en': 'In the name of Allah',
        }),
      });

      appState.quranData.clear();
      appState.quranData.addAll(mockSurahs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: SurahListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to find Ya-Sin if needed
      final yasinFinder = find.text('Ya-Sin');
      await tester.scrollUntilVisible(
        yasinFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(yasinFinder, findsOneWidget);

      // Verify Ya-Sin tile has 1.0 Opacity (not dimmed to 0.5)
      final yasinTile = find.ancestor(
        of: yasinFinder,
        matching: find.byType(Opacity),
      );
      expect(yasinTile, findsOneWidget);
      final yasinOpacity = tester.widget<Opacity>(yasinTile);
      expect(yasinOpacity.opacity, 1.0, reason: 'Ya-Sin must always have 1.0 opacity even when future');

      // Verify Ya-Sin does NOT have a lock icon
      final yasinRow = find.ancestor(
        of: yasinFinder,
        matching: find.byType(Row),
      ).first;
      final lockIconInYasin = find.descendant(
        of: yasinRow,
        matching: find.byIcon(Icons.lock_outline_rounded),
      );
      expect(lockIconInYasin, findsNothing, reason: 'Ya-Sin must not have a lock icon');

      // Verify an arrow forward icon is present instead
      final arrowIconInYasin = find.descendant(
        of: yasinRow,
        matching: find.byIcon(Icons.arrow_forward_ios_rounded),
      );
      expect(arrowIconInYasin, findsOneWidget);
    });

    testWidgets('SurahDetailScreen renders Ya-Sin ayahs with 1.0 opacity when future', (tester) async {
      final appState = AppState(prefs);
      // User is at Surah 1, so Surah 36 ayahs are not yet reached in sequence
      final yasinSurah = {
        'surah_number': 36,
        'surah_name': 'Ya-Sin',
        'total_ayah': 3,
        'ayahs': [
          {
            'ayah_number': 1,
            'arabic': 'يس',
            'latin': 'Ya-Sin',
            'translation_id': 'Ya Sin',
            'translation_en': 'Ya Sin',
          },
          {
            'ayah_number': 2,
            'arabic': 'وَالْقُرْآنِ الْحَكِيمِ',
            'latin': 'Wal-qur-anil-hakim',
            'translation_id': 'Demi Al-Qur\'an yang penuh hikmah',
            'translation_en': 'By the wise Quran',
          },
          {
            'ayah_number': 3,
            'arabic': 'إِنَّكَ لَمِنَ الْمُرْسَلِينَ',
            'latin': 'Innaka laminal-mursalin',
            'translation_id': 'Sungguh, engkau salah seorang rasul',
            'translation_en': 'Indeed you are of the messengers',
          },
        ],
      };

      appState.quranData.clear();
      appState.quranData.addAll([yasinSurah]);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: SurahDetailScreen(surah: yasinSurah),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the second ayah by latin text 'Wal-qur-anil-hakim'
      final ayah2 = find.text('Wal-qur-anil-hakim');
      expect(ayah2, findsOneWidget);

      // Verify the ayah container's Opacity is 1.0 (not dimmed to 0.6)
      final ayah2OpacityAncestor = find.ancestor(
        of: ayah2,
        matching: find.byType(Opacity),
      ).first;
      final ayah2Opacity = tester.widget<Opacity>(ayah2OpacityAncestor);
      expect(ayah2Opacity.opacity, 1.0, reason: 'Ayahs in Ya-Sin must always be 1.0 opacity (alive)');
    });
  });

  group('Sunnah Mission Active Schedule Styling Tests', () {
    tearDown(() {
      SunnahMissionHelper.debugSimulatedTime = null;
    });

    test('isSurahAlwaysActive logic for Friday Kahf, Night Mulk & Baqarah, and Ya-Sin', () {
      final wednesdayNoon = DateTime(2026, 9, 16, 12, 0); // Wednesday 12:00
      final fridayMorning = DateTime(2026, 9, 18, 9, 0);  // Friday 09:00
      final nightTime = DateTime(2026, 9, 16, 21, 0);      // Wednesday 21:00

      // Ya-Sin (36) is always active regardless of time
      expect(SunnahMissionHelper.isSurahAlwaysActive(36, wednesdayNoon), isTrue);
      expect(SunnahMissionHelper.isSurahAlwaysActive(36, fridayMorning), isTrue);
      expect(SunnahMissionHelper.isSurahAlwaysActive(36, nightTime), isTrue);

      // Al-Kahf (18) active only during Friday window
      expect(SunnahMissionHelper.isSurahAlwaysActive(18, wednesdayNoon), isFalse);
      expect(SunnahMissionHelper.isSurahAlwaysActive(18, fridayMorning), isTrue);

      // Al-Mulk (67) active only during Night window
      expect(SunnahMissionHelper.isSurahAlwaysActive(67, wednesdayNoon), isFalse);
      expect(SunnahMissionHelper.isSurahAlwaysActive(67, nightTime), isTrue);

      // Al-Baqarah (2) active during Night window
      expect(SunnahMissionHelper.isSurahAlwaysActive(2, wednesdayNoon), isFalse);
      expect(SunnahMissionHelper.isSurahAlwaysActive(2, nightTime), isTrue);

      // Other surahs (e.g. 3, 4, 114) never bypass progression
      expect(SunnahMissionHelper.isSurahAlwaysActive(3, fridayMorning), isFalse);
      expect(SunnahMissionHelper.isSurahAlwaysActive(3, nightTime), isFalse);
    });

    test('isAyahAlwaysActive logic for specific ayahs', () {
      final wednesdayNoon = DateTime(2026, 9, 16, 12, 0);
      final fridayMorning = DateTime(2026, 9, 18, 9, 0);
      final nightTime = DateTime(2026, 9, 16, 21, 0);

      // Ya-Sin (36): any ayah is active
      expect(SunnahMissionHelper.isAyahAlwaysActive(36, 0, wednesdayNoon), isTrue);
      expect(SunnahMissionHelper.isAyahAlwaysActive(36, 50, wednesdayNoon), isTrue);

      // Al-Kahf (18): all ayahs active on Friday, not on Wednesday
      expect(SunnahMissionHelper.isAyahAlwaysActive(18, 0, fridayMorning), isTrue);
      expect(SunnahMissionHelper.isAyahAlwaysActive(18, 0, wednesdayNoon), isFalse);

      // Al-Mulk (67): all ayahs active at night, not at noon
      expect(SunnahMissionHelper.isAyahAlwaysActive(67, 0, nightTime), isTrue);
      expect(SunnahMissionHelper.isAyahAlwaysActive(67, 0, wednesdayNoon), isFalse);

      // Al-Baqarah (2):
      // Ayat Kursi is ayah 255 (index 254)
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 254, nightTime), isTrue);
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 254, wednesdayNoon), isFalse);

      // Last 2 ayahs are 285 (index 284) and 286 (index 285)
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 284, nightTime), isTrue);
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 285, nightTime), isTrue);
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 284, wednesdayNoon), isFalse);

      // Other ayahs in Al-Baqarah (e.g. ayah 1, index 0, or ayah 10, index 9) are NOT active
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 0, nightTime), isFalse);
      expect(SunnahMissionHelper.isAyahAlwaysActive(2, 9, nightTime), isFalse);
    });

    testWidgets('SurahDetailScreen renders Ayat Kursi (2:255) with 1.0 opacity during night window', (tester) async {
      // Simulate night time
      SunnahMissionHelper.debugSimulatedTime = DateTime(2026, 9, 16, 21, 0);

      final appState = AppState(prefs);
      final baqarahSurah = {
        'surah_number': 2,
        'surah_name': 'Al-Baqarah',
        'total_ayah': 286,
        'ayahs': [
          {
            'ayah_number': 1,
            'arabic': 'الم',
            'latin': 'Alif-Lam-Mim',
            'translation_id': 'Alif Lam Mim',
            'translation_en': 'Alif Lam Meem',
          },
          {
            'ayah_number': 255,
            'arabic': 'اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
            'latin': 'Allahu la ilaha illa huwal-hayyul-qayyum',
            'translation_id': 'Allah, tidak ada tuhan selain Dia...',
            'translation_en': 'Allah! There is no deity except Him...',
          },
        ],
      };

      appState.quranData.clear();
      appState.quranData.addAll([baqarahSurah]);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: SurahDetailScreen(surah: baqarahSurah),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In SurahDetailScreen, index 0 is Ayah 1 (not active, future) -> opacity 0.6
      final ayah1 = find.text('Alif-Lam-Mim');
      expect(ayah1, findsOneWidget);
      final ayah1OpacityAncestor = find.ancestor(
        of: ayah1,
        matching: find.byType(Opacity),
      ).first;
      final ayah1Opacity = tester.widget<Opacity>(ayah1OpacityAncestor);
      expect(ayah1Opacity.opacity, 0.6, reason: 'Ayah 1 of Al-Baqarah should remain dimmed when future');

      // Index 1 corresponds to ayah_number 255 in our mock data
      final ayah255 = find.text('Allahu la ilaha illa huwal-hayyul-qayyum');
      expect(ayah255, findsOneWidget);
      final ayah255OpacityAncestor = find.ancestor(
        of: ayah255,
        matching: find.byType(Opacity),
      ).first;
      final ayah255Opacity = tester.widget<Opacity>(ayah255OpacityAncestor);
      expect(ayah255Opacity.opacity, 1.0, reason: 'Ayat Kursi (255) must have 1.0 opacity during night window');
    });
  });
}

