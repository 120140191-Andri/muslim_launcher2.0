import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/milestone_share_card.dart';
import '../../widgets/milestone_celebration_dialog.dart';
import '../../utils/translations.dart';
import '../../utils/page_transitions.dart';
import '../quran/surah_detail_screen.dart';

class MilestoneGalleryScreen extends StatefulWidget {
  const MilestoneGalleryScreen({super.key});

  @override
  State<MilestoneGalleryScreen> createState() => _MilestoneGalleryScreenState();
}

class _MilestoneGalleryScreenState extends State<MilestoneGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = appState.languageCode;
    final maqam = appState.currentMaqamRank;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          Translations.get(lang, 'milestone_gallery_title'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 2,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: maqam.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: maqam.primaryColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(maqam.crownEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${appState.khatmCount}x Khatam',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: maqam.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildMaqamHeader(context, appState, maqam, lang),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _GalleryTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF10B981),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF10B981),
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  tabs: [
                    Tab(text: Translations.get(lang, 'tab_all')),
                    Tab(text: Translations.get(lang, 'tab_quran')),
                    Tab(text: Translations.get(lang, 'tab_dzikir')),
                    Tab(text: Translations.get(lang, 'tab_khatam')),
                  ],
                ),
                colorScheme.surface,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(context, appState, lang),
            _buildQuranTab(context, appState, lang),
            _buildDzikirTab(context, appState, lang),
            _buildKhatamTab(context, appState, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildMaqamHeader(
    BuildContext context,
    AppState appState,
    MaqamInfo maqam,
    String lang,
  ) {
    final completedCount = appState.completedSurahsThisCycle.length;
    final progressRatio = (completedCount / 114.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: maqam.primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      maqam.primaryColor.withValues(alpha: 0.3),
                      maqam.primaryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: maqam.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    maqam.crownEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get(lang, 'spiritual_maqam_badge'),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: maqam.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maqam.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maqam.description,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress of current Khatam Cycle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${Translations.get(lang, 'khatam_cycle_progress')}: ${appState.khatmCount + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completedCount / 114 Surah',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ───────────────────────────────────────────────────────
  Widget _buildOverviewTab(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final completedCount = appState.completedSurahsThisCycle.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                title: Translations.get(lang, 'stat_surahs_done'),
                value: '$completedCount',
                unit: '/ 114',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                title: Translations.get(lang, 'stat_khatam_count'),
                value: '${appState.khatmCount}',
                unit: 'x',
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                title: Translations.get(lang, 'stat_blessing_points'),
                value: '${appState.points}',
                unit: 'pts',
                icon: Icons.auto_awesome_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Featured Khatam Certificate Banner
        _buildFeaturedKhatamCard(context, appState, lang),

        const SizedBox(height: 18),

        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                Translations.get(lang, 'recent_unlocked_badges'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text(Translations.get(lang, 'view_all_114')),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal list of unlocked / milestone surahs
        _buildRecentBadgesList(context, appState, lang),

        const SizedBox(height: 20),

        // Dzikir Achievements Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                Translations.get(lang, 'dzikir_milestones'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(2),
              child: Text(Translations.get(lang, 'view_dzikir')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildDzikirPreviewRow(context, appState, lang),
      ],
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedKhatamCard(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final bool hasKhatam = appState.khatmCount > 0;
    final int currentJuz = appState.currentJuzNumber;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2E1C0C),
            Color(0xFF1A1006),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF1A1006),
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.get(lang, 'gold_khatam_certificate'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasKhatam
                      ? Translations.get(lang, 'khatam_certified_desc')
                      : '${Translations.get(lang, 'khatam_on_progress')}: Juz $currentJuz / 30',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showKhatamCardDialog(context, appState, lang);
                    },
                    icon: const Icon(Icons.share_rounded, size: 14),
                    label: Text(
                      Translations.get(lang, 'open_share_card'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF1A1006),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBadgesList(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    if (appState.quranData.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: Text(
            Translations.get(lang, 'setup_loading_apps'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    // Show surahs completed or first 5 surahs
    final completedSet = appState.completedSurahsThisCycle;
    final List<dynamic> displaySurahs = [];

    for (final s in appState.quranData) {
      final num = s['surah_number'] as int? ?? 1;
      if (completedSet.contains(num) || displaySurahs.length < 5) {
        displaySurahs.add(s);
      }
      if (displaySurahs.length >= 8) break;
    }

    return SizedBox(
      height: 124,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: displaySurahs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final surah = displaySurahs[index];
          final num = surah['surah_number'] as int? ?? 1;
          final isUnlocked = completedSet.contains(num) || appState.khatmCount > 0;
          return _buildMiniBadgeCard(context, appState, surah, isUnlocked, lang);
        },
      ),
    );
  }

  Widget _buildMiniBadgeCard(
    BuildContext context,
    AppState appState,
    dynamic surah,
    bool isUnlocked,
    String lang,
  ) {
    final num = surah['surah_number'] as int? ?? 1;
    final name = surah['surah_name'] as String? ?? '';
    final totalAyahs = surah['total_ayah'] as int? ?? 1;
    final tier = AppState.getSurahTier(totalAyahs);
    final points = AppState.getSurahBonusPoints(totalAyahs, surahNumber: num);

    return InkWell(
      onTap: () {
        if (isUnlocked) {
          _showSurahCardDialog(context, appState, surah, lang);
        } else {
          _showLockedSurahSheet(context, appState, surah, lang);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 125,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUnlocked
              ? const Color(0xFF10B981).withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'T$tier • +$points',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isUnlocked
                      ? Icons.verified_rounded
                      : Icons.lock_outline_rounded,
                  size: 16,
                  color: isUnlocked ? const Color(0xFF10B981) : Colors.grey,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$totalAyahs Ayat',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDzikirPreviewRow(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildDzikirMilestoneCard(
            context,
            appState,
            title: 'Subhanallah',
            arabic: 'سُبْحَانَ اللَّهِ',
            count: 33,
            label: 'Putaran 1 Sunnah',
            isUnlocked: appState.dailyDzikirRounds >= 1,
            lang: lang,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDzikirMilestoneCard(
            context,
            appState,
            title: 'Alhamdulillah',
            arabic: 'الْحَمْدُ لِلَّهِ',
            count: 66,
            label: 'Putaran 2 Sunnah',
            isUnlocked: appState.dailyDzikirRounds >= 2,
            lang: lang,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDzikirMilestoneCard(
            context,
            appState,
            title: 'Allahu Akbar',
            arabic: 'اللَّهُ أَكْبَرُ',
            count: 99,
            label: 'Putaran 3 Purna',
            isUnlocked: appState.dailyDzikirRounds >= 3,
            lang: lang,
          ),
        ),
      ],
    );
  }

  Widget _buildDzikirMilestoneCard(
    BuildContext context,
    AppState appState, {
    required String title,
    required String arabic,
    required int count,
    required String label,
    required bool isUnlocked,
    required String lang,
  }) {
    return InkWell(
      onTap: () {
        _showDzikirCardDialog(
          context,
          appState,
          title: title,
          arabic: arabic,
          count: count,
          label: label,
          lang: lang,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            Text(
              arabic,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F766E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${count}x',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9.5, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Al-Qur'an 114 Surahs ──────────────────────────────────────────
  Widget _buildQuranTab(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    if (appState.quranData.isEmpty) {
      return Center(
        child: Text(
          Translations.get(lang, 'setup_loading_apps'),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    final completedSet = appState.completedSurahsThisCycle;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: appState.quranData.length,
      itemBuilder: (context, index) {
        final surah = appState.quranData[index];
        final num = surah['surah_number'] as int? ?? (index + 1);
        final name = surah['surah_name'] as String? ?? 'Surah $num';
        final totalAyahs = surah['total_ayah'] as int? ?? 1;
        final isCompletedInCycle = completedSet.contains(num);
        final isUnlocked = isCompletedInCycle || appState.khatmCount > 0;
        final tier = AppState.getSurahTier(totalAyahs);
        final bonus = AppState.getSurahBonusPoints(totalAyahs, surahNumber: num);

        return InkWell(
          onTap: () {
            if (isUnlocked) {
              _showSurahCardDialog(context, appState, surah, lang);
            } else {
              _showLockedSurahSheet(context, appState, surah, lang);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isUnlocked
                    ? const Color(0xFF10B981).withValues(alpha: 0.45)
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: isUnlocked ? 1.5 : 1.0,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFF10B981)
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$num',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : colorScheme.outlineVariant.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'T$tier • +$bonus',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? const Color(0xFF10B981)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnlocked)
                          const Icon(
                            Icons.share_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$totalAyahs ${Translations.get(lang, 'ayah')}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Tab 3: Dzikir Milestones ─────────────────────────────────────────────
  Widget _buildDzikirTab(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dzikirPresets = [
      {
        'title': 'Subhanallah',
        'arabic': 'سُبْحَانَ اللَّهِ',
        'subtitle': 'Maha Suci Allah',
        'target': 33,
        'round': 'Putaran 1 Sunnah (+3 Pts)',
        'virtue': 'Menghapus dosa-dosa kecil laksana buih di lautan.',
        'source': '(HR. Muslim)',
        'isUnlocked': appState.dailyDzikirRounds >= 1,
      },
      {
        'title': 'Alhamdulillah',
        'arabic': 'الْحَمْدُ لِلَّهِ',
        'subtitle': 'Segala Puji Bagi Allah',
        'target': 66,
        'round': 'Putaran 2 Sunnah (+3 Pts)',
        'virtue': 'Memenuhi timbangan amal kebaikan di hari kiamat.',
        'source': '(HR. Muslim)',
        'isUnlocked': appState.dailyDzikirRounds >= 2,
      },
      {
        'title': 'Allahu Akbar',
        'arabic': 'اللَّهُ أَكْبَرُ',
        'subtitle': 'Allah Maha Besar',
        'target': 99,
        'round': 'Putaran 3 Purna (+13 Pts Bonus)',
        'virtue': 'Mengagungkan asma Allah yang tiada tandingannya.',
        'source': '(HR. Muslim)',
        'isUnlocked': appState.dailyDzikirRounds >= 3,
      },
      {
        'title': 'La Ilaha Illallah Wahdahu...',
        'arabic': 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
        'subtitle': 'Penyempurna 100x Dzikir',
        'target': 100,
        'round': 'Penyempurna Seratus',
        'virtue': 'Diberi pahala semisal memerdekakan sepuluh budak.',
        'source': '(HR. Bukhari & Muslim)',
        'isUnlocked': appState.dailyDzikirRounds >= 3,
      },
      {
        'title': 'Sayyidul Istighfar',
        'arabic': 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ',
        'subtitle': 'Penghulu Segala Istighfar',
        'target': 100,
        'round': 'Dzikir Pagi & Petang',
        'virtue': 'Barangsiapa membacanya dengan yakin lalu meninggal, ia termasuk penghuni surga.',
        'source': '(HR. Bukhari)',
        'isUnlocked': true,
      },
      {
        'title': 'Istighfar Akbar 1000x',
        'arabic': 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
        'subtitle': 'Pembersih Jiwa & Pengetuk Pintu Rezeki',
        'target': 1000,
        'round': 'Pencapaian Ruhani Akbar',
        'virtue': 'Barangsiapa memperbanyak istighfar, Allah berikan jalan keluar dari setiap kesempitan.',
        'source': '(HR. Abu Dawud)',
        'isUnlocked': appState.points >= 500,
      },
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: dzikirPresets.length,
      itemBuilder: (context, index) {
        final item = dzikirPresets[index];
        final isUnlocked = item['isUnlocked'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked
                  ? const Color(0xFF0F766E).withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showDzikirCardDialog(
                  context,
                  appState,
                  title: item['title'] as String,
                  arabic: item['arabic'] as String,
                  count: item['target'] as int,
                  label: item['round'] as String,
                  quote: item['virtue'] as String,
                  quoteSource: item['source'] as String,
                  lang: lang,
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFF0F766E),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${item['target']}x • ${item['round']}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.share_rounded,
                                size: 16,
                                color: Color(0xFF0F766E),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['arabic'] as String,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Tab 4: Khatam 30 Juz ─────────────────────────────────────────────────
  Widget _buildKhatamTab(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final khatmCount = appState.khatmCount;
    final currentJuz = appState.currentJuzNumber;
    final percent = appState.khatamProgressPercent;
    final phase = appState.currentKhatamPhase;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Royal Certificate Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF261907),
                Color(0xFF140D04),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF140D04),
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SERTIFIKAT KHATAM 30 JUZ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFFFFD700),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Maha Benar Allah dengan Segala Firman-Nya',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Total Selesai: $khatmCount Kali Khatam',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showKhatamCardDialog(context, appState, lang);
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Bagikan Sertifikat Emas 9:16',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF140D04),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Active Journey Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perjalanan Khatam Saat Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phase.nameId,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Juz $currentJuz / 30',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: currentJuz / 30.0,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Dialog & Sheet Helpers ───────────────────────────────────────────────

  void _showSurahCardDialog(
    BuildContext context,
    AppState appState,
    dynamic surah,
    String lang,
  ) {
    final num = surah['surah_number'] as int? ?? 1;
    final name = surah['surah_name'] as String? ?? 'Surah $num';
    final totalAyahs = surah['total_ayah'] as int? ?? 1;
    final points = AppState.getSurahBonusPoints(totalAyahs, surahNumber: num);
    final khatamProgressJuz = AppState.getJuzForSurahAndAyah(num, 1);

    MilestoneCelebrationDialog.show(
      context,
      data: MilestoneCardData(
        type: MilestoneCardType.surah,
        title: name,
        subtitle: 'Menuntaskan $totalAyahs Ayat Al-Qur\'an',
        surahNumber: num,
        ayahCount: totalAyahs,
        durationMinutes: 15,
        userName: appState.userName,
        khatamProgressJuz: khatamProgressJuz,
        khatamCount: appState.khatmCount,
        dateStr: DateFormat('d MMMM yyyy').format(DateTime.now()),
        bonusPoints: points,
        quote: num == 18
            ? 'Barangsiapa membaca Surah Al-Kahfi di hari Jumat, maka akan dipancarkan cahaya baginya...'
            : 'Bacalah Al-Qur\'an, sesungguhnya ia akan datang di hari kiamat sebagai pemberi syafaat.',
        quoteSource: num == 18 ? '(HR. Hakim & Baihaqi)' : '(HR. Muslim)',
      ),
    );
  }

  void _showLockedSurahSheet(
    BuildContext context,
    AppState appState,
    dynamic surah,
    String lang,
  ) {
    final num = surah['surah_number'] as int? ?? 1;
    final name = surah['surah_name'] as String? ?? 'Surah $num';
    final totalAyahs = surah['total_ayah'] as int? ?? 1;
    final points = AppState.getSurahBonusPoints(totalAyahs, surahNumber: num);
    final tier = AppState.getSurahTier(totalAyahs);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalAyahs Ayat • Tier $tier (+ $points Poin)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                Translations.get(lang, 'surah_locked_milestone_notice'),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    appState.navigatorKey.currentState?.push(
                      AppPageRoute(
                        child: SurahDetailScreen(surah: surah),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(Translations.get(lang, 'read_now')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  void _showDzikirCardDialog(
    BuildContext context,
    AppState appState, {
    required String title,
    required String arabic,
    required int count,
    required String label,
    String? quote,
    String? quoteSource,
    required String lang,
  }) {
    MilestoneCelebrationDialog.show(
      context,
      data: MilestoneCardData(
        type: MilestoneCardType.dzikir,
        title: title,
        arabicTitle: arabic,
        subtitle: label,
        ayahCount: count,
        durationMinutes: 5,
        userName: appState.userName,
        dateStr: DateFormat('d MMMM yyyy').format(DateTime.now()),
        bonusPoints: 10,
        quote: quote ?? 'Dzikir adalah penenang hati dan pelindung dari marabahaya.',
        quoteSource: quoteSource ?? '(Keutamaan Dzikir)',
      ),
    );
  }

  void _showKhatamCardDialog(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    MilestoneCelebrationDialog.show(
      context,
      data: MilestoneCardData(
        type: MilestoneCardType.khatam,
        title: 'Khatam 30 Juz Al-Qur\'an',
        subtitle: 'Maha Benar Allah dengan Segala Firman-Nya',
        ayahCount: 6236,
        durationMinutes: 120,
        userName: appState.userName,
        khatamProgressJuz: 30,
        khatamProgressPercent: 100,
        khatamCount: appState.khatmCount > 0 ? appState.khatmCount : 1,
        dateStr: DateFormat('d MMMM yyyy').format(DateTime.now()),
        bonusPoints: 500,
        quote: 'Sebaik-baik kalian adalah yang mempelajari Al-Qur\'an dan mengajarkannya.',
        quoteSource: '(HR. Bukhari)',
      ),
    );
  }
}

class _GalleryTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _GalleryTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_GalleryTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
