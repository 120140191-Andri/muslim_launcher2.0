import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/quran_progress_helper.dart';
import '../../services/analytics_service.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';
import '../quran/surah_list_screen.dart';
import '../quran/surah_detail_screen.dart';
import '../dzikir/dzikir_screen.dart';
import '../../services/streak_notification_service.dart';
import '../../widgets/achievement_certificate_dialog.dart';

enum BadgeRarity { common, rare, epic, legendary }

class SpiritualBadge {
  final String id;
  final String category; // 'quran', 'dzikir', 'focus'
  final String title;
  final String description;
  final String fadhilah;
  final IconData icon;
  final bool isUnlocked;
  final bool isClaimed;
  final double progress; // 0.0 to 1.0
  final String progressLabel;
  final int pointsReward;
  final BadgeRarity rarity;

  const SpiritualBadge({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.fadhilah,
    required this.icon,
    required this.isUnlocked,
    this.isClaimed = false,
    required this.progress,
    required this.progressLabel,
    required this.pointsReward,
    required this.rarity,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  /// Mengambil daftar semua lencana pencapaian berdasarkan state saat ini
  static List<SpiritualBadge> getBadges(AppState appState, [String lang = 'id']) {
    return _AchievementsScreenState.generateBadgesList(appState, lang);
  }

  /// Menghitung total lencana yang sudah terbuka namun belum diklaim poinnya
  static int getUnclaimedBadgesCount(AppState appState) {
    final badges = getBadges(appState, 'id');
    return badges.where((b) => b.isUnlocked && !b.isClaimed).length;
  }

  /// Memeriksa apakah ada lencana yang belum diklaim
  static bool hasUnclaimedBadges(AppState appState) {
    return getUnclaimedBadgesCount(appState) > 0;
  }

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all'; // 'all', 'quran', 'dzikir', 'focus'
  String _streakTab = 'quran'; // 'quran' or 'dzikir'

  /// Helper: get translated string, substituting {key: value} template vars.
  String _t(String lang, String key, [Map<String, String>? vars]) {
    String s = Translations.get(lang, key);
    vars?.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('AchievementsScreen');
  }

  void _openQuran(AppState appState) {
    if (appState.lastReadSurah.isNotEmpty && appState.quranData.isNotEmpty) {
      final surahIdx = appState.currentSurahIndex;
      if (surahIdx >= 0 && surahIdx < appState.quranData.length) {
        Navigator.of(context).push(
          AppPageRoute(
            child: SurahDetailScreen(
              surah: appState.quranData[surahIdx],
              initialAyahIndex: appState.currentAyahIndex,
            ),
          ),
        ).then((_) {
          if (mounted) setState(() {});
        });
        return;
      }
    }

    Navigator.of(context).push(
      AppPageRoute(child: const SurahListScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _openDzikir() {
    Navigator.of(context).push(
      AppPageRoute(child: const DzikirScreen()),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  static List<SpiritualBadge> generateBadgesList(AppState appState, String lang) {
    final khatm = appState.khatmCount;
    final completedSurahs = appState.completedSurahsThisCycle.length;
    final totalDzikir = appState.totalDzikirCount;
    final points = appState.points;
    final currentQuranStreak = appState.quranDailyStreak;
    final maxQuranStreak = appState.maxQuranDailyStreak;
    final currentDzikirStreak = appState.dzikirDailyStreak;
    final maxDzikirStreak = appState.maxDzikirDailyStreak;
    final currentDisciplineStreak = appState.disciplineDailyStreak;
    final maxDisciplineStreak = appState.maxDisciplineDailyStreak;
    final hasReadAyah = appState.highestSurahIndex > 0 ||
        appState.highestAyahIndex >= 0 ||
        khatm > 0;
    final cumulativeAyahs = QuranProgressHelper.getCumulativeAyahs(
      appState.currentSurahIndex,
      appState.lastReadAyahNumber,
      appState.quranData,
    );

    return [
      // ── AL-QUR'AN & TILAWAH ──
      SpiritualBadge(
        id: 'quran_first_step',
        category: 'quran',
        title: lang == 'en' ? 'The First Step' : 'Langkah Pertama',
        description: lang == 'en'
            ? 'Begin reciting the first ayah of the Holy Qur\'an.'
            : 'Memulai tilawah ayat pertama Al-Qur\'an.',
        fadhilah: lang == 'en'
            ? '"Whoever recites a letter from Allah\'s Book will have a reward, and that reward is multiplied tenfold." (Tirmidhi)'
            : '"Siapa yang membaca satu huruf dari Kitabullah, maka baginya satu kebaikan dan satu kebaikan dilipatgandakan sepuluh kali." (HR. Tirmidzi)',
        icon: Icons.auto_stories_rounded,
        isUnlocked: hasReadAyah,
        progress: hasReadAyah ? 1.0 : 0.0,
        progressLabel: hasReadAyah ? '1 / 1' : '0 / 1',
        pointsReward: 10,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'quran_streak_1',
        category: 'quran',
        title: lang == 'en' ? 'Day 1 Habit' : 'Istiqomah 1 Hari',
        description: lang == 'en'
            ? 'Recite at least 1 ayah of the Holy Qur\'an today to spark your daily streak.'
            : 'Membaca Al-Qur\'an minimal 1 ayat hari ini untuk menyalakan lentera istiqomah.',
        fadhilah: lang == 'en'
            ? '"The journey of a thousand miles begins with a single step in Allah\'s remembrance."'
            : '"Langkah awal adalah penentu kebiasaan mulia. Setiap ayat yang dibaca mendatangkan rahmat."',
        icon: Icons.wb_sunny_rounded,
        isUnlocked: maxQuranStreak >= 1,
        progress: (maxQuranStreak >= 1) ? 1.0 : (currentQuranStreak / 1).clamp(0.0, 1.0),
        progressLabel: (maxQuranStreak >= 1)
            ? '1 / 1 ${lang == 'en' ? 'Day' : 'Hari'}'
            : '$currentQuranStreak / 1 ${lang == 'en' ? 'Day' : 'Hari'}',
        pointsReward: 10,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'quran_streak_3',
        category: 'quran',
        title: lang == 'en' ? '3-Day Habit' : 'Istiqomah 3 Hari',
        description: lang == 'en'
            ? 'Recite at least 1 ayah of the Holy Qur\'an daily for 3 consecutive days.'
            : 'Membaca Al-Qur\'an minimal 1 ayat setiap hari selama 3 hari berturut-turut.',
        fadhilah: lang == 'en'
            ? '"The most beloved deed to Allah is the most regular and constant even if it were little." (Bukhari & Muslim)'
            : '"Amalan yang paling dicintai Allah adalah yang berkelanjutan (istiqomah) walaupun sedikit." (HR. Bukhari & Muslim)',
        icon: Icons.local_fire_department_rounded,
        isUnlocked: maxQuranStreak >= 3,
        progress: (maxQuranStreak >= 3) ? 1.0 : (currentQuranStreak / 3).clamp(0.0, 1.0),
        progressLabel: (maxQuranStreak >= 3)
            ? '3 / 3 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentQuranStreak / 3 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 20,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'quran_streak_7',
        category: 'quran',
        title: lang == 'en' ? '7-Day Steadfast (1 Week)' : 'Istiqomah 7 Hari (1 Pekan)',
        description: lang == 'en'
            ? 'Recite at least 1 ayah daily for 7 consecutive days without missing a single day.'
            : 'Rutin membaca Al-Qur\'an minimal 1 ayat per hari selama 7 hari berturut-turut tanpa jeda.',
        fadhilah: lang == 'en'
            ? '"Whoever recites a letter from Allah\'s Book will receive ten good rewards multiplied." (Tirmidhi)'
            : '"Siapa yang membaca satu huruf dari Kitabullah, baginya sepuluh kebaikan berlipat ganda." (HR. Tirmidzi)',
        icon: Icons.bolt_rounded,
        isUnlocked: maxQuranStreak >= 7,
        progress: (maxQuranStreak >= 7) ? 1.0 : (currentQuranStreak / 7).clamp(0.0, 1.0),
        progressLabel: (maxQuranStreak >= 7)
            ? '7 / 7 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentQuranStreak / 7 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'quran_streak_14',
        category: 'quran',
        title: lang == 'en' ? '14-Day Devotion (2 Weeks)' : 'Istiqomah 14 Hari (2 Pekan)',
        description: lang == 'en'
            ? 'Keep the light of tilawah glowing daily for 14 consecutive days.'
            : 'Menjaga lentera tilawah senantiasa menyala setiap hari selama 14 hari penuh berturut-turut.',
        fadhilah: lang == 'en'
            ? '"Tranquility descends and mercy envelops the servant whose heart is attached to the Qur\'an." (Muslim)'
            : '"Ketenangan (sakinah) turun dan rahmat Ilahi senantiasa menaungi hamba yang teguh membaca firman Allah." (HR. Muslim)',
        icon: Icons.auto_awesome_rounded,
        isUnlocked: maxQuranStreak >= 14,
        progress: (maxQuranStreak >= 14) ? 1.0 : (currentQuranStreak / 14).clamp(0.0, 1.0),
        progressLabel: (maxQuranStreak >= 14)
            ? '14 / 14 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentQuranStreak / 14 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 100,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'quran_streak_30',
        category: 'quran',
        title: lang == 'en' ? '30-Day Golden Habit (1 Month)' : 'Istiqomah Sebulan Penuh (30 Hari)',
        description: lang == 'en'
            ? 'True dedication: Recite the Holy Qur\'an without missing a day for 30 consecutive days.'
            : 'Membuktikan komitmen sejati: Membaca Al-Qur\'an tanpa terputus selama 30 hari (1 bulan) berturut-turut.',
        fadhilah: lang == 'en'
            ? '"The best of you are those who learn the Qur\'an and teach it, holding steadfast to it." (Bukhari)'
            : '"Sebaik-baik kalian adalah orang yang belajar Al-Qur\'an, mengajarkannya, dan senantiasa melaziminya." (HR. Bukhari)',
        icon: Icons.military_tech_rounded,
        isUnlocked: maxQuranStreak >= 30,
        progress: (maxQuranStreak >= 30) ? 1.0 : (currentQuranStreak / 30).clamp(0.0, 1.0),
        progressLabel: (maxQuranStreak >= 30)
            ? '30 / 30 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentQuranStreak / 30 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 250,
        rarity: BadgeRarity.legendary,
      ),
      SpiritualBadge(
        id: 'quran_streak_365',
        category: 'quran',
        title: lang == 'en' ? '1-Year Legendary Devotion (365 Days)' : 'Istiqomah 1 Tahun Penuh (365 Hari)',
        description: lang == 'en'
            ? 'True legendary dedication: Recite the Holy Qur\'an daily for 365 consecutive days without missing a single day.'
            : 'Pencapaian legendaris insan pilihan: Membaca Al-Qur\'an setiap hari selama 365 hari (1 tahun) berturut-turut tanpa jeda.',
        fadhilah: lang == 'en'
            ? '"Indeed, Allah has His own family among mankind: the People of the Qur\'an." (Ibn Majah)'
            : '"Sesungguhnya Allah memiliki keluarga dari kalangan manusia: yaitu Ahlul Qur\'an, mereka adalah keluarga Allah dan orang-orang khusus-Nya." (HR. Ibnu Majah)',
        icon: Icons.diamond_rounded,
        isUnlocked: maxQuranStreak >= 365,
        progress: (maxQuranStreak >= 365) ? 1.0 : (currentQuranStreak / 365).clamp(0.0, 1.0),
        progressLabel: (maxQuranStreak >= 365)
            ? '365 / 365 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentQuranStreak / 365 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 1000,
        rarity: BadgeRarity.legendary,
      ),
      SpiritualBadge(
        id: 'quran_surah_explorer',
        category: 'quran',
        title: lang == 'en' ? 'Surah Completer' : 'Penjelajah Surah',
        description: lang == 'en'
            ? 'Finish reciting your first complete surah.'
            : 'Menuntaskan tilawah 1 surah penuh pertama.',
        fadhilah: lang == 'en'
            ? 'Every completed surah strengthens heart tranquility and istiqomah.'
            : 'Setiap surah yang dituntaskan menjadi benteng penenang hati dan istiqomah.',
        icon: Icons.menu_book_rounded,
        isUnlocked: completedSurahs >= 1 || khatm > 0,
        progress: (completedSurahs / 1).clamp(0.0, 1.0),
        progressLabel: '${completedSurahs.clamp(0, 1)} / 1 Surah',
        pointsReward: 20,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'quran_albaqarah',
        category: 'quran',
        title: lang == 'en' ? 'Grand Surah' : 'Surah Terpanjang',
        description: lang == 'en'
            ? 'Complete Surah Al-Baqarah (286 ayahs).'
            : 'Menuntaskan Surah Al-Baqarah (286 ayat).',
        fadhilah: lang == 'en'
            ? '"Do not make your houses graves. Indeed, Satan flees from the house in which Surah Al-Baqarah is recited." (Muslim)'
            : '"Jangan jadikan rumah kalian kuburan. Sesungguhnya setan lari dari rumah yang dibacakan di dalamnya Surah Al-Baqarah." (HR. Muslim)',
        icon: Icons.fort_rounded,
        isUnlocked: appState.completedSurahsThisCycle.contains(2) || khatm > 0,
        progress: (appState.completedSurahsThisCycle.contains(2) || khatm > 0)
            ? 1.0
            : 0.0,
        progressLabel: (appState.completedSurahsThisCycle.contains(2) || khatm > 0)
            ? '286 / 286 Ayat'
            : '0 / 286 Ayat',
        pointsReward: 100,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'quran_alkahf',
        category: 'quran',
        title: lang == 'en' ? 'Friday Radiance' : 'Cahaya Hari Jum\'at',
        description: lang == 'en'
            ? 'Complete Surah Al-Kahf (Surah 18).'
            : 'Menuntaskan Surah Al-Kahf (110 ayat).',
        fadhilah: lang == 'en'
            ? '"Whoever reads Surah Al-Kahf on Friday will have light illuminating him between the two Fridays." (Bayhaqi)'
            : '"Barangsiapa membaca Surah Al-Kahfi pada hari Jum\'at, akan dipancarkan baginya cahaya di antara dua Jum\'at." (HR. Al-Baihaqi)',
        icon: Icons.light_mode_rounded,
        isUnlocked: appState.completedSurahsThisCycle.contains(18) || khatm > 0,
        progress: (appState.completedSurahsThisCycle.contains(18) || khatm > 0)
            ? 1.0
            : 0.0,
        progressLabel: (appState.completedSurahsThisCycle.contains(18) || khatm > 0)
            ? '110 / 110 Ayat'
            : '0 / 110 Ayat',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'quran_juz_amma',
        category: 'quran',
        title: lang == 'en' ? 'Summit of Juz \'Amma' : 'Puncak Juz \'Amma',
        description: lang == 'en'
            ? 'Finish reciting the closing Surah of the Qur\'an (Surah An-Nas).'
            : 'Menuntaskan surah penutup Al-Qur\'an (Surah An-Nas).',
        fadhilah: lang == 'en'
            ? 'The final summit of the 30 Juz Khatam journey, full of blessings and protection.'
            : 'Puncak garis akhir Khatam 30 Juz yang sarat dengan perlindungan dari Allah.',
        icon: Icons.terrain_rounded,
        isUnlocked: appState.completedSurahsThisCycle.contains(114) || khatm > 0,
        progress: (appState.completedSurahsThisCycle.contains(114) || khatm > 0)
            ? 1.0
            : 0.0,
        progressLabel: (appState.completedSurahsThisCycle.contains(114) || khatm > 0)
            ? 'Selesai'
            : 'Belum',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'quran_maqam_1',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 1 • Steadfast Seeker'
            : 'Tingkat 1 • Pejuang Istiqomah',
        description: lang == 'en'
            ? 'Towards 1st Khatam: Initial steps establishing daily recitation habit and balanced app usage unlock.'
            : 'Menuju Khatam ke-1: Langkah awal membiasakan diri membaca firman Allah setiap hari. Membuka kuota aplikasi harian secara proporsional.',
        fadhilah: lang == 'en'
            ? '"The most beloved deed to Allah is the most regular and constant even if it were little." (Bukhari & Muslim)'
            : '"Sebaik-baik amalan adalah yang konsisten (istiqomah) meskipun sedikit." (HR. Bukhari & Muslim)',
        icon: Icons.local_florist_rounded,
        isUnlocked: hasReadAyah || khatm > 0,
        progress: (khatm > 0) ? 1.0 : (cumulativeAyahs / 6236).clamp(0.0, 1.0),
        progressLabel: (khatm > 0)
            ? '6.236 / 6.236 Ayat'
            : '$cumulativeAyahs / 6.236 Ayat',
        pointsReward: 15,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'quran_maqam_2',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 2 • Al-Mubtadi\' Al-Karim'
            : 'Tingkat 2 • Al-Mubtadi\' Al-Karim',
        description: lang == 'en'
            ? '1x Khatam (6,236 Verses): Successfully reciting all 30 Juz. Unlocks permanent +25% points boost!'
            : '1x Khatam (6.236 Ayat): Berhasil menuntaskan seluruh 30 Juz Al-Qur\'an. Membuka Boost Poin permanen +25%!',
        fadhilah: lang == 'en'
            ? '"The angels invoke blessings upon the servant who completes the Qur\'an." (Ad-Darimi)'
            : '"Doa orang yang mengkhatamkan Al-Qur\'an diaminkan oleh ribuan malaikat yang mendoakan rahmat baginya." (Ad-Darimi)',
        icon: Icons.star_rounded,
        isUnlocked: khatm >= 1,
        progress: (khatm / 1).clamp(0.0, 1.0),
        progressLabel: '$khatm / 1 Khatam',
        pointsReward: 500,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'quran_maqam_3',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 3 • Companion of the Quran'
            : 'Tingkat 3 • Shahibul Qur\'an',
        description: lang == 'en'
            ? '2x Khatam: The Holy Qur\'an becomes a cherished companion. Increases points boost to +50%!'
            : '2x Khatam: Al-Qur\'an telah menjadi sahabat karib penyejuk hati. Meningkatkan Boost Poin menjadi +50%!',
        fadhilah: lang == 'en'
            ? '"Read the Qur\'an, for it will come on the Day of Resurrection as an intercessor for its companions." (Muslim)'
            : '"Bacalah Al-Qur\'an, sesungguhnya ia akan datang pada hari kiamat sebagai pemberi syafa\'at bagi para sahabatnya (shahibul Qur\'an)." (HR. Muslim)',
        icon: Icons.menu_book_rounded,
        isUnlocked: khatm >= 2,
        progress: (khatm / 2).clamp(0.0, 1.0),
        progressLabel: '$khatm / 2 Khatam',
        pointsReward: 750,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'quran_maqam_4',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 4 • Guardian of Light'
            : 'Tingkat 4 • Haafizhun Nuur',
        description: lang == 'en'
            ? '3–4x Khatam: Steady rhythm protecting your time and heart. Increases points boost to +75%!'
            : '3–4x Khatam: Ritme tilawah semakin kokoh dan menjadi perisai jiwa. Meningkatkan Boost Poin menjadi +75%!',
        fadhilah: lang == 'en'
            ? '"The one who is proficient in the recitation of the Qur\'an will be with the noble, obedient angels." (Bukhari & Muslim)'
            : '"Orang yang mahir dan istiqomah membaca Al-Qur\'an kelak bersama para malaikat yang mulia lagi taat." (HR. Bukhari & Muslim)',
        icon: Icons.shield_rounded,
        isUnlocked: khatm >= 3,
        progress: (khatm / 3).clamp(0.0, 1.0),
        progressLabel: '$khatm / 3 Khatam',
        pointsReward: 1200,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'quran_maqam_5',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 5 • Ahlul Qur\'an Al-Mubarok'
            : 'Tingkat 5 • Ahlul Qur\'an Al-Mubarok',
        description: lang == 'en'
            ? '5x+ Khatam: The summit of lifelong devotion. Enjoy permanent Double Points 2.0x (+100%)!'
            : '5x+ Khatam: Puncak kemuliaan Ahlul Qur\'an. Menikmati Double Points 2.0x (+100% Poin) selamanya!',
        fadhilah: lang == 'en'
            ? '"Indeed, Allah has His own people among mankind: the People of the Qur\'an, they are the people of Allah and His special ones." (Ibn Majah)'
            : '"Sesungguhnya Allah memiliki keluarga dari kalangan manusia: yaitu Ahlul Qur\'an, mereka adalah keluarga Allah dan orang-orang khusus-Nya." (HR. Ibnu Majah)',
        icon: Icons.workspace_premium_rounded,
        isUnlocked: khatm >= 5,
        progress: (khatm / 5).clamp(0.0, 1.0),
        progressLabel: '$khatm / 5 Khatam',
        pointsReward: 2500,
        rarity: BadgeRarity.legendary,
      ),

      // ── DZIKIR & TASBIH ──
      SpiritualBadge(
        id: 'dzikir_first_tap',
        category: 'dzikir',
        title: lang == 'en' ? 'Moistening the Tongue' : 'Basahi Lisan',
        description: lang == 'en'
            ? 'Complete your first digital tasbih count.'
            : 'Memulai dzikir tasbih pertama kali.',
        fadhilah: lang == 'en'
            ? '"Keep your tongue constantly moist with the remembrance of Allah." (Tirmidhi)'
            : '"Senantiasalah lisanmu basah karena mengingat Allah." (HR. Tirmidzi)',
        icon: Icons.grain_rounded,
        isUnlocked: totalDzikir >= 1,
        progress: (totalDzikir / 1).clamp(0.0, 1.0),
        progressLabel: '${totalDzikir.clamp(0, 1)} / 1',
        pointsReward: 5,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'dzikir_streak_1',
        category: 'dzikir',
        title: lang == 'en' ? 'Day 1 Dhikr Habit' : 'Istiqomah Dzikir 1 Hari',
        description: lang == 'en'
            ? 'Complete at least 1 round of digital dhikr (33x) today to establish your daily remembrance streak.'
            : 'Tuntaskan minimal 1 putaran dzikir tasbih (33x) hari ini untuk menyalakan istiqomah dzikir.',
        fadhilah: lang == 'en'
            ? '"Keep your tongue constantly moist with the remembrance of Allah." (Tirmidhi)'
            : '"Senantiasalah lisanmu basah karena mengingat Allah." (HR. Tirmidzi)',
        icon: Icons.wb_sunny_rounded,
        isUnlocked: maxDzikirStreak >= 1,
        progress: (maxDzikirStreak >= 1) ? 1.0 : (currentDzikirStreak / 1).clamp(0.0, 1.0),
        progressLabel: (maxDzikirStreak >= 1)
            ? '1 / 1 ${lang == 'en' ? 'Day' : 'Hari'}'
            : '$currentDzikirStreak / 1 ${lang == 'en' ? 'Day' : 'Hari'}',
        pointsReward: 10,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'dzikir_streak_3',
        category: 'dzikir',
        title: lang == 'en' ? '3-Day Dhikr Streak' : 'Istiqomah Dzikir 3 Hari',
        description: lang == 'en'
            ? 'Complete at least 1 round of dhikr (33x) daily for 3 consecutive days.'
            : 'Rutin bertasbih minimal 1 putaran (33x) setiap hari selama 3 hari berturut-turut.',
        fadhilah: lang == 'en'
            ? '"The similitude of the one who remembers his Lord and the one who does not is like that of the living and the dead." (Bukhari)'
            : '"Perumpamaan orang yang berdzikir kepada Tuhannya dan yang tidak, seperti orang hidup dan orang mati." (HR. Bukhari)',
        icon: Icons.local_fire_department_rounded,
        isUnlocked: maxDzikirStreak >= 3,
        progress: (maxDzikirStreak >= 3) ? 1.0 : (currentDzikirStreak / 3).clamp(0.0, 1.0),
        progressLabel: (maxDzikirStreak >= 3)
            ? '3 / 3 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDzikirStreak / 3 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 20,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'dzikir_streak_7',
        category: 'dzikir',
        title: lang == 'en' ? '7-Day Dhikr Steadfast (1 Week)' : 'Istiqomah Dzikir 7 Hari (1 Pekan)',
        description: lang == 'en'
            ? 'Consistently recite at least 1 round of dhikr (33x) every day for 7 consecutive days.'
            : 'Konsisten bertasbih minimal 1 putaran (33x) setiap hari selama 7 hari berturut-turut tanpa terputus.',
        fadhilah: lang == 'en'
            ? '"Two phrases are light on the tongue, heavy on the scales, and beloved to Ar-Rahman: Subhanallah wa bihamdihi, Subhanallahil \'Azhim." (Bukhari)'
            : '"Dua kalimat yang ringan di lisan, berat di timbangan, dan dicintai Ar-Rahman: Subhanallah wa bihamdihi, Subhanallahil \'Azhim." (HR. Bukhari)',
        icon: Icons.bolt_rounded,
        isUnlocked: maxDzikirStreak >= 7,
        progress: (maxDzikirStreak >= 7) ? 1.0 : (currentDzikirStreak / 7).clamp(0.0, 1.0),
        progressLabel: (maxDzikirStreak >= 7)
            ? '7 / 7 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDzikirStreak / 7 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'dzikir_streak_14',
        category: 'dzikir',
        title: lang == 'en' ? '14-Day Dhikr Devotion (2 Weeks)' : 'Istiqomah Dzikir 14 Hari (2 Pekan)',
        description: lang == 'en'
            ? 'Keep your heart anchored in daily dhikr (min. 33x) for 14 consecutive days.'
            : 'Menjaga lisan berdzikir minimal 1 putaran (33x) selama 14 hari penuh berturut-turut.',
        fadhilah: lang == 'en'
            ? '"Unquestionably, by the remembrance of Allah hearts are assured." (Ar-Ra\'d: 28)'
            : '"Ingatlah, hanya dengan mengingat Allah hati menjadi tenteram." (QS. Ar-Ra\'d: 28)',
        icon: Icons.auto_awesome_rounded,
        isUnlocked: maxDzikirStreak >= 14,
        progress: (maxDzikirStreak >= 14) ? 1.0 : (currentDzikirStreak / 14).clamp(0.0, 1.0),
        progressLabel: (maxDzikirStreak >= 14)
            ? '14 / 14 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDzikirStreak / 14 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 100,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'dzikir_streak_30',
        category: 'dzikir',
        title: lang == 'en' ? '30-Day Dhikr Habit (1 Month)' : 'Istiqomah Dzikir Sebulan (30 Hari)',
        description: lang == 'en'
            ? 'A full month of daily dhikr devotion (min. 33x/day) without missing a single day.'
            : 'Sebulan penuh menghiasi hari-hari dengan tasbih (min. 33x/hari) tanpa jeda.',
        fadhilah: lang == 'en'
            ? '"Shall I tell you of the best of your deeds and the purest in the sight of your Lord? Remembrance of Allah." (Tirmidhi)'
            : '"Maukah kuberitahu amalan terbaik dan tersuci di sisi Tuhanmu? Yaitu senantiasa berdzikir mengingat Allah." (HR. Tirmidzi)',
        icon: Icons.military_tech_rounded,
        isUnlocked: maxDzikirStreak >= 30,
        progress: (maxDzikirStreak >= 30) ? 1.0 : (currentDzikirStreak / 30).clamp(0.0, 1.0),
        progressLabel: (maxDzikirStreak >= 30)
            ? '30 / 30 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDzikirStreak / 30 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 250,
        rarity: BadgeRarity.legendary,
      ),
      SpiritualBadge(
        id: 'dzikir_streak_365',
        category: 'dzikir',
        title: lang == 'en' ? '1-Year Legendary Dhikr (365 Days)' : 'Istiqomah Dzikir 1 Tahun (365 Hari)',
        description: lang == 'en'
            ? 'Legendary milestone: Recite at least 1 round of dhikr (33x) every single day for 365 consecutive days.'
            : 'Pencapaian agung ahli dzikir: Membaca tasbih minimal 1 putaran (33x) setiap hari selama 365 hari penuh tanpa terlewat.',
        fadhilah: lang == 'en'
            ? '"The men who remember Allah often and the women who do so - for them Allah has prepared forgiveness and a great reward." (Al-Ahzab: 35)'
            : '"Laki-laki dan perempuan yang banyak berdzikir mengingat Allah, Allah sediakan ampunan dan pahala yang besar." (QS. Al-Ahzab: 35)',
        icon: Icons.diamond_rounded,
        isUnlocked: maxDzikirStreak >= 365,
        progress: (maxDzikirStreak >= 365) ? 1.0 : (currentDzikirStreak / 365).clamp(0.0, 1.0),
        progressLabel: (maxDzikirStreak >= 365)
            ? '365 / 365 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDzikirStreak / 365 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 1000,
        rarity: BadgeRarity.legendary,
      ),
      SpiritualBadge(
        id: 'dzikir_round_1',
        category: 'dzikir',
        title: lang == 'en' ? 'Full Tasbih Round' : 'Satu Putaran Penuh',
        description: lang == 'en'
            ? 'Recite 33x tasbih counts in one session.'
            : 'Menyelesaikan 33x butir tasbih dalam satu putaran.',
        fadhilah: lang == 'en'
            ? '33x Subhanallah, Alhamdulillah, Allahu Akbar cleanses the heart and mind.'
            : '33x Subhanallah, Alhamdulillah, dan Allahu Akbar menghapuskan kekeliruan dan menenteramkan jiwa.',
        icon: Icons.all_inclusive_rounded,
        isUnlocked: totalDzikir >= 33,
        progress: (totalDzikir / 33).clamp(0.0, 1.0),
        progressLabel: '${totalDzikir.clamp(0, 33)} / 33',
        pointsReward: 10,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'dzikir_daily_3_rounds',
        category: 'dzikir',
        title: lang == 'en' ? 'Daily Steadfastness' : 'Istiqomah Harian',
        description: lang == 'en'
            ? 'Complete all 3 daily tasbih rounds (99 counts).'
            : 'Menyelesaikan 3 putaran tasbih harian (99 butir).',
        fadhilah: lang == 'en'
            ? '"Whoever glorifies Allah ninety-nine times daily, his sins will be forgiven even if like the foam of the sea." (Muslim)'
            : '"Siapa yang bertasbih, bertahmid, dan bertakbir 99 kali setiap hari, diampuni kesalahannya walau sebanyak buih lautan." (HR. Muslim)',
        icon: Icons.verified_rounded,
        isUnlocked: appState.dailyDzikirRounds >= 3 || totalDzikir >= 99,
        progress: (appState.dailyDzikirRounds / 3).clamp(0.0, 1.0),
        progressLabel: '${appState.dailyDzikirRounds.clamp(0, 3)} / 3 Putaran',
        pointsReward: 20,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'dzikir_monumental_990',
        category: 'dzikir',
        title: lang == 'en' ? 'Sanctuary of 990 Dhikr' : 'Seribu Tasbih',
        description: lang == 'en'
            ? 'Achieve 990x Dhikr (30 full tasbih cycles for 100% garden bloom).'
            : 'Mencapai target monumental 990x Dzikir (30 putaran tasbih penuh).',
        fadhilah: lang == 'en'
            ? '990 tasbih completes 30% contribution to the full 100% landscape sanctuary bloom.'
            : '990x dzikir menyempurnakan 30% kontribusi mekar penuhnya lanskap Taman Surga di homescreen.',
        icon: Icons.spa_rounded,
        isUnlocked: totalDzikir >= 990,
        progress: (totalDzikir / 990).clamp(0.0, 1.0),
        progressLabel: '$totalDzikir / 990 Dzikir',
        pointsReward: 150,
        rarity: BadgeRarity.legendary,
      ),

      // ── DISIPLIN & GHADHUL BASHAR ──
      SpiritualBadge(
        id: 'focus_points_250',
        category: 'focus',
        title: lang == 'en' ? 'Redeemer of Time' : 'Penebus Waktu',
        description: lang == 'en'
            ? 'Accumulate 250 spiritual points through Qur\'an reading & dhikr.'
            : 'Mengumpulkan 250 poin ibadah dari tilawah Al-Qur\'an dan dzikir.',
        fadhilah: lang == 'en'
            ? 'Your good deeds directly unlock balanced app usage quotas.'
            : 'Ibadahmu membuka kuota aplikasi harian secara proporsional dan seimbang.',
        icon: Icons.stars_rounded,
        isUnlocked: points >= 250,
        progress: (points / 250).clamp(0.0, 1.0),
        progressLabel: '${points.clamp(0, 250)} / 250 Poin',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'focus_points_1000',
        category: 'focus',
        title: lang == 'en' ? 'Abundant Rewards' : 'Kolektor Kebaikan',
        description: lang == 'en'
            ? 'Earn 1,000 spiritual points through consistent daily worship.'
            : 'Mengumpulkan 1.000 poin ibadah dari ketekunan harian.',
        fadhilah: lang == 'en'
            ? '"The most beloved deed to Allah is the most regular, even if small." (Bukhari)'
            : '"Amalan yang paling dicintai Allah adalah amalan yang rutin dikerjakan walaupun sedikit." (HR. Bukhari)',
        icon: Icons.diamond_rounded,
        isUnlocked: points >= 1000,
        progress: (points / 1000).clamp(0.0, 1.0),
        progressLabel: '${points.clamp(0, 1000)} / 1000 Poin',
        pointsReward: 150,
        rarity: BadgeRarity.epic,
      ),

      // ── DISIPLIN LAYAR & KENDALI DIRI (STREAK <= 50 POIN/HARI) ──
      SpiritualBadge(
        id: 'focus_streak_3',
        category: 'focus',
        title: lang == 'en' ? '3-Day Screen Discipline' : 'Disiplin Layar 3 Hari',
        description: lang == 'en'
            ? 'Spend at most 50 points daily (max 1 hour non-productive apps) for 3 consecutive days.'
            : 'Maksimal hanya menggunakan 50 poin/hari (1 jam aplikasi non-produktif) selama 3 hari berturut-turut.',
        fadhilah: lang == 'en'
            ? '"Part of the perfection of one\'s Islam is leaving what does not concern him." (Tirmidhi)'
            : '"Di antara kebaikan Islam seseorang adalah meninggalkan hal yang tidak bermanfaat baginya." (HR. Tirmidzi)',
        icon: Icons.timer_rounded,
        isUnlocked: maxDisciplineStreak >= 3,
        progress: (maxDisciplineStreak >= 3) ? 1.0 : (currentDisciplineStreak / 3).clamp(0.0, 1.0),
        progressLabel: (maxDisciplineStreak >= 3)
            ? '3 / 3 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDisciplineStreak / 3 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 20,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'focus_streak_7',
        category: 'focus',
        title: lang == 'en' ? '7-Day Screen Discipline (1 Week)' : 'Disiplin Layar 7 Hari (1 Pekan)',
        description: lang == 'en'
            ? 'Spend at most 50 points daily (max 1 hour non-productive apps) for 7 consecutive days.'
            : 'Maksimal hanya menggunakan 50 poin/hari (1 jam aplikasi non-produktif) selama 7 hari berturut-turut.',
        fadhilah: lang == 'en'
            ? '"Two blessings many people lose: health and free time." (Bukhari)'
            : '"Dua nikmat yang banyak manusia tertipu di dalamnya: kesehatan dan waktu luang." (HR. Bukhari)',
        icon: Icons.bolt_rounded,
        isUnlocked: maxDisciplineStreak >= 7,
        progress: (maxDisciplineStreak >= 7) ? 1.0 : (currentDisciplineStreak / 7).clamp(0.0, 1.0),
        progressLabel: (maxDisciplineStreak >= 7)
            ? '7 / 7 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDisciplineStreak / 7 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'focus_streak_14',
        category: 'focus',
        title: lang == 'en' ? '14-Day Time Guardian (2 Weeks)' : 'Disiplin Layar 14 Hari (2 Pekan)',
        description: lang == 'en'
            ? 'Keep non-productive screen time at or under 1 hour (<= 50 pts/day) for 14 consecutive days.'
            : 'Maksimal hanya menggunakan 50 poin/hari (1 jam aplikasi non-produktif) selama 14 hari berturut-turut.',
        fadhilah: lang == 'en'
            ? '"By time, indeed, mankind is in loss, except for those who believe and do righteous deeds." (Al-\'Asr: 1-3)'
            : '"Demi masa. Sesungguhnya manusia itu benar-benar dalam kerugian, kecuali orang-orang yang beriman dan beramal saleh." (QS. Al-\'Ashr: 1-3)',
        icon: Icons.health_and_safety_rounded,
        isUnlocked: maxDisciplineStreak >= 14,
        progress: (maxDisciplineStreak >= 14) ? 1.0 : (currentDisciplineStreak / 14).clamp(0.0, 1.0),
        progressLabel: (maxDisciplineStreak >= 14)
            ? '14 / 14 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDisciplineStreak / 14 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 100,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'focus_streak_30',
        category: 'focus',
        title: lang == 'en' ? '30-Day Master of Time (1 Month)' : 'Disiplin Layar Sebulan (30 Hari)',
        description: lang == 'en'
            ? 'A full month maintaining at most 50 points/day (1 hour non-productive apps).'
            : 'Sebulan penuh konsisten maksimal hanya menggunakan 50 poin/hari (1 jam aplikasi non-produktif).',
        fadhilah: lang == 'en'
            ? '"Time is like a sword: if you do not cut it, it will cut you." (Imam Shafi\'i)'
            : '"Waktu laksana pedang. Jika engkau tidak memotongnya, maka ia yang akan memotongmu." (Imam Syafi\'i)',
        icon: Icons.military_tech_rounded,
        isUnlocked: maxDisciplineStreak >= 30,
        progress: (maxDisciplineStreak >= 30) ? 1.0 : (currentDisciplineStreak / 30).clamp(0.0, 1.0),
        progressLabel: (maxDisciplineStreak >= 30)
            ? '30 / 30 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDisciplineStreak / 30 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 250,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'focus_streak_60',
        category: 'focus',
        title: lang == 'en' ? '60-Day Self-Mastery (2 Months)' : 'Disiplin Layar 2 Bulan (60 Hari)',
        description: lang == 'en'
            ? 'Two continuous months limiting non-productive app usage to at most 1 hour (<= 50 pts/day).'
            : 'Dua bulan penuh disiplin maksimal hanya menggunakan 50 poin/hari (1 jam aplikasi non-produktif).',
        fadhilah: lang == 'en'
            ? '"The strong man is not the wrestler, but the one who controls himself in desires." (Bukhari)'
            : '"Orang yang perkasa bukanlah yang menang bergulat, melainkan yang mampu mengendalikan hawa nafsunya." (HR. Bukhari)',
        icon: Icons.workspace_premium_rounded,
        isUnlocked: maxDisciplineStreak >= 60,
        progress: (maxDisciplineStreak >= 60) ? 1.0 : (currentDisciplineStreak / 60).clamp(0.0, 1.0),
        progressLabel: (maxDisciplineStreak >= 60)
            ? '60 / 60 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDisciplineStreak / 60 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 500,
        rarity: BadgeRarity.legendary,
      ),
      SpiritualBadge(
        id: 'focus_streak_90',
        category: 'focus',
        title: lang == 'en' ? '90-Day Digital Legend (3 Months)' : 'Legenda Disiplin Layar (90 Hari)',
        description: lang == 'en'
            ? 'Legendary focus milestone: 90 consecutive days using at most 50 points/day (1 hour non-productive apps).'
            : 'Pencapaian legendaris: 90 hari berturut-turut konsisten maksimal hanya menggunakan 50 poin/hari (1 jam aplikasi non-produktif).',
        fadhilah: lang == 'en'
            ? '"Take benefit of five before five: your youth before your old age, health before illness, and free time before preoccupation." (Al-Hakim)'
            : '"Manfaatkan lima perkara sebelum lima perkara: waktu mudamu sebelum tuamu, sehatmu sebelum sakitmu, dan luangmu sebelum sibukmu." (HR. Al-Hakim)',
        icon: Icons.diamond_rounded,
        isUnlocked: maxDisciplineStreak >= 90,
        progress: (maxDisciplineStreak >= 90) ? 1.0 : (currentDisciplineStreak / 90).clamp(0.0, 1.0),
        progressLabel: (maxDisciplineStreak >= 90)
            ? '90 / 90 ${lang == 'en' ? 'Days' : 'Hari'}'
            : '$currentDisciplineStreak / 90 ${lang == 'en' ? 'Days' : 'Hari'}',
        pointsReward: 1000,
        rarity: BadgeRarity.legendary,
      ),
    ].map((b) => SpiritualBadge(
      id: b.id,
      category: b.category,
      title: b.title,
      description: b.description,
      fadhilah: b.fadhilah,
      icon: b.icon,
      isUnlocked: b.isUnlocked,
      isClaimed: appState.isBadgeClaimed(b.id),
      progress: b.progress,
      progressLabel: b.progressLabel,
      pointsReward: b.pointsReward,
      rarity: b.rarity,
    )).toList();
  }

  void _showBadgeDetailModal(BuildContext context, SpiritualBadge badge, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        final rarityColor = _getRarityColor(badge.rarity);

        return Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + MediaQuery.of(ctx).padding.bottom),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Glowing Badge Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: badge.isUnlocked
                        ? [rarityColor.withValues(alpha: 0.25), rarityColor.withValues(alpha: 0.08)]
                        : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHigh],
                  ),
                  border: Border.all(
                    color: badge.isUnlocked ? rarityColor : colorScheme.outlineVariant,
                    width: 2,
                  ),
                  boxShadow: badge.isUnlocked
                      ? [
                          BoxShadow(
                            color: rarityColor.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  badge.icon,
                  size: 38,
                  color: badge.isUnlocked ? rarityColor : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Status
              Text(
                badge.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? const Color(0xFF059669).withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badge.isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                          size: 13,
                          color: badge.isUnlocked ? const Color(0xFF10B981) : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge.isUnlocked
                              ? _t(lang, 'badge_unlocked')
                              : _t(lang, 'badge_in_progress'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked ? const Color(0xFF10B981) : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.rarity.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: rarityColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Fadhilah Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: rarityColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        badge.fadhilah,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t(lang, 'progress_label'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    badge.progressLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: badge.progress,
                  minHeight: 7,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    badge.isUnlocked ? const Color(0xFF10B981) : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reward Status Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: badge.isClaimed
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : (badge.isUnlocked
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: badge.isClaimed
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : (badge.isUnlocked
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                            : colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      badge.isClaimed
                          ? Icons.check_circle_rounded
                          : (badge.isUnlocked ? Icons.stars_rounded : Icons.lock_rounded),
                      size: 18,
                      color: badge.isClaimed
                          ? const Color(0xFF10B981)
                          : (badge.isUnlocked ? const Color(0xFFD97706) : colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        badge.isClaimed
                            ? _t(lang, 'reward_claimed', {'pts': '${badge.pointsReward}'})
                            : (badge.isUnlocked
                                ? _t(lang, 'reward_ready', {'pts': '${badge.pointsReward}'})
                                : _t(lang, 'reward_on_unlock', {'pts': '${badge.pointsReward}'})),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badge.isClaimed
                              ? const Color(0xFF047857)
                              : (badge.isUnlocked ? const Color(0xFFB45309) : colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (badge.isUnlocked) ...[
                if (!badge.isClaimed) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.stars_rounded, size: 20),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final appState = Provider.of<AppState>(context, listen: false);
                        await appState.claimBadgeReward(badge.id, badge.pointsReward, badge.title);
                        HapticFeedback.heavyImpact();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _t(lang, 'claim_badge_success', {'pts': '${badge.pointsReward}', 'title': badge.title}),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF047857),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      label: Text(
                        _t(lang, 'claim_reward_btn', {'pts': '${badge.pointsReward}'}),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Bagikan Sertifikat Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AchievementCertificateDialog.show(
                        context,
                        badge: badge,
                        lang: lang,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    label: Text(
                      Translations.get(lang, 'share_certificate'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      _t(lang, 'close'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _t(lang, 'close'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
    );
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF10B981); // Emerald
      case BadgeRarity.rare:
        return const Color(0xFF0284C7); // Sky Blue
      case BadgeRarity.epic:
        return const Color(0xFF8B5CF6); // Royal Purple
      case BadgeRarity.legendary:
        return const Color(0xFFF59E0B); // Radiant Amber Gold
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    final khatm = appState.khatmCount;
    final completedSurahs = appState.completedSurahsThisCycle.length;
    final totalDzikir = appState.totalDzikirCount;
    final points = appState.points;

    final currentLevel = QuranProgressHelper.getMaqamLevel(khatm);
    final currentTitle = QuranProgressHelper.getMaqamTitle(khatm, lang);

    final combinedProgress = QuranProgressHelper.getCombinedSpiritualProgress(
      khatmCount: khatm,
      currentSurahIndex: appState.currentSurahIndex,
      currentAyahNumber: appState.lastReadAyahNumber,
      quranData: appState.quranData,
      totalDzikirCount: totalDzikir,
    );

    final allBadges = generateBadgesList(appState, lang);
    final filteredBadges = _selectedCategory == 'all'
        ? allBadges
        : allBadges.where((b) => b.category == _selectedCategory).toList();

    final unlockedCount = allBadges.where((b) => b.isUnlocked).length;
    final claimableBadges = allBadges.where((b) => b.isUnlocked && !b.isClaimed).toList();
    final totalClaimablePoints = claimableBadges.fold<int>(0, (sum, b) => sum + b.pointsReward);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: Text(
          _t(lang, 'milestones_badges'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: _t(lang, 'maqam_journey_guide'),
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              QuranProgressHelper.showKhatamLevelInfoModal(context, lang, khatm);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO BANNER: MAQAM SPIRITUAL RANK ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D5C3A), // Deep Islamic Emerald
                    Color(0xFF0F766E), // Teal
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D5C3A).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_t(lang, 'maqam_label')} $currentLevel ${_t(lang, 'maqam_suffix')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => QuranProgressHelper.showKhatamLevelInfoModal(context, lang, khatm),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _t(lang, 'five_levels'),
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right_rounded, color: Colors.amber, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    currentTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    khatm <= 0
                        ? _t(lang, 'towards_khatam_1_desc')
                        : _t(lang, 'khatam_completed_desc', {'n': '$khatm'}),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Active Maqam Point Boost Banner
                  InkWell(
                    onTap: () => QuranProgressHelper.showKhatamLevelInfoModal(context, lang, khatm),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (khatm > 0 ? Colors.amber : Colors.white).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 18,
                            color: khatm > 0 ? Colors.amber : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  khatm <= 0
                                      ? _t(lang, 'boost_standard')
                                      : _t(lang, 'boost_active', {'pct': '${appState.maqamBoostPercent}', 'lvl': '$currentLevel'}),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: khatm > 0 ? Colors.amber : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  khatm <= 0
                                      ? _t(lang, 'boost_hint_unlock')
                                      : _t(lang, 'boost_hint_active'),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Combined Sanctuary Bloom Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _t(lang, 'sanctuary_bloom'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(combinedProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: combinedProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── QUICK STAT COUNTERS ──
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(
                    context: context,
                    icon: Icons.workspace_premium_rounded,
                    value: '${khatm}x',
                    label: lang == 'en' ? 'Khatam' : 'Khatam',
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatBox(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    value: '$completedSurahs/114',
                    label: lang == 'en' ? 'Surahs' : 'Surah',
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatBox(
                    context: context,
                    icon: Icons.grain_rounded,
                    value: '$totalDzikir',
                    label: lang == 'en' ? 'Dhikr' : 'Dzikir',
                    color: Colors.indigo.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatBox(
                    context: context,
                    icon: Icons.stars_rounded,
                    value: '$points',
                    label: lang == 'en' ? 'Points' : 'Poin',
                    color: const Color(0xFF047857),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── DAILY TILAWAH STREAK BANNER ──
            _buildStreakCard(context, appState, lang),

            if (claimableBadges.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildClaimAllBanner(context, appState, claimableBadges, totalClaimablePoints, lang),
            ],

            const SizedBox(height: 24),

            // ── CATEGORY FILTER PILLS ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _t(lang, 'lifetime_badges'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$unlockedCount / ${allBadges.length} ${_t(lang, 'earned_count')}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCategoryFilterPill('all', '${_t(lang, 'all_filter')} (${allBadges.length})'),
                  const SizedBox(width: 8),
                  _buildCategoryFilterPill('quran', 'Al-Qur\'an'),
                  const SizedBox(width: 8),
                  _buildCategoryFilterPill('dzikir', 'Dzikir'),
                  const SizedBox(width: 8),
                  _buildCategoryFilterPill('focus', _t(lang, 'focus_filter')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── BADGE CARDS LIST ──
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredBadges.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                return _buildBadgeCard(context, badge, lang, appState);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isQuran = _streakTab == 'quran';

    final currentStreak = isQuran ? appState.quranDailyStreak : appState.dzikirDailyStreak;
    final maxStreak = isQuran ? appState.maxQuranDailyStreak : appState.maxDzikirDailyStreak;

    // Milestones: 1, 3, 7, 14, 30, 365
    final int nextTarget = currentStreak < 1
        ? 1
        : (currentStreak < 3
            ? 3
            : (currentStreak < 7
                ? 7
                : (currentStreak < 14
                    ? 14
                    : (currentStreak < 30
                        ? 30
                        : (currentStreak < 365 ? 365 : currentStreak + 30)))));
    final double targetProgress = (currentStreak / nextTarget).clamp(0.0, 1.0);

    final Color accentColor = isQuran ? const Color(0xFFF97316) : const Color(0xFF6366F1);
    final Color darkAccent = isQuran ? const Color(0xFFEA580C) : const Color(0xFF4F46E5);
    final Color textColor = isQuran ? const Color(0xFFC2410C) : const Color(0xFF4338CA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: darkAccent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Switcher between Tilawah and Dzikir
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_streakTab != 'quran') {
                        setState(() => _streakTab = 'quran');
                      } else {
                        _openQuran(appState);
                      }
                    },
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isQuran ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: isQuran
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 14, color: Color(0xFFEA580C)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _t(lang, 'streak_tab_tilawah', {'n': '${appState.quranDailyStreak}'}),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isQuran ? FontWeight.bold : FontWeight.w500,
                                color: isQuran ? const Color(0xFFC2410C) : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_streakTab != 'dzikir') {
                        setState(() => _streakTab = 'dzikir');
                      } else {
                        _openDzikir();
                      }
                    },
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !isQuran ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: !isQuran
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.grain_rounded, size: 14, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              _t(lang, 'streak_tab_dzikir', {'n': '${appState.dzikirDailyStreak}'}),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: !isQuran ? FontWeight.bold : FontWeight.w500,
                                color: !isQuran ? const Color(0xFF4338CA) : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tappable Streak Details (Opens Quran for Tilawah, Dzikir for Dzikir)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isQuran ? () => _openQuran(appState) : () => _openDzikir(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor, darkAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: darkAccent.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isQuran ? Icons.local_fire_department_rounded : Icons.flare_rounded,
                            color: Colors.white,
                            size: 22,
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
                                  Expanded(
                                    child: Text(
                                      isQuran
                                          ? _t(lang, 'streak_daily_tilawah')
                                          : _t(lang, 'streak_daily_dzikir'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isQuran
                                          ? _t(lang, 'streak_best', {'n': '$maxStreak'})
                                          : _t(lang, 'streak_best', {'n': '$maxStreak'}),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: darkAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentStreak > 0
                                    ? '${_t(lang, 'streak_days_row', {'n': '$currentStreak', 's': currentStreak > 1 ? 's' : ''})} ${isQuran ? "🔥" : "✨"}'
                                    : (isQuran
                                        ? _t(lang, 'streak_start_today_quran')
                                        : _t(lang, 'streak_start_today_dzikir')),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _t(lang, 'streak_target', {'n': '$nextTarget'}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$currentStreak / $nextTarget ${_t(lang, 'streak_days')}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: targetProgress,
                        minHeight: 6,
                        backgroundColor: accentColor.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(darkAccent),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Action CTA Bar
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                      decoration: BoxDecoration(
                        color: darkAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: darkAccent.withValues(alpha: 0.22),
                          width: 1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isQuran ? Icons.menu_book_rounded : Icons.grain_rounded,
                              size: 15,
                              color: darkAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isQuran
                                  ? _t(lang, 'streak_open_quran')
                                  : _t(lang, 'streak_open_dzikir'),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: darkAccent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: darkAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Streak Daily Reminder Toggle Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        appState.isStreakReminderEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 16,
                        color: appState.isStreakReminderEnabled
                            ? darkAccent
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t(lang, 'daily_reminder_title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _t(lang, 'daily_reminder_desc'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: appState.isStreakReminderEnabled,
                    activeThumbColor: darkAccent,
                    onChanged: (val) async {
                      if (val) {
                        await StreakNotificationService.requestPermission();
                      }
                      await appState.setStreakReminderEnabled(val);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterPill(String key, String title) {
    final isSelected = _selectedCategory == key;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildClaimAllBanner(
    BuildContext context,
    AppState appState,
    List<SpiritualBadge> claimableBadges,
    int totalClaimablePoints,
    String lang,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.redeem_rounded,
              color: Colors.amber,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  claimableBadges.length > 1
                      ? _t(lang, 'badges_ready_to_claim', {'n': '${claimableBadges.length}', 's': ''})
                      : _t(lang, 'badges_ready_to_claim', {'n': '${claimableBadges.length}', 's': ''}),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _t(lang, 'total_claimable', {'pts': '$totalClaimablePoints'}),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final payload = claimableBadges.map((b) => {
                'id': b.id,
                'points': b.pointsReward,
                'title': b.title,
              }).toList();
              final claimed = await appState.claimAllBadgeRewards(payload);
              HapticFeedback.heavyImpact();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _t(lang, 'claim_all_success', {'pts': '$claimed', 'n': '${claimableBadges.length}'}),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF047857),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _t(lang, 'claim_all'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, SpiritualBadge badge, String lang, AppState appState) {
    final colorScheme = Theme.of(context).colorScheme;
    final rarityColor = _getRarityColor(badge.rarity);

    return InkWell(
      onTap: () => _showBadgeDetailModal(context, badge, lang),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badge.isUnlocked
                ? rarityColor.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: badge.isUnlocked ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: badge.isUnlocked
                  ? rarityColor.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Badge Icon Circle (Proportional 46x46)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: badge.isUnlocked
                      ? [rarityColor.withValues(alpha: 0.20), rarityColor.withValues(alpha: 0.08)]
                      : [colorScheme.surfaceContainerHighest.withValues(alpha: 0.6), colorScheme.surfaceContainerHigh.withValues(alpha: 0.3)],
                ),
                border: Border.all(
                  color: badge.isUnlocked
                      ? rarityColor
                      : colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Icon(
                badge.icon,
                size: 24,
                color: badge.isUnlocked
                    ? rarityColor
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row: Title + Status/Reward Pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          badge.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (badge.isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                              const SizedBox(width: 3),
                              Text(
                                _t(lang, 'badge_unlocked'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars_rounded, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                '+${badge.pointsReward}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Middle: Description
                  Text(
                    badge.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bottom Row: Progress Bar + Progress Label / Claim Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: badge.progress,
                            minHeight: 5,
                            backgroundColor: badge.isUnlocked
                                ? const Color(0xFF10B981).withValues(alpha: 0.18)
                                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              badge.isUnlocked ? const Color(0xFF10B981) : rarityColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (badge.isUnlocked && !badge.isClaimed)
                        InkWell(
                          onTap: () async {
                            await appState.claimBadgeReward(badge.id, badge.pointsReward, badge.title);
                            HapticFeedback.mediumImpact();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _t(lang, 'claim_badge_success', {'pts': '${badge.pointsReward}', 'title': badge.title}),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF047857),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, size: 11, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  _t(lang, 'claim_pts', {'pts': '${badge.pointsReward}'}),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          badge.progressLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: badge.isUnlocked
                                ? const Color(0xFF10B981)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
