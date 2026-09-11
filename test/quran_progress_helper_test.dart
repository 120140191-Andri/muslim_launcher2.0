import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_launcher_2/utils/quran_progress_helper.dart';

void main() {
  group('QuranProgressHelper Juz and Phase Tests', () {
    test('Calculates Juz numbers accurately across boundaries', () {
      // Juz 1: Al-Fatihah 1..Al-Baqarah 141
      expect(QuranProgressHelper.getJuzNumber(1, 1), 1);
      expect(QuranProgressHelper.getJuzNumber(1, 7), 1);
      expect(QuranProgressHelper.getJuzNumber(2, 1), 1);
      expect(QuranProgressHelper.getJuzNumber(2, 141), 1);

      // Juz 2: Al-Baqarah 142..252
      expect(QuranProgressHelper.getJuzNumber(2, 142), 2);
      expect(QuranProgressHelper.getJuzNumber(2, 252), 2);

      // Juz 3: Al-Baqarah 253..Ali 'Imran 92
      expect(QuranProgressHelper.getJuzNumber(2, 253), 3);
      expect(QuranProgressHelper.getJuzNumber(3, 92), 3);

      // Juz 4: Ali 'Imran 93
      expect(QuranProgressHelper.getJuzNumber(3, 93), 4);

      // Juz 15: Al-Isra' 1..Al-Kahf 74
      expect(QuranProgressHelper.getJuzNumber(17, 1), 15);
      expect(QuranProgressHelper.getJuzNumber(18, 1), 15);
      expect(QuranProgressHelper.getJuzNumber(18, 74), 15);

      // Juz 16: Al-Kahf 75
      expect(QuranProgressHelper.getJuzNumber(18, 75), 16);

      // Juz 28: Al-Mujadilah 1
      expect(QuranProgressHelper.getJuzNumber(58, 1), 28);

      // Juz 30: An-Naba' 1..An-Nas 6
      expect(QuranProgressHelper.getJuzNumber(78, 1), 30);
      expect(QuranProgressHelper.getJuzNumber(114, 6), 30);
    });

    test('Maps Juz numbers to 3-Phase Khatam Journey correctly', () {
      // Phase 1: Juz 1–6 (The Grand Climb)
      for (int juz = 1; juz <= 6; juz++) {
        expect(QuranProgressHelper.getPhase(juz), KhatamPhase.grandClimb);
      }

      // Phase 2: Juz 7–27 (The Rhythmic Cadence)
      for (int juz = 7; juz <= 27; juz++) {
        expect(QuranProgressHelper.getPhase(juz), KhatamPhase.rhythmicCadence);
      }

      // Phase 3: Juz 28–30 (The Sprint to the Summit)
      for (int juz = 28; juz <= 30; juz++) {
        expect(QuranProgressHelper.getPhase(juz), KhatamPhase.sprintSummit);
      }
    });

    test('Provides localized phase titles and subtitles', () {
      expect(
        QuranProgressHelper.getPhaseTitle(KhatamPhase.grandClimb, 'id'),
        'Tahap 1: Awal Perjalanan (Juz 1–6)',
      );
      expect(
        QuranProgressHelper.getPhaseTitle(KhatamPhase.grandClimb, 'en'),
        'Stage 1: The Journey Begins (Juz 1–6)',
      );

      expect(
        QuranProgressHelper.getPhaseTitle(KhatamPhase.rhythmicCadence, 'id'),
        'Tahap 2: Ritme Istiqomah (Juz 7–27)',
      );
      expect(
        QuranProgressHelper.getPhaseTitle(KhatamPhase.sprintSummit, 'id'),
        'Tahap 3: Menjelang Khatam (Juz 28–30)',
      );

      expect(
        QuranProgressHelper.getPhaseSubtitle(KhatamPhase.grandClimb, 'id')
            .isNotEmpty,
        true,
      );
    });

    test('Returns appropriate spiritual rank (Maqam) based on Khatm count', () {
      expect(QuranProgressHelper.getMaqamTitle(0, 'id'), 'Pejuang Istiqomah');
      expect(
        QuranProgressHelper.getMaqamTitle(1, 'id'),
        'Al-Mubtadi\' Al-Karim',
      );
      expect(QuranProgressHelper.getMaqamTitle(2, 'id'), 'Sahabat Al-Qur\'an');
      expect(QuranProgressHelper.getMaqamTitle(3, 'id'), 'Penjaga Cahaya');
      expect(QuranProgressHelper.getMaqamTitle(4, 'id'), 'Penjaga Cahaya');
      expect(
        QuranProgressHelper.getMaqamTitle(5, 'id'),
        'Ahlul Qur\'an Al-Mubarok',
      );
    });

    test('Calculates overall progress cleanly', () {
      final mockData = [
        {'total_ayah': 7},
        {'total_ayah': 286},
        {'total_ayah': 200},
      ];

      // Surah 1 (index 0), ayah 0 -> 0.0
      expect(QuranProgressHelper.getOverallProgress(0, 0, mockData), 0.0);

      // Surah 1 (index 0), ayah 7 -> 7 / 6236 ~ 0.0011
      final p1 = QuranProgressHelper.getOverallProgress(0, 7, mockData);
      expect(p1 > 0.0 && p1 < 0.01, true);

      // Surah 2 (index 1), ayah 142 -> (7 + 142) / 6236 ~ 0.0238
      final p2 = QuranProgressHelper.getOverallProgress(1, 142, mockData);
      expect((p2 * 100).toStringAsFixed(1), '2.4');
    });

    testWidgets('showKhatamLevelInfoModal renders 5 tiers and current rank',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => QuranProgressHelper.showKhatamLevelInfoModal(
                  context,
                  'id',
                  0,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Tingkatan Khatam & Maqam'), findsOneWidget);
      expect(find.text('Pejuang Istiqomah'), findsWidgets);
      expect(find.text('Al-Mubtadi\' Al-Karim'), findsOneWidget);
      expect(find.text('Saya Mengerti'), findsOneWidget);

      await tester.ensureVisible(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saya Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Tingkatan Khatam & Maqam'), findsNothing);
    });

  });
}

