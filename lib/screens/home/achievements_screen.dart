import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/quran_progress_helper.dart';
import '../../services/analytics_service.dart';

enum BadgeRarity { common, rare, epic, legendary }

class SpiritualBadge {
  final String id;
  final String category; // 'quran', 'dzikir', 'focus'
  final String title;
  final String description;
  final String fadhilah;
  final IconData icon;
  final bool isUnlocked;
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
    required this.progress,
    required this.progressLabel,
    required this.pointsReward,
    required this.rarity,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'all'; // 'all', 'quran', 'dzikir', 'focus'

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('AchievementsScreen');
  }

  List<SpiritualBadge> _generateBadges(AppState appState, String lang) {
    final khatm = appState.khatmCount;
    final completedSurahs = appState.completedSurahsThisCycle.length;
    final totalDzikir = appState.totalDzikirCount;
    final points = appState.points;
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
        pointsReward: 25,
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
        pointsReward: 75,
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
        pointsReward: 50,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'quran_maqam_2',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 2 • Al-Mubtadi\' Al-Karim'
            : 'Tingkat 2 • Al-Mubtadi\' Al-Karim',
        description: lang == 'en'
            ? '1x Khatam (6,236 Verses): Successfully reciting all 30 Juz from Al-Fatihah to An-Nas.'
            : '1x Khatam (6.236 Ayat): Berhasil menuntaskan seluruh 30 Juz Al-Qur\'an dari Al-Fatihah hingga An-Nas.',
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
            : 'Tingkat 3 • Sahabat Al-Qur\'an',
        description: lang == 'en'
            ? '2x Khatam: The Holy Qur\'an becomes a cherished companion in your daily life.'
            : '2x Khatam: Al-Qur\'an telah menjadi sahabat karib penyejuk hati di setiap waktu luang dan keseharian.',
        fadhilah: lang == 'en'
            ? '"Read the Qur\'an, for it will come on the Day of Resurrection as an intercessor for its companions." (Muslim)'
            : '"Bacalah Al-Qur\'an, sesungguhnya ia akan datang pada hari kiamat sebagai pemberi syafa\'at bagi para sahabatnya." (HR. Muslim)',
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
            : 'Tingkat 4 • Penjaga Cahaya',
        description: lang == 'en'
            ? '3–4x Khatam: Steady rhythm protecting your time and heart from digital distractions.'
            : '3–4x Khatam: Ritme tilawah semakin kokoh dan menjadi perisai jiwa dari distraksi digital yang melalaikan.',
        fadhilah: lang == 'en'
            ? '"The one who is proficient in the recitation of the Qur\'an will be with the noble, obedient angels." (Bukhari & Muslim)'
            : '"Orang yang mahir dan istiqomah membaca Al-Qur\'an kelak bersama para malaikat yang mulia lagi taat." (HR. Bukhari & Muslim)',
        icon: Icons.shield_rounded,
        isUnlocked: khatm >= 3,
        progress: (khatm / 3).clamp(0.0, 1.0),
        progressLabel: '$khatm / 3 Khatam',
        pointsReward: 1500,
        rarity: BadgeRarity.epic,
      ),
      SpiritualBadge(
        id: 'quran_maqam_5',
        category: 'quran',
        title: lang == 'en'
            ? 'Level 5 • Ahlul Qur\'an Al-Mubarok'
            : 'Tingkat 5 • Ahlul Qur\'an Al-Mubarok',
        description: lang == 'en'
            ? '5x+ Khatam: The summit of lifelong devotion living with divine guidance every day.'
            : '5x+ Khatam: Puncak kemuliaan insan yang senantiasa hidup, membaca, dan mengamalkan kalam Ilahi setiap harinya.',
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
            : 'Memulai zikir tasbih pertama kali.',
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
        pointsReward: 19,
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
        pointsReward: 300,
        rarity: BadgeRarity.legendary,
      ),

      // ── DISIPLIN & GHADHUL BASHAR ──
      SpiritualBadge(
        id: 'focus_guardian',
        category: 'focus',
        title: lang == 'en' ? 'Guardian of Gaze' : 'Penjaga Pandangan',
        description: lang == 'en'
            ? 'Active protective barrier guarding vision from harmful digital content.'
            : 'Pelindung aktif dari paparan konten digital yang melalaikan.',
        fadhilah: lang == 'en'
            ? '"Tell the believing men to lower their gaze and guard their modesty." (An-Nur: 30)'
            : '"Katakanlah kepada orang laki-laki yang beriman: Hendaklah mereka menahan pandangannya, dan memelihara kemaluannya." (QS. An-Nur: 30)',
        icon: Icons.visibility_rounded,
        isUnlocked: appState.hasSeenAccessibilitySetup || points > 0,
        progress: (appState.hasSeenAccessibilitySetup || points > 0) ? 1.0 : 0.0,
        progressLabel: (appState.hasSeenAccessibilitySetup || points > 0)
            ? 'Aktif'
            : 'Siap',
        pointsReward: 15,
        rarity: BadgeRarity.common,
      ),
      SpiritualBadge(
        id: 'focus_shield',
        category: 'focus',
        title: lang == 'en' ? 'Digital Fortress' : 'Benteng Digital',
        description: lang == 'en'
            ? 'Block distracting or time-wasting apps to safeguard worship time.'
            : 'Memilih dan memblokir aplikasi adiktif untuk menjaga fokus ibadah.',
        fadhilah: lang == 'en'
            ? 'Controlling screen time gives you hours of real blessings and focus.'
            : 'Mengendalikan waktu layar menyelamatkan ratusan jam berharga untuk hal yang bermanfaat.',
        icon: Icons.shield_rounded,
        isUnlocked: appState.blockedApps.isNotEmpty,
        progress: appState.blockedApps.isNotEmpty ? 1.0 : 0.0,
        progressLabel: '${appState.blockedApps.length} Aplikasi',
        pointsReward: 20,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'focus_points_50',
        category: 'focus',
        title: lang == 'en' ? 'Redeemer of Time' : 'Penebus Waktu',
        description: lang == 'en'
            ? 'Accumulate 50 spiritual points through Qur\'an reading & dhikr.'
            : 'Mengumpulkan 50 poin ibadah dari tilawah Al-Qur\'an dan zikir.',
        fadhilah: lang == 'en'
            ? 'Your good deeds directly unlock balanced app usage quotas.'
            : 'Ibadahmu membuka kuota aplikasi harian secara proporsional dan seimbang.',
        icon: Icons.stars_rounded,
        isUnlocked: points >= 50,
        progress: (points / 50).clamp(0.0, 1.0),
        progressLabel: '${points.clamp(0, 50)} / 50 Poin',
        pointsReward: 50,
        rarity: BadgeRarity.rare,
      ),
      SpiritualBadge(
        id: 'focus_points_500',
        category: 'focus',
        title: lang == 'en' ? 'Abundant Rewards' : 'Kolektor Kebaikan',
        description: lang == 'en'
            ? 'Earn 500 spiritual points through consistent daily worship.'
            : 'Mengumpulkan 500 poin ibadah dari ketekunan harian.',
        fadhilah: lang == 'en'
            ? '"The most beloved deed to Allah is the most regular, even if small." (Bukhari)'
            : '"Amalan yang paling dicintai Allah adalah amalan yang rutin dikerjakan walaupun sedikit." (HR. Bukhari)',
        icon: Icons.diamond_rounded,
        isUnlocked: points >= 500,
        progress: (points / 500).clamp(0.0, 1.0),
        progressLabel: '${points.clamp(0, 500)} / 500 Poin',
        pointsReward: 200,
        rarity: BadgeRarity.epic,
      ),
    ];
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
                              ? (lang == 'en' ? 'Unlocked' : 'Tercapai')
                              : (lang == 'en' ? 'In Progress' : 'Dalam Proses'),
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
                    lang == 'en' ? 'Progress' : 'Progres',
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
              const SizedBox(height: 24),

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
                    lang == 'en' ? 'Close' : 'Tutup',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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

    final allBadges = _generateBadges(appState, lang);
    final filteredBadges = _selectedCategory == 'all'
        ? allBadges
        : allBadges.where((b) => b.category == _selectedCategory).toList();

    final unlockedCount = allBadges.where((b) => b.isUnlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      appBar: AppBar(
        title: Text(
          lang == 'en' ? 'Milestones & Badges' : 'Pencapaian & Lencana',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            tooltip: lang == 'en' ? 'Maqam Journey Guide' : 'Panduan Tingkatan Maqam',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                            Text(
                              'TINGKAT $currentLevel • MAQAM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '5 Tingkat',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.chevron_right_rounded, color: Colors.amber, size: 14),
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
                        ? (lang == 'en'
                            ? 'Steadfast on the path towards completing the 1st Khatam'
                            : 'Sedang berproses dengan sabar menuju Khatam ke-1')
                        : (lang == 'en'
                            ? 'Alhamdulillah, completed $khatm Khatam cycles'
                            : 'Alhamdulillah, telah menuntaskan $khatm kali Khatam 30 Juz'),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Combined Sanctuary Bloom Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == 'en' ? 'Sanctuary Bloom Progress' : 'Mekarnya Taman Surga',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
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
            const SizedBox(height: 24),

            // ── CATEGORY FILTER PILLS ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang == 'en' ? 'LIFETIME BADGES' : 'LENCANA PENCAPAIAN',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$unlockedCount / ${allBadges.length} ${lang == 'en' ? 'Earned' : 'Diraih'}',
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
                  _buildCategoryFilterPill('all', lang == 'en' ? 'All (${allBadges.length})' : 'Semua (${allBadges.length})'),
                  const SizedBox(width: 8),
                  _buildCategoryFilterPill('quran', lang == 'en' ? 'Al-Qur\'an' : 'Al-Qur\'an'),
                  const SizedBox(width: 8),
                  _buildCategoryFilterPill('dzikir', lang == 'en' ? 'Dzikir' : 'Dzikir'),
                  const SizedBox(width: 8),
                  _buildCategoryFilterPill('focus', lang == 'en' ? 'Focus & Screen Time' : 'Disiplin & Fokus'),
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
                return _buildBadgeCard(context, badge, lang);
              },
            ),
          ],
        ),
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
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: colorScheme.onSurfaceVariant,
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

  Widget _buildBadgeCard(BuildContext context, SpiritualBadge badge, String lang) {
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
          children: [
            // Badge Icon Circle
            Container(
              width: 50,
              height: 50,
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
                size: 26,
                color: badge.isUnlocked
                    ? rarityColor
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          badge.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badge.isUnlocked
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge.isUnlocked
                              ? (lang == 'en' ? 'Earned' : 'Tercapai')
                              : badge.progressLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badge.isUnlocked
                                ? const Color(0xFF10B981)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    badge.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      minHeight: 4.5,
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        badge.isUnlocked ? const Color(0xFF10B981) : rarityColor,
                      ),
                    ),
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
