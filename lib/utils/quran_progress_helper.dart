import 'package:flutter/material.dart';

enum KhatamPhase {
  grandClimb, // Juz 1–6: Tahap 1: Awal Perjalanan (Surah panjang Al-Baqarah s/d Al-An'am)
  rhythmicCadence, // Juz 7–27: Tahap 2: Ritme Istiqomah (Al-A'raf s/d Al-Hadid)
  sprintSummit, // Juz 28–30: Tahap 3: Menjelang Khatam (Puncak Juz 'Amma)
}

class QuranProgressHelper {
  /// Total ayahs in the Holy Quran
  static const int totalQuranAyahs = 6236;

  /// Standard 30 Juz start points in Uthmani Mushaf:
  /// [surahNumber (1-114), ayahNumber (1-based)]
  static const List<List<int>> juzStarts = [
    [1, 1], // Juz 1: Al-Fatihah 1
    [2, 142], // Juz 2: Al-Baqarah 142
    [2, 253], // Juz 3: Al-Baqarah 253
    [3, 93], // Juz 4: Ali 'Imran 93
    [4, 24], // Juz 5: An-Nisa' 24
    [4, 148], // Juz 6: An-Nisa' 148
    [5, 82], // Juz 7: Al-Ma'idah 82
    [6, 111], // Juz 8: Al-An'am 111
    [7, 88], // Juz 9: Al-A'raf 88
    [8, 41], // Juz 10: Al-Anfal 41
    [9, 93], // Juz 11: At-Tawbah 93
    [11, 6], // Juz 12: Hud 6
    [12, 53], // Juz 13: Yusuf 53
    [15, 1], // Juz 14: Al-Hijr 1
    [17, 1], // Juz 15: Al-Isra' 1
    [18, 75], // Juz 16: Al-Kahf 75
    [21, 1], // Juz 17: Al-Anbiya' 1
    [23, 1], // Juz 18: Al-Mu'minun 1
    [25, 21], // Juz 19: Al-Furqan 21
    [27, 56], // Juz 20: An-Naml 56
    [29, 46], // Juz 21: Al-'Ankabut 46
    [33, 31], // Juz 22: Al-Ahzab 31
    [36, 28], // Juz 23: Ya-Sin 28
    [39, 32], // Juz 24: Az-Zumar 32
    [41, 47], // Juz 25: Fussilat 47
    [46, 1], // Juz 26: Al-Ahqaf 1
    [51, 31], // Juz 27: Adh-Dhariyat 31
    [58, 1], // Juz 28: Al-Mujadilah 1
    [67, 1], // Juz 29: Al-Mulk 1
    [78, 1], // Juz 30: An-Naba' 1
  ];

  /// Determines the Juz number (1–30) from 1-based [surahNumber] and [ayahNumber].
  static int getJuzNumber(int surahNumber, int ayahNumber) {
    if (surahNumber <= 0) return 1;
    final safeAyah = ayahNumber <= 0 ? 1 : ayahNumber;

    for (int i = juzStarts.length - 1; i >= 0; i--) {
      final startSurah = juzStarts[i][0];
      final startAyah = juzStarts[i][1];

      if (surahNumber > startSurah ||
          (surahNumber == startSurah && safeAyah >= startAyah)) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Determines the Khatam journey phase from the [juzNumber].
  static KhatamPhase getPhase(int juzNumber) {
    if (juzNumber <= 6) {
      return KhatamPhase.grandClimb;
    } else if (juzNumber <= 27) {
      return KhatamPhase.rhythmicCadence;
    } else {
      return KhatamPhase.sprintSummit;
    }
  }

  /// Localized title for the Khatam journey phase (Descriptive & Self-Explanatory).
  static String getPhaseTitle(KhatamPhase phase, String lang) {
    switch (phase) {
      case KhatamPhase.grandClimb:
        switch (lang) {
          case 'id':
            return 'Tahap 1: Awal Perjalanan (Juz 1–6)';
          case 'ms':
            return 'Tahap 1: Awal Perjalanan (Juzuk 1–6)';
          case 'ar':
            return 'المرحلة ١: بداية المسيرة (الجزء ١–٦)';
          case 'af':
            return 'Fase 1: Die Reis Begin (Juz 1–6)';
          case 'sw':
            return 'Awamu ya 1: Mwanzo wa Safari (Juzuu 1–6)';
          case 'en':
          default:
            return 'Stage 1: The Journey Begins (Juz 1–6)';
        }
      case KhatamPhase.rhythmicCadence:
        switch (lang) {
          case 'id':
            return 'Tahap 2: Ritme Istiqomah (Juz 7–27)';
          case 'ms':
            return 'Tahap 2: Ritma Istiqomah (Juzuk 7–27)';
          case 'ar':
            return 'المرحلة ٢: الإيقاع الثابت (الجزء ٧–٢٧)';
          case 'af':
            return 'Fase 2: Ritmiese Kadens (Juz 7–27)';
          case 'sw':
            return 'Awamu ya 2: Mdundo Imara (Juzuu 7–27)';
          case 'en':
          default:
            return 'Stage 2: Rhythmic Cadence (Juz 7–27)';
        }
      case KhatamPhase.sprintSummit:
        switch (lang) {
          case 'id':
            return 'Tahap 3: Menjelang Khatam (Juz 28–30)';
          case 'ms':
            return 'Tahap 3: Menjelang Khatam (Juzuk 28–30)';
          case 'ar':
            return 'المرحلة ٣: مشارف الختم (الجزء ٢٨–٣٠)';
          case 'af':
            return 'Fase 3: Naby aan Khatam (Juz 28–30)';
          case 'sw':
            return 'Awamu ya 3: Kuelekea Khatma (Juzuu 28–30)';
          case 'en':
          default:
            return 'Stage 3: Approaching Khatam (Juz 28–30)';
        }
    }
  }

  /// Localized inspiring subtitle / encouragement for the phase.
  static String getPhaseSubtitle(KhatamPhase phase, String lang) {
    switch (phase) {
      case KhatamPhase.grandClimb:
        switch (lang) {
          case 'id':
            return 'Tetap istiqomah membaca surah-surah panjang';
          case 'ms':
            return 'Tetap istiqomah membaca surah-surah panjang';
          case 'ar':
            return 'اثبت على تلاوة السور الطوال المباركة';
          case 'af':
            return 'Bly standvastig deur die lang soeras';
          case 'sw':
            return 'Baki thabiti ukisoma sura ndefu';
          case 'en':
          default:
            return 'Stay steadfast through the foundational grand surahs';
        }
      case KhatamPhase.rhythmicCadence:
        switch (lang) {
          case 'id':
            return 'Ritme tilawah semakin tenang dan mengalir';
          case 'ms':
            return 'Ritma tilawah semakin tenang dan mengalir';
          case 'ar':
            return 'إيقاع التلاوة ينساب بطمأنينة وخشوع';
          case 'af':
            return 'Resitasieritme vloei rustig en vreedsaam';
          case 'sw':
            return 'Mdundo wa usomaji unatiririka kwa utulivu';
          case 'en':
          default:
            return 'Recitation rhythm flowing peacefully';
        }
      case KhatamPhase.sprintSummit:
        switch (lang) {
          case 'id':
            return 'Puncak Juz \'Amma, sedikit lagi menuju khatam!';
          case 'ms':
            return 'Puncak Juzuk \'Amma, sedikit lagi menuju khatam!';
          case 'ar':
            return 'قصار السور في جزء عم، خط النهاية والختم قريب!';
          case 'af':
            return 'Kort soeras van Juz \'Amma, baie naby aan Khatam!';
          case 'sw':
            return 'Sura fupi za Juzuu \'Amma, karibu sana kukhatimu!';
          case 'en':
          default:
            return 'Summit of Juz \'Amma, Khatam is within reach!';
        }
    }
  }

  /// Localized inspiring encouragement quote displayed below the progress bar (Compact).
  static String getPhaseEncouragement(KhatamPhase phase, String lang) {
    switch (phase) {
      case KhatamPhase.grandClimb:
        switch (lang) {
          case 'id':
            return 'Kuatkan niat, teguhkan istiqomah.';
          case 'ms':
            return 'Kuatkan niat, teguhkan istiqomah.';
          case 'ar':
            return 'اثبت على البداية وواصل المسير.';
          case 'af':
            return 'Bly standvastig by elke stap.';
          case 'sw':
            return 'Baki thabiti katika kila hatua.';
          case 'en':
          default:
            return 'Stay steadfast in every step.';
        }
      case KhatamPhase.rhythmicCadence:
        switch (lang) {
          case 'id':
            return 'Jaga ritmemu, tenangkan jiwamu.';
          case 'ms':
            return 'Jaga rentakmu, tenangkan jiwamu.';
          case 'ar':
            return 'حافظ على وردك واطمئن به.';
          case 'af':
            return 'Hou die ritme en vind vrede.';
          case 'sw':
            return 'Dumisha mdundo, pata amani.';
          case 'en':
          default:
            return 'Keep the flow, find daily peace.';
        }
      case KhatamPhase.sprintSummit:
        switch (lang) {
          case 'id':
            return 'Sedikit lagi, tuntaskan khatammu!';
          case 'ms':
            return 'Sedikit lagi, sempurnakan khatam!';
          case 'ar':
            return 'أوشكت على الختم، هنيئاً لك!';
          case 'af':
            return 'Byna daar, bereik jou Khatam!';
          case 'sw':
            return 'Umekaribia, kamilisha Khatma!';
          case 'en':
          default:
            return 'Almost there, reach your Khatam!';
        }
    }
  }

  /// Spiritual rank / Maqam title based on Khatm frequency (Section 10.3)
  static String getMaqamTitle(int khatmCount, String lang) {
    if (khatmCount <= 0) {
      switch (lang) {
        case 'id':
        case 'ms':
          return 'Pejuang Istiqomah';
        case 'ar':
          return 'مجاهد الاستقامة';
        case 'af':
          return 'Standvastige Soeker';
        case 'sw':
          return 'Mpiganaji Imara';
        case 'en':
        default:
          return 'Steadfast Seeker';
      }
    } else if (khatmCount == 1) {
      return 'Al-Mubtadi\' Al-Karim';
    } else if (khatmCount == 2) {
      switch (lang) {
        case 'id':
        case 'ms':
          return 'Shahibul Qur\'an';
        case 'ar':
          return 'صاحب القرآن';
        case 'af':
          return 'Vriend van die Koran';
        case 'sw':
          return 'Sahibu wa Quran';
        case 'en':
        default:
          return 'Companion of the Quran';
      }
    } else if (khatmCount < 5) {
      switch (lang) {
        case 'id':
        case 'ms':
          return 'Haafizhun Nuur';
        case 'ar':
          return 'حافظ النور';
        case 'af':
          return 'Bewaarder van Lig';
        case 'sw':
          return 'Mlinzi wa Nuru';
        case 'en':
        default:
          return 'Guardian of Light';
      }
    } else {
      return 'Ahlul Qur\'an Al-Mubarok';
    }
  }

  /// Returns the numeric level (1 to 5) corresponding to the khatm count.
  static int getMaqamLevel(int khatmCount) {
    if (khatmCount <= 0) return 1;
    if (khatmCount == 1) return 2;
    if (khatmCount == 2) return 3;
    if (khatmCount < 5) return 4;
    return 5;
  }

  /// Calculates cumulative Quran reading progress ratio (0.0 to 1.0)
  /// based on 0-based [currentSurahIndex] and 1-based [currentAyahNumber].
  static double getOverallProgress(
    int currentSurahIndex,
    int currentAyahNumber,
    List<dynamic> quranData,
  ) {
    if (currentSurahIndex < 0 || quranData.isEmpty) return 0.0;

    int cumulativeAyahs = 0;
    final int maxSurah = currentSurahIndex < 0
        ? 0
        : (currentSurahIndex >= quranData.length
            ? quranData.length - 1
            : currentSurahIndex);

    for (int i = 0; i < maxSurah; i++) {
      final surah = quranData[i];
      if (surah is Map && surah.containsKey('total_ayah')) {
        cumulativeAyahs += (surah['total_ayah'] as int? ?? 0);
      } else if (surah is Map && surah['ayahs'] is List) {
        cumulativeAyahs += (surah['ayahs'] as List).length;
      }
    }

    final int safeAyah = currentAyahNumber < 0
        ? 0
        : (currentAyahNumber > 300 ? 300 : currentAyahNumber);
    cumulativeAyahs += safeAyah;
    return (cumulativeAyahs / totalQuranAyahs).clamp(0.0, 1.0).toDouble();
  }

  /// Calculates cumulative ayahs in the current reading cycle
  static int getCumulativeAyahs(
    int currentSurahIndex,
    int currentAyahNumber,
    List<dynamic> quranData,
  ) {
    if (currentSurahIndex < 0 || quranData.isEmpty) return 0;
    int cumulative = 0;
    final int maxSurah = currentSurahIndex < 0
        ? 0
        : (currentSurahIndex >= quranData.length
            ? quranData.length - 1
            : currentSurahIndex);

    for (int i = 0; i < maxSurah; i++) {
      final surah = quranData[i];
      if (surah is Map && surah.containsKey('total_ayah')) {
        cumulative += (surah['total_ayah'] as int? ?? 0);
      } else if (surah is Map && surah['ayahs'] is List) {
        cumulative += (surah['ayahs'] as List).length;
      }
    }
    final int safeAyah = currentAyahNumber < 0
        ? 0
        : (currentAyahNumber > 300 ? 300 : currentAyahNumber);
    cumulative += safeAyah;
    return cumulative;
  }

  /// Monumental spiritual journey target:
  /// Level 5 Ahlul Qur'an (5x Khatam = 31,180 ayat) + 990x Dzikir (30 putaran tasbih)
  static const int targetKhatmForMonumentalLandscape = 5;
  static const int targetDzikirForMonumentalLandscape = 990;

  /// Returns the combined spiritual journey progress (0.0 to 1.0)
  /// Target 100%: 5x Khatam Al-Qur'an + 990x Dzikir
  static double getCombinedSpiritualProgress({
    required int khatmCount,
    required int currentSurahIndex,
    required int currentAyahNumber,
    required List<dynamic> quranData,
    required int totalDzikirCount,
  }) {
    final int currentCycleAyahs = getCumulativeAyahs(
      currentSurahIndex,
      currentAyahNumber,
      quranData,
    );

    final int safeKhatm = khatmCount < 0
        ? 0
        : (khatmCount > targetKhatmForMonumentalLandscape
            ? targetKhatmForMonumentalLandscape
            : khatmCount);
    final int safeCurrentCycle = currentCycleAyahs < 0
        ? 0
        : (currentCycleAyahs > totalQuranAyahs
            ? totalQuranAyahs
            : currentCycleAyahs);

    final double totalAyahsRead =
        ((safeKhatm * totalQuranAyahs) + safeCurrentCycle).toDouble();
    final double targetQuranAyahs =
        (targetKhatmForMonumentalLandscape * totalQuranAyahs).toDouble(); // 31,180.0
    final double quranRatio =
        (totalAyahsRead / targetQuranAyahs).clamp(0.0, 1.0).toDouble();

    final double dzikirRatio =
        (totalDzikirCount / targetDzikirForMonumentalLandscape)
            .clamp(0.0, 1.0)
            .toDouble();

    // 70% Quran reading contribution + 30% Dzikir contribution
    // Reaching 100% requires 5x Khatam (Tingkat 5 Ahlul Qur'an) AND 990x Dzikir
    final double combined = (quranRatio * 0.70) + (dzikirRatio * 0.30);
    return combined.clamp(0.0, 1.0).toDouble();
  }

  /// Color palette for Phase 1 (Amber / Sunrise Warmth)
  static const Color phase1Primary = Color(0xFFE65100);
  static const Color phase1Bg = Color(0xFFFFF3E0);

  /// Color palette for Phase 2 (Emerald / Flourishing Teal)
  static const Color phase2Primary = Color(0xFF00796B);
  static const Color phase2Bg = Color(0xFFE0F2F1);

  /// Color palette for Phase 3 (Royal Violet & Golden Summit)
  static const Color phase3Primary = Color(0xFF6A1B9A);
  static const Color phase3Bg = Color(0xFFF3E5F5);

  /// Primary color according to phase
  static Color getPhasePrimaryColor(KhatamPhase phase) {
    switch (phase) {
      case KhatamPhase.grandClimb:
        return phase1Primary;
      case KhatamPhase.rhythmicCadence:
        return phase2Primary;
      case KhatamPhase.sprintSummit:
        return phase3Primary;
    }
  }

  /// Background container color according to phase
  static Color getPhaseContainerColor(KhatamPhase phase) {
    switch (phase) {
      case KhatamPhase.grandClimb:
        return phase1Bg;
      case KhatamPhase.rhythmicCadence:
        return phase2Bg;
      case KhatamPhase.sprintSummit:
        return phase3Bg;
    }
  }

  /// Phase icon
  static IconData getPhaseIcon(KhatamPhase phase) {
    switch (phase) {
      case KhatamPhase.grandClimb:
        return Icons.park_rounded; // Sprout / Journey starts
      case KhatamPhase.rhythmicCadence:
        return Icons.spa_rounded; // Calm leaf / Istiqomah
      case KhatamPhase.sprintSummit:
        return Icons.auto_awesome_rounded; // Summit / Khatam near
    }
  }

  /// Interactive Modal Sheet explaining the 3 Stages of Khatam
  static void showJourneyInfoModal(
    BuildContext context,
    String lang,
    int currentJuz,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final currentPhase = getPhase(currentJuz);

        String sheetTitle;
        String sheetSubtitle;
        String stage1Title;
        String stage1Desc;
        String stage2Title;
        String stage2Desc;
        String stage3Title;
        String stage3Desc;
        String currentStageBadge;
        String bottomNote;
        String closeBtnText;

        switch (lang) {
          case 'id':
            sheetTitle = 'Perjalanan Khatam 30 Juz';
            sheetSubtitle =
                'Menuntaskan Al-Qur\'an adalah perjalanan bertahap yang mulia untuk membiasakan tilawah setiap hari.';
            stage1Title = 'Tahap 1: Awal Perjalanan (Juz 1–6)';
            stage1Desc =
                'Mengokohkan fondasi tilawah dengan membaca surah-surah panjang (Al-Baqarah s/d Al-An\'am). Memerlukan ketahanan awal yang sabar.';
            stage2Title = 'Tahap 2: Ritme Istiqomah (Juz 7–27)';
            stage2Desc =
                'Merawat kebiasaan membaca harian yang stabil, tenang, dan mengalir menyejukkan hati (Al-A\'raf s/d Al-Hadid).';
            stage3Title = 'Tahap 3: Menjelang Khatam (Juz 28–30)';
            stage3Desc =
                'Surah-surah pendek Juz \'Amma dengan akselerasi semangat menuju puncak Khatam 30 Juz.';
            currentStageBadge = 'Posisi Saat Ini';
            bottomNote =
                'Setiap huruf bernilai 10 kebaikan. Tilawahmu juga membuka kuota akses aplikasi harian secara proporsional.';
            closeBtnText = 'Saya Mengerti';
            break;
          case 'ms':
            sheetTitle = 'Perjalanan Khatam 30 Juzuk';
            sheetSubtitle =
                'Menamatkan Al-Qur\'an adalah perjalanan bertahap yang mulia untuk membiasakan tilawah setiap hari.';
            stage1Title = 'Tahap 1: Awal Perjalanan (Juzuk 1–6)';
            stage1Desc =
                'Mengukuhkan asas tilawah dengan membaca surah-surah panjang (Al-Baqarah hingga Al-An\'am). Memerlukan ketahanan awal yang sabar.';
            stage2Title = 'Tahap 2: Ritma Istiqomah (Juzuk 7–27)';
            stage2Desc =
                'Menjaga amalan membaca harian yang stabil, tenang, dan menyejukkan jiwa (Al-A\'raf hingga Al-Hadid).';
            stage3Title = 'Tahap 3: Menjelang Khatam (Juzuk 28–30)';
            stage3Desc =
                'Surah-surah pendek Juzuk \'Amma dengan pecutan semangat menuju garis akhir Khatam 30 Juzuk.';
            currentStageBadge = 'Kedudukan Sekarang';
            bottomNote =
                'Setiap huruf bernilai 10 kebaikan. Tilawah anda juga membuka kuota fokus aplikasi harian.';
            closeBtnText = 'Saya Faham';
            break;
          case 'ar':
            sheetTitle = 'رحلة ختم القرآن الكريم (٣٠ جزءاً)';
            sheetSubtitle =
                'ختم القرآن مسيرة إيمانية مباركة وميسرة لبناء عادة التلاوة اليومية الدائمة.';
            stage1Title = 'المرحلة الأولى: بداية المسيرة (الجزء ١–٦)';
            stage1Desc =
                'تثبيت عادة التلاوة عبر السور الطوال العظيمة (من البقرة إلى الأنعام) بالصبر والتؤدة.';
            stage2Title = 'المرحلة الثانية: الإيقاع الثابت (الجزء ٧–٢٧)';
            stage2Desc =
                'تلاوة يومية مستمرة ومنتظمة تبعث السكينة والطمأنينة في القلب (من الأعراف إلى الحديد).';
            stage3Title = 'المرحلة الثالثة: مشارف الختم (الجزء ٢٨–٣٠)';
            stage3Desc =
                'قصار السور في جزء عم المبارك، والانطلاق بهمة عالية نحو إتمام الختمة كاملة.';
            currentStageBadge = 'موقعك الحالي';
            bottomNote =
                'كل حرف تتلوه بحسنة والحسنة بعشر أمثالها، وتمنحك وقتاً متزناً لاستخدام التطبيقات.';
            closeBtnText = 'فهمت ذلك';
            break;
          case 'af':
            sheetTitle = 'Reis na 30 Juz Khatam';
            sheetSubtitle =
                'Om die Koran te voltooi is \'n edele stap-vir-stap reis om daaglikse resitasie te bou.';
            stage1Title = 'Fase 1: Die Reis Begin (Juz 1–6)';
            stage1Desc =
                'Bou stamina deur lang soeras (Al-Baqarah tot Al-An\'am) met geduld.';
            stage2Title = 'Fase 2: Ritmiese Kadens (Juz 7–27)';
            stage2Desc =
                'Bestendige daaglikse lees wat vrede en kalmte bring (Al-A\'raf tot Al-Hadid).';
            stage3Title = 'Fase 3: Naby aan Khatam (Juz 28–30)';
            stage3Desc =
                'Kort soeras van Juz \'Amma wat vinnig na die wenstreep beweeg.';
            currentStageBadge = 'Huidige Fase';
            bottomNote =
                'Elke vers wat jy lees bring seëninge en ontsluit jou daaglikse toepassingstoegang.';
            closeBtnText = 'Ek Verstaan';
            break;
          case 'sw':
            sheetTitle = 'Safari ya Khatma ya Juzuu 30';
            sheetSubtitle =
                'Kukamilisha Quran ni safari tukufu ya hatua kwa hatua kukuza usomaji wa kila siku.';
            stage1Title = 'Awamu ya 1: Mwanzo wa Safari (Juzuu 1–6)';
            stage1Desc =
                'Kuimarisha msingi kwa kusoma sura ndefu (Al-Baqarah hadi Al-An\'am) kwa subira.';
            stage2Title = 'Awamu ya 2: Mdundo Imara (Juzuu 7–27)';
            stage2Desc =
                'Kudumisha usomaji wa kila siku ulio mtulivu na wenye kuleta amani (Al-A\'raf hadi Al-Hadid).';
            stage3Title = 'Awamu ya 3: Kuelekea Khatma (Juzuu 28–30)';
            stage3Desc =
                'Sura fupi za Juzuu \'Amma zikielekea kileleni kwa kasi nzuri.';
            currentStageBadge = 'Uko Hapa';
            bottomNote =
                'Kila aya unayosoma inaleta thawabu na inakufungulia muda wa kutumia programu.';
            closeBtnText = 'Nimeelewa';
            break;
          case 'en':
          default:
            sheetTitle = 'The 30 Juz Khatam Journey';
            sheetSubtitle =
                'Completing the Holy Qur\'an is a noble step-by-step journey to nurture daily recitation habits.';
            stage1Title = 'Stage 1: The Journey Begins (Juz 1–6)';
            stage1Desc =
                'Building endurance through long foundational surahs (Al-Baqarah to Al-An\'am) with patience.';
            stage2Title = 'Stage 2: Rhythmic Cadence (Juz 7–27)';
            stage2Desc =
                'Nurturing a steady, peaceful daily recitation habit that flows serenely (Al-A\'raf to Al-Hadid).';
            stage3Title = 'Stage 3: Approaching Khatam (Juz 28–30)';
            stage3Desc =
                'Short surahs of Juz \'Amma accelerating towards the summit of completing all 30 Juz.';
            currentStageBadge = 'Current Stage';
            bottomNote =
                'Every letter recited brings tenfold rewards and unlocks your daily balanced app usage.';
            closeBtnText = 'Got It';
            break;
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Top Bar (Easy drag-down handle + close X button)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheetTitle,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sheetSubtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Stages Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildStageCard(
                        ctx,
                        stage1Title,
                        stage1Desc,
                        Icons.park_rounded,
                        phase1Primary,
                        phase1Bg,
                        currentPhase == KhatamPhase.grandClimb,
                        currentStageBadge,
                      ),
                      const SizedBox(height: 10),
                      _buildStageCard(
                        ctx,
                        stage2Title,
                        stage2Desc,
                        Icons.spa_rounded,
                        phase2Primary,
                        phase2Bg,
                        currentPhase == KhatamPhase.rhythmicCadence,
                        currentStageBadge,
                      ),
                      const SizedBox(height: 10),
                      _buildStageCard(
                        ctx,
                        stage3Title,
                        stage3Desc,
                        Icons.auto_awesome_rounded,
                        phase3Primary,
                        phase3Bg,
                        currentPhase == KhatamPhase.sprintSummit,
                        currentStageBadge,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bottomNote,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Safe Action Button (Never covered by navbar)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  14 + MediaQuery.of(ctx).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      closeBtnText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  static Widget _buildStageCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color primaryColor,
    Color bgColor,
    bool isCurrent,
    String badgeText,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? bgColor.withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? primaryColor.withValues(alpha: 0.6)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isCurrent ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              isCurrent ? primaryColor : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Modal Sheet explaining the Khatam Levels & Maqam Titles
  static void showKhatamLevelInfoModal(
    BuildContext context,
    String lang,
    int khatmCount,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final currentMaqam = getMaqamTitle(khatmCount, lang);

        String sheetTitle;
        String sheetSubtitle;
        String currentRankLabel;
        String currentRankSub;
        String currentBadge;
        String bottomNote;
        String closeBtnText;

        String t0Title, t0Req, t0Desc;
        String t1Title, t1Req, t1Desc;
        String t2Title, t2Req, t2Desc;
        String t3Title, t3Req, t3Desc;
        String t4Title, t4Req, t4Desc;

        switch (lang) {
          case 'id':
            sheetTitle = 'Tingkatan Khatam & Maqam';
            sheetSubtitle =
                'Setiap kali Anda menuntaskan 30 Juz (6.236 ayat), tingkatan khatam dan gelar maqam spiritual Anda akan meningkat.';
            currentRankLabel = 'Tingkatan Anda Saat Ini';
            currentRankSub = khatmCount <= 0
                ? 'Sedang berproses menuju Khatam ke-1'
                : 'Alhamdulillah telah khatam $khatmCount kali';
            currentBadge = 'Tingkat Anda';
            bottomNote =
                'Rasulullah ﷺ bersabda: "Sebaik-baik kalian adalah orang yang belajar Al-Qur\'an dan mengajarkannya." (HR. Bukhari)';
            closeBtnText = 'Saya Mengerti';

            t0Title = 'Tingkat 1 • Pejuang Istiqomah';
            t0Req = 'Menuju Khatam ke-1';
            t0Desc =
                'Langkah awal membiasakan diri membaca firman Allah setiap hari. Membuka kuota aplikasi harian secara proporsional.';

            t1Title = 'Tingkat 2 • Al-Mubtadi\' Al-Karim';
            t1Req = '1x Khatam (6.236 Ayat)';
            t1Desc =
                'Pencapaian agung pertama: Berhasil menuntaskan seluruh 30 Juz Al-Qur\'an dari Al-Fatihah hingga An-Nas.';

            t2Title = 'Tingkat 3 • Shahibul Qur\'an';
            t2Req = '2x Khatam';
            t2Desc =
                'Al-Qur\'an telah menjadi sahabat karib penyejuk hati di setiap waktu luang dan keseharian.';

            t3Title = 'Tingkat 4 • Haafizhun Nuur';
            t3Req = '3–4x Khatam';
            t3Desc =
                'Ritme tilawah semakin kokoh dan menjadi perisai jiwa dari distraksi digital yang melalaikan.';

            t4Title = 'Tingkat 5 • Ahlul Qur\'an Al-Mubarok';
            t4Req = '5x+ Khatam';
            t4Desc =
                'Puncak kemuliaan insan yang senantiasa hidup, membaca, dan mengamalkan kalam Ilahi setiap harinya.';
            break;

          case 'ms':
            sheetTitle = 'Peringkat Khatam & Maqam';
            sheetSubtitle =
                'Setiap kali anda menamatkan 30 Juzuk (6,236 ayat), peringkat khatam dan maqam rohani anda akan meningkat.';
            currentRankLabel = 'Peringkat Anda Sekarang';
            currentRankSub = khatmCount <= 0
                ? 'Sedang berjuang menuju Khatam pertama'
                : 'Alhamdulillah telah khatam $khatmCount kali';
            currentBadge = 'Peringkat Anda';
            bottomNote =
                'Rasulullah ﷺ bersabda: "Sebaik-baik kamu adalah orang yang belajar Al-Qur\'an dan mengajarkannya." (HR. Bukhari)';
            closeBtnText = 'Saya Faham';

            t0Title = 'Peringkat 1 • Pejuang Istiqomah';
            t0Req = 'Menuju Khatam ke-1';
            t0Desc =
                'Langkah awal membiasakan diri membaca firman Allah setiap hari dan membuka kuota aplikasi harian secara seimbang.';

            t1Title = 'Peringkat 2 • Al-Mubtadi\' Al-Karim';
            t1Req = '1x Khatam (6,236 Ayat)';
            t1Desc =
                'Pencapaian agung pertama: Berjaya menamatkan seluruh 30 Juzuk Al-Qur\'an dari Al-Fatihah hingga An-Nas.';

            t2Title = 'Shahibul Qur\'an';
            t2Req = '2x Khatam';
            t2Desc =
                'Al-Qur\'an menjadi peneman setia di setiap waktu lapang dan penyejuk jiwa dalam kehidupan.';

            t3Title = 'Haafizhun Nuur';
            t3Req = '3–4x Khatam';
            t3Desc =
                'Amalan tilawah semakin mantap membentengi diri daripada gangguan digital.';

            t4Title = 'Ahlul Qur\'an Al-Mubarok';
            t4Req = '5x+ Khatam';
            t4Desc =
                'Kemuliaan insan yang sentiasa berdamping dan mengamalkan kalam Ilahi sepanjang hayat.';
            break;

          case 'ar':
            sheetTitle = 'مراتب الختم ومقامات التلاوة';
            sheetSubtitle =
                'كلما أتممت قراءة القرآن الكريم كاملاً (٦٢٣٦ آية)، ارتقيت في مراتب الختم والمقامات الإيمانية.';
            currentRankLabel = 'رتبتك الحالية';
            currentRankSub = khatmCount <= 0
                ? 'في طريقك نحو الختمة الأولى المباركة'
                : 'الحمد لله أتممت $khatmCount ختمات';
            currentBadge = 'رتبتك';
            bottomNote =
                'قال رسول الله ﷺ: «خيركم من تعلّم القرآن وعلّمه» (رواه البخاري)';
            closeBtnText = 'فهمت ذلك';

            t0Title = 'مجاهد الاستقامة';
            t0Req = 'بدء المسيرة';
            t0Desc =
                'بداية تعويد النفس على ورد التلاوة اليومي وتوازن استخدام التطبيقات.';

            t1Title = 'المبتدئ الكريم';
            t1Req = 'ختمة واحدة';
            t1Desc =
                'إتمام قراءة ٣٠ جزءاً كاملاً من الفاتحة إلى الناس لأول مرة.';

            t2Title = 'صاحب القرآن';
            t2Req = 'ختمتان';
            t2Desc =
                'مصاحبة القرآن الكريم والائتناس بآياته في كل وقت وحين.';

            t3Title = 'حافظ النور';
            t3Req = '٣–٤ ختمات';
            t3Desc =
                'ثبات الورد القرآني واستنارة القلب به وحمايته من ملهيات الشاشات.';

            t4Title = 'أهل القرآن المبارك';
            t4Req = '٥ ختمات فأكثر';
            t4Desc =
                'شرف القرب الدائم والعيش في ظلال كتاب الله الكريم دوماً.';
            break;

          case 'af':
            sheetTitle = 'Khatam Vlakke & Maqam';
            sheetSubtitle =
                'Elke keer wat jy al 30 Juz (6 236 verse) voltooi, styg jou rang en geestelike mylpaal.';
            currentRankLabel = 'Jou Huidige Vlak';
            currentRankSub = khatmCount <= 0
                ? 'Op pad na die 1ste Khatam'
                : 'Alhamdulillah, $khatmCount keer voltooi';
            currentBadge = 'Jou Vlak';
            bottomNote =
                'Die Profeet ﷺ het gesê: "Die beste van julle is hy wat die Koran leer en dit onderrig." (Boechari)';
            closeBtnText = 'Ek Verstaan';

            t0Title = 'Standvastige Soeker';
            t0Req = '0x Khatam';
            t0Desc =
                'Bou daaglikse resitasie gewoonte en ontsluit gebalanseerde app-tyd.';

            t1Title = 'Al-Mubtadi\' Al-Karim';
            t1Req = '1x Khatam (6 236 Verse)';
            t1Desc =
                'Die eerste groot mylpaal: Voltooiing van al 30 Juz van Al-Fatihah tot An-Nas.';

            t2Title = 'Vriend van die Koran';
            t2Req = '2x Khatam';
            t2Desc =
                'Die Koran word \'n daaglikse metgesel en bron van gemoedsrus.';

            t3Title = 'Bewaarder van Lig';
            t3Req = '3–4x Khatam';
            t3Desc =
                'Bestendige resitasie beskerm teen digitale afleidings.';

            t4Title = 'Ahlul Qur\'an Al-Mubarok';
            t4Req = '5x+ Khatam';
            t4Desc =
                'Die hoogste toewyding om daagliks met die Heilige Koran te leef.';
            break;

          case 'sw':
            sheetTitle = 'Ngazi za Khatma & Maqam';
            sheetSubtitle =
                'Kila mara unapokamilisha Juzuu 30 (aya 6,236), cheo chako cha kiroho kinapanda.';
            currentRankLabel = 'Cheo Chako cha Sasa';
            currentRankSub = khatmCount <= 0
                ? 'Kuelekea Khatma ya 1'
                : 'Alhamdulillah imekhatimiwa mara $khatmCount';
            currentBadge = 'Cheo Chako';
            bottomNote =
                'Mtume ﷺ amesema: "Mbora wenu ni yule anayejifunza Quran na kuifundisha." (Bukhari)';
            closeBtnText = 'Nimeelewa';

            t0Title = 'Mpiganaji Imara';
            t0Req = '0x Khatma';
            t0Desc =
                'Hatua ya kwanza ya kujenga kawaida ya kusoma Quran kila siku.';

            t1Title = 'Al-Mubtadi\' Al-Karim';
            t1Req = 'Khatma 1 (Aya 6,236)';
            t1Desc =
                'Kukamilisha Juzuu zote 30 kuanzia Al-Fatihah hadi An-Nas kwa mara ya kwanza.';

            t2Title = 'Sahibu wa Quran';
            t2Req = 'Khatma 2';
            t2Desc =
                'Quran imekuwa rafiki wa karibu katika maisha yako ya kila siku.';

            t3Title = 'Mlinzi wa Nuru';
            t3Req = 'Khatma 3–4';
            t3Desc =
                'Usomaji thabiti unaokinga dhidi ya usumbufu wa kidijitali.';

            t4Title = 'Ahlul Qur\'an Al-Mubarok';
            t4Req = 'Khatma 5+';
            t4Desc =
                'Kilele cha utukufu cha kuishi na kuongozwa na Quran kila siku.';
            break;

          case 'en':
          default:
            sheetTitle = 'Khatam Tiers & Spiritual Maqam';
            sheetSubtitle =
                'Every time you complete all 30 Juz (6,236 verses), your Khatam rank and spiritual title rise.';
            currentRankLabel = 'Your Current Rank';
            currentRankSub = khatmCount <= 0
                ? 'Journeying towards 1st Khatam'
                : 'Alhamdulillah completed $khatmCount time(s)';
            currentBadge = 'Your Tier';
            bottomNote =
                'The Messenger of Allah ﷺ said: "The best among you are those who learn the Qur\'an and teach it." (Bukhari)';
            closeBtnText = 'Got It';

            t0Title = 'Level 1 • Steadfast Seeker';
            t0Req = 'Towards 1st Khatam';
            t0Desc =
                'Initial steps establishing daily recitation habit and balanced app usage unlock.';

            t1Title = 'Level 2 • Al-Mubtadi\' Al-Karim';
            t1Req = '1x Khatam (6,236 Verses)';
            t1Desc =
                'The first milestone: Successfully reciting all 30 Juz from Al-Fatihah to An-Nas.';

            t2Title = 'Level 3 • Companion of the Quran';
            t2Req = '2x Khatam';
            t2Desc =
                'The Holy Qur\'an becomes a cherished companion in your daily life.';

            t3Title = 'Level 4 • Guardian of Light';
            t3Req = '3–4x Khatam';
            t3Desc =
                'Steady rhythm protecting your time and heart from digital distractions.';

            t4Title = 'Level 5 • Ahlul Qur\'an Al-Mubarok';
            t4Req = '5x+ Khatam';
            t4Desc =
                'The summit of lifelong devotion living with divine guidance every day.';
            break;
        }

        final int activeTierIndex = khatmCount <= 0
            ? 0
            : (khatmCount == 1
                ? 1
                : (khatmCount == 2
                    ? 2
                    : (khatmCount < 5 ? 3 : 4)));

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed Top Bar (Easy drag-down handle + close X button)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheetTitle,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sheetSubtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Current Rank Highlight Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD97706).withValues(alpha: 0.14),
                              const Color(0xFFF59E0B).withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD97706).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentRankLabel.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentMaqam,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currentRankSub,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.brown.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5 Tiers
                      _buildKhatamTierCard(
                        context: ctx,
                        colorScheme: colorScheme,
                        title: t0Title,
                        req: t0Req,
                        description: t0Desc,
                        icon: Icons.local_florist_rounded,
                        accentColor: const Color(0xFF10B981),
                        isCurrent: activeTierIndex == 0,
                        currentBadge: currentBadge,
                      ),
                      const SizedBox(height: 10),
                      _buildKhatamTierCard(
                        context: ctx,
                        colorScheme: colorScheme,
                        title: t1Title,
                        req: t1Req,
                        description: t1Desc,
                        icon: Icons.star_rounded,
                        accentColor: const Color(0xFF0284C7),
                        isCurrent: activeTierIndex == 1,
                        currentBadge: currentBadge,
                      ),
                      const SizedBox(height: 10),
                      _buildKhatamTierCard(
                        context: ctx,
                        colorScheme: colorScheme,
                        title: t2Title,
                        req: t2Req,
                        description: t2Desc,
                        icon: Icons.menu_book_rounded,
                        accentColor: const Color(0xFF6366F1),
                        isCurrent: activeTierIndex == 2,
                        currentBadge: currentBadge,
                      ),
                      const SizedBox(height: 10),
                      _buildKhatamTierCard(
                        context: ctx,
                        colorScheme: colorScheme,
                        title: t3Title,
                        req: t3Req,
                        description: t3Desc,
                        icon: Icons.shield_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        isCurrent: activeTierIndex == 3,
                        currentBadge: currentBadge,
                      ),
                      const SizedBox(height: 10),
                      _buildKhatamTierCard(
                        context: ctx,
                        colorScheme: colorScheme,
                        title: t4Title,
                        req: t4Req,
                        description: t4Desc,
                        icon: Icons.workspace_premium_rounded,
                        accentColor: const Color(0xFFD97706),
                        isCurrent: activeTierIndex == 4,
                        currentBadge: currentBadge,
                      ),
                      const SizedBox(height: 14),

                      // Bottom Hadith
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bottomNote,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Action Button (Never covered by navbar)
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  14 + MediaQuery.of(ctx).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      closeBtnText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildKhatamTierCard({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String title,
    required String req,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isCurrent,
    required String currentBadge,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isCurrent
            ? accentColor.withValues(alpha: 0.08)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? accentColor.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: isCurrent ? 1.4 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isCurrent ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? accentColor : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentBadge,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
