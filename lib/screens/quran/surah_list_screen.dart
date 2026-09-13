import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../providers/app_state.dart';
import 'surah_detail_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';
import '../../utils/quran_progress_helper.dart';
import '../../utils/sunnah_mission_helper.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ValueNotifier<int> _currentVisibleSurah = ValueNotifier<int>(1);

  int? _highlightedSurahIndex;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    _currentVisibleSurah.dispose();
    super.dispose();
  }

  void _onItemPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int minIndex = positions.first.index;
    for (final pos in positions) {
      if (pos.index < minIndex && pos.itemLeadingEdge >= 0) {
        minIndex = pos.index;
      }
    }
    final visible = minIndex + 1;
    if (_currentVisibleSurah.value != visible) {
      _currentVisibleSurah.value = visible;
    }
  }

  void _scrollToSurah(int index, {bool animate = false}) {
    if (index < 0) index = 0;
    final appState = Provider.of<AppState>(context, listen: false);
    final total = appState.quranData.length;
    if (total == 0) return;
    if (index >= total) index = total - 1;

    if (_itemScrollController.isAttached) {
      if (animate) {
        _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _itemScrollController.jumpTo(index: index);
      }
    }
    _currentVisibleSurah.value = index + 1;

    _highlightTimer?.cancel();
    setState(() {
      _highlightedSurahIndex = index;
    });
    _highlightTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _highlightedSurahIndex = null;
        });
      }
    });
  }

  void _showSurahNavigatorSheet(
    BuildContext context,
    AppState appState,
    String lang,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 6,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SurahNavigatorBottomSheet(
        quranData: appState.quranData,
        currentVisibleSurah: _currentVisibleSurah.value,
        lastReadSurahIndex: appState.currentSurahIndex >= 0 &&
                appState.currentSurahIndex < appState.quranData.length
            ? appState.currentSurahIndex
            : null,
        highestSurahIndex: appState.highestSurahIndex >= 0 &&
                appState.highestSurahIndex < appState.quranData.length
            ? appState.highestSurahIndex
            : null,
        lang: lang,
        onSurahSelected: (surahNumber) {
          _scrollToSurah(surahNumber - 1);
        },
        onSurahOpened: (surahNumber) {
          final idx = surahNumber - 1;
          if (idx >= 0 && idx < appState.quranData.length) {
            final surah = appState.quranData[idx];
            appState.navigatorKey.currentState?.push(
              AppPageRoute(
                child: SurahDetailScreen(surah: surah),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final lastReadIdx = appState.currentSurahIndex;
    final int highestSurah = appState.highestSurahIndex;
    final int highestAyah = appState.highestAyahIndex;
    final int quranLength = appState.quranData.length;
    final bool prevFinished = (highestSurah >= 0 && highestSurah < quranLength)
        ? (highestAyah ==
            (appState.quranData[highestSurah]['total_ayah'] as int) - 1)
        : false;
    final int unlockedUntilIndex =
        prevFinished ? highestSurah + 1 : highestSurah;

    final colorScheme = Theme.of(context).colorScheme;

    final int currentSurahNum = appState.currentSurahIndex + 1;
    final int currentAyahNum =
        appState.lastReadAyahNumber > 0 ? appState.lastReadAyahNumber : 1;
    final int currentJuz = QuranProgressHelper.getJuzNumber(
      currentSurahNum,
      currentAyahNum,
    );
    final KhatamPhase currentPhase = QuranProgressHelper.getPhase(currentJuz);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          Translations.get(lang, 'select_surah'),
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
          IconButton(
            icon: const Icon(Icons.near_me_rounded),
            tooltip: _SurahNavTranslations.getTitle(lang),
            onPressed: () => _showSurahNavigatorSheet(context, appState, lang),
          ),
          _PointsBadge(
            points: appState.points,
            khatmCount: appState.khatmCount,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F5E3B),
                      Color(0xFF094027),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D5C3A).withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Translations.get(lang, 'total_surahs'),
                            style: const TextStyle(
                              color: Color(0xFFFBFDFC),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lang == 'id'
                                ? '114 Surah • Terjemahan'
                                : '114 Surahs • Translation',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: appState.quranData.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ScrollablePositionedList.builder(
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 2, 0, 80),
                        itemCount: appState.quranData.length,
                        itemBuilder: (context, index) {
                          final surah = appState.quranData[index];
                          final int surahNumber =
                              surah['surah_number'] as int? ?? (index + 1);
                          final bool isAlwaysActive =
                              SunnahMissionHelper.isSurahAlwaysActive(surahNumber);

                          final isLastRead = index == lastReadIdx;
                          final isFuture = index > unlockedUntilIndex;
                          final isFinished = index < highestSurah ||
                              (index == highestSurah && prevFinished);
                          final isHighlighted = _highlightedSurahIndex == index;

                          KhatamPhase? sectionPhase;
                          if (index == 0) {
                            sectionPhase = KhatamPhase.grandClimb;
                          } else if (index == 6) {
                            sectionPhase = KhatamPhase.rhythmicCadence;
                          } else if (index == 57) {
                            sectionPhase = KhatamPhase.sprintSummit;
                          }

                          final tile = RepaintBoundary(
                            child: Opacity(
                              opacity: (isFuture && !isAlwaysActive) ? 0.5 : 1.0,
                              child: _SurahTile(
                                surah: surah,
                                lang: lang,
                                isLastRead: isLastRead,
                                isFinished: isFinished,
                                isFuture: isFuture,
                                isHighlighted: isHighlighted,
                                onTap: () {
                                  appState.navigatorKey.currentState?.push(
                                    AppPageRoute(
                                      child: SurahDetailScreen(surah: surah),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );

                          if (sectionPhase != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PhaseSectionHeader(
                                  phase: sectionPhase,
                                  lang: lang,
                                  isCurrentPhase: currentPhase == sectionPhase,
                                  onInfoTap: () {
                                    QuranProgressHelper.showJourneyInfoModal(
                                      context,
                                      lang,
                                      currentJuz,
                                    );
                                  },
                                ),
                                tile,
                              ],
                            );
                          }

                          return tile;
                        },
                      ),
              ),
            ],
          ),
          if (quranLength > 0)
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: RepaintBoundary(
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentVisibleSurah,
                  builder: (context, currentSurah, _) {
                    return _SurahNavFloatingPill(
                      currentSurah: currentSurah,
                      totalSurahs: quranLength,
                      onTap: () =>
                          _showSurahNavigatorSheet(context, appState, lang),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhaseSectionHeader extends StatelessWidget {
  final KhatamPhase phase;
  final String lang;
  final bool isCurrentPhase;
  final VoidCallback onInfoTap;

  const _PhaseSectionHeader({
    required this.phase,
    required this.lang,
    required this.isCurrentPhase,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = QuranProgressHelper.getPhaseTitle(phase, lang);

    Color accentColor;
    IconData phaseIcon;
    switch (phase) {
      case KhatamPhase.grandClimb:
        accentColor = const Color(0xFF10B981);
        phaseIcon = Icons.eco_rounded;
        break;
      case KhatamPhase.rhythmicCadence:
        accentColor = const Color(0xFF0284C7);
        phaseIcon = Icons.spa_rounded;
        break;
      case KhatamPhase.sprintSummit:
        accentColor = const Color(0xFFF59E0B);
        phaseIcon = Icons.bolt_rounded;
        break;
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        phase == KhatamPhase.grandClimb ? 4 : 22,
        16,
        8,
      ),
      decoration: BoxDecoration(
        color: isCurrentPhase
            ? accentColor.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPhase
              ? accentColor.withValues(alpha: 0.45)
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: isCurrentPhase ? 1.2 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onInfoTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    phaseIcon,
                    size: 16,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isCurrentPhase
                                ? accentColor
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentPhase) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang == 'id' ? 'Aktif' : 'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onInfoTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final dynamic surah;
  final String lang;
  final bool isLastRead;
  final bool isFinished;
  final bool isFuture;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SurahTile({
    required this.surah,
    required this.lang,
    required this.isLastRead,
    required this.isFinished,
    required this.isFuture,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int surahNumber = surah['surah_number'] as int? ?? 0;
    final bool isAlwaysActive =
        SunnahMissionHelper.isSurahAlwaysActive(surahNumber);

    final Color borderColor = isHighlighted
        ? Colors.teal
        : (isLastRead
            ? colorScheme.primary
            : colorScheme.outlineVariant.withValues(alpha: 0.4));
    final double borderWidth = isHighlighted ? 2.0 : (isLastRead ? 1.5 : 1.0);
    final Color bgColor = isHighlighted
        ? Colors.teal.withValues(alpha: 0.15)
        : (isLastRead
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerLow);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _SurahNumberShape(
                  number: surah['surah_number'].toString(),
                  isLastRead: isLastRead,
                  isFuture: isFuture && !isAlwaysActive,
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah['surah_name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isLastRead
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${surah['total_ayah']} ${Translations.get(lang, 'ayah')}",
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFinished)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  )
                else if (isLastRead)
                  Icon(
                    Icons.history_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  )
                else if (isFuture && !isAlwaysActive)
                  Icon(
                    Icons.lock_outline_rounded,
                    color: colorScheme.outlineVariant,
                    size: 20,
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.outlineVariant,
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  final int khatmCount;
  const _PointsBadge({required this.points, required this.khatmCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (khatmCount > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 11,
                ),
                const SizedBox(width: 4),
                Text(
                  "Khatm ${khatmCount}x",
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                color: colorScheme.onTertiaryContainer,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                points.toString(),
                style: TextStyle(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurahNumberShape extends StatelessWidget {
  final String number;
  final bool isLastRead;
  final bool isFuture;

  const _SurahNumberShape({
    required this.number,
    required this.isLastRead,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color = isLastRead
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    Color textColor = isLastRead
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    if (isFuture) {
      color = colorScheme.surfaceContainerHigh.withValues(alpha: 0.5);
      textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    }

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The 8-pointed star (Rub el Hizb)
          Transform.rotate(
            angle: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.785, // 45 degrees in radians
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            number,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating Navigation Pill positioned cleanly above the system navbar.
class _SurahNavFloatingPill extends StatelessWidget {
  final int currentSurah;
  final int totalSurahs;
  final VoidCallback onTap;

  const _SurahNavFloatingPill({
    required this.currentSurah,
    required this.totalSurahs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isDark ? Colors.teal.shade900 : Colors.teal.shade700,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Surah $currentSurah / $totalSurahs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.unfold_more_rounded,
                size: 15,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translation helper for Surah Navigation across 6 supported languages.
class _SurahNavTranslations {
  static String getTitle(String lang) {
    switch (lang) {
      case 'en':
        return 'Jump to Surah';
      case 'ar':
        return 'الانتقال إلى السورة';
      case 'af':
        return 'Spring na Soera';
      case 'sw':
        return 'Nenda kwenye Sura';
      case 'ms':
      case 'id':
      default:
        return 'Lompat ke Surah';
    }
  }

  static String getSubtitle(String lang, int total) {
    switch (lang) {
      case 'en':
        return 'Select Surah 1 - $total';
      case 'ar':
        return 'اختر سورة ١ - $total';
      case 'af':
        return 'Kies Soera 1 - $total';
      case 'sw':
        return 'Chagua Sura 1 - $total';
      case 'ms':
      case 'id':
      default:
        return 'Pilih Surah 1 - $total';
    }
  }

  static String getEnterNumber(String lang) {
    switch (lang) {
      case 'en':
        return 'Enter Surah Number';
      case 'ar':
        return 'أدخل رقم السورة';
      case 'af':
        return 'Voer Soeranommer In';
      case 'sw':
        return 'Weka Namba ya Sura';
      case 'ms':
      case 'id':
      default:
        return 'Ketik Nomor Surah';
    }
  }

  static String getMaxSurahError(String lang, int total) {
    switch (lang) {
      case 'en':
        return 'Max surah is $total';
      case 'ar':
        return 'أقصى عدد للسور هو $total';
      case 'af':
        return 'Maksimum soera is $total';
      case 'sw':
        return 'Upeo wa sura ni $total';
      case 'ms':
      case 'id':
      default:
        return 'Maksimal surah $total';
    }
  }

  static String getInvalidSurahError(String lang, int total) {
    switch (lang) {
      case 'en':
        return 'Enter 1 - $total';
      case 'ar':
        return 'أدخل ١ - $total';
      case 'af':
        return 'Kies 1 - $total';
      case 'sw':
        return 'Chagua 1 - $total';
      case 'ms':
      case 'id':
      default:
        return 'Pilih surah 1 - $total';
    }
  }

  static String getLastRead(String lang) {
    switch (lang) {
      case 'en':
        return 'Last Read';
      case 'ar':
        return 'آخر قراءة';
      case 'af':
        return 'Laas Gelees';
      case 'sw':
        return 'Mwisho Kusomwa';
      case 'ms':
      case 'id':
      default:
        return 'Terakhir Dibaca';
    }
  }

  static String getNextTarget(String lang) {
    switch (lang) {
      case 'en':
        return 'Next Target';
      case 'ar':
        return 'الهدف التالي';
      case 'af':
        return 'Volgende Teiken';
      case 'sw':
        return 'Lengo Linalofuata';
      case 'ms':
      case 'id':
      default:
        return 'Target Lanjut';
    }
  }

  static String getOpenSurah(String lang) {
    switch (lang) {
      case 'en':
        return 'Open Directly';
      case 'ar':
        return 'فتح السورة';
      case 'af':
        return 'Maak Oop';
      case 'sw':
        return 'Fungua';
      case 'ms':
      case 'id':
      default:
        return 'Buka Langsung';
    }
  }

  static String getJumpTo(String lang) {
    switch (lang) {
      case 'en':
        return 'Jump to Surah';
      case 'ar':
        return 'انتقل إلى السورة';
      case 'af':
        return 'Spring na Soera';
      case 'sw':
        return 'Nenda kwenye Sura';
      case 'ms':
      case 'id':
      default:
        return 'Lompat ke Surah';
    }
  }
}

/// Ultra-smooth Surah Navigator Bottom Sheet with in-app numeric keypad and live preview.
class _SurahNavigatorBottomSheet extends StatefulWidget {
  final List<dynamic> quranData;
  final int currentVisibleSurah;
  final int? lastReadSurahIndex;
  final int? highestSurahIndex;
  final String lang;
  final ValueChanged<int> onSurahSelected;
  final ValueChanged<int> onSurahOpened;

  const _SurahNavigatorBottomSheet({
    required this.quranData,
    required this.currentVisibleSurah,
    this.lastReadSurahIndex,
    this.highestSurahIndex,
    required this.lang,
    required this.onSurahSelected,
    required this.onSurahOpened,
  });

  @override
  State<_SurahNavigatorBottomSheet> createState() =>
      _SurahNavigatorBottomSheetState();
}

class _SurahNavigatorBottomSheetState
    extends State<_SurahNavigatorBottomSheet> {
  String _enteredNumber = '';
  String? _errorMessage;

  void _onDigitPressed(int digit) {
    HapticFeedback.selectionClick();
    if (_enteredNumber.isEmpty && digit == 0) return;
    final candidate = '$_enteredNumber$digit';
    final parsed = int.tryParse(candidate);
    final total = widget.quranData.length;
    if (parsed != null && parsed > total) {
      setState(() {
        _errorMessage =
            _SurahNavTranslations.getMaxSurahError(widget.lang, total);
      });
      return;
    }
    setState(() {
      _enteredNumber = candidate;
      _errorMessage = null;
    });
  }

  void _onBackspacePressed() {
    HapticFeedback.selectionClick();
    if (_enteredNumber.isNotEmpty) {
      setState(() {
        _enteredNumber =
            _enteredNumber.substring(0, _enteredNumber.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClearPressed() {
    HapticFeedback.selectionClick();
    setState(() {
      _enteredNumber = '';
      _errorMessage = null;
    });
  }

  void _onJumpPressed() {
    if (_enteredNumber.isEmpty) return;
    final parsed = int.tryParse(_enteredNumber);
    final total = widget.quranData.length;
    if (parsed == null || parsed < 1 || parsed > total) {
      setState(() {
        _errorMessage =
            _SurahNavTranslations.getInvalidSurahError(widget.lang, total);
      });
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onSurahSelected(parsed);
  }

  void _onOpenPressed() {
    if (_enteredNumber.isEmpty) return;
    final parsed = int.tryParse(_enteredNumber);
    final total = widget.quranData.length;
    if (parsed == null || parsed < 1 || parsed > total) {
      setState(() {
        _errorMessage =
            _SurahNavTranslations.getInvalidSurahError(widget.lang, total);
      });
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onSurahOpened(parsed);
  }

  void _selectChip(int surahNumber) {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    widget.onSurahSelected(surahNumber);
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipColor = color ?? Colors.teal;
    final textColor = isDark
        ? chipColor.withValues(alpha: 0.95)
        : chipColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: chipColor.withValues(alpha: isDark ? 0.45 : 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: chipColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(
    List<int> digits,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: digits
            .map(
              (d) => _buildKeyButton(
                child: Text(
                  '$d',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () => _onDigitPressed(d),
                isDark: isDark,
                colorScheme: colorScheme,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final total = widget.quranData.length;

    final parsed = int.tryParse(_enteredNumber);
    String? previewSurahName;
    int? previewAyahCount;
    if (parsed != null && parsed >= 1 && parsed <= total) {
      final s = widget.quranData[parsed - 1];
      previewSurahName = s['surah_name'] as String?;
      previewAyahCount = s['total_ayah'] as int?;
    }
    final ayahLabel = Translations.get(widget.lang, 'ayah');

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: Colors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _SurahNavTranslations.getTitle(widget.lang),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _SurahNavTranslations.getSubtitle(
                            widget.lang,
                            total,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Number Display Box with Live Surah Preview
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.red
                        : Colors.teal.withValues(alpha: 0.3),
                    width: _errorMessage != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Surah: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    Text(
                      _enteredNumber.isEmpty ? '-' : _enteredNumber,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: _enteredNumber.isEmpty
                            ? colorScheme.onSurface.withValues(alpha: 0.3)
                            : Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (previewSurahName != null)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$previewSurahName • $previewAyahCount $ayahLabel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          '1 - $total',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    if (_enteredNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _onClearPressed,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Quick Shortcuts (Horizontal Scroll)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.lastReadSurahIndex != null) ...[
                      _buildQuickChip(
                        label:
                            '${_SurahNavTranslations.getLastRead(widget.lang)}: ${widget.quranData[widget.lastReadSurahIndex!]['surah_name']}',
                        icon: Icons.bookmark_added_rounded,
                        color: Colors.teal,
                        onTap: () =>
                            _selectChip(widget.lastReadSurahIndex! + 1),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.highestSurahIndex != null &&
                        widget.highestSurahIndex! + 1 < total) ...[
                      _buildQuickChip(
                        label:
                            '${_SurahNavTranslations.getNextTarget(widget.lang)}: ${widget.quranData[widget.highestSurahIndex! + 1]['surah_name']}',
                        icon: Icons.track_changes_rounded,
                        color: Colors.orange.shade800,
                        onTap: () =>
                            _selectChip(widget.highestSurahIndex! + 2),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _buildQuickChip(
                      label: widget.lang == 'en'
                          ? 'Surah 1 (Start)'
                          : 'Surah 1 (Awal)',
                      icon: Icons.first_page_rounded,
                      onTap: () => _selectChip(1),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: 'Fase 1: Pendakian (1. Al-Fatihah)',
                      icon: Icons.eco_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => _selectChip(1),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: "Fase 2: Irama (7. Al-A'raf)",
                      icon: Icons.spa_rounded,
                      color: const Color(0xFF0284C7),
                      onTap: () => _selectChip(7),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: 'Fase 3: Puncak (58. Al-Mujadilah)',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _selectChip(58),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '18. Al-Kahf',
                      icon: Icons.star_rounded,
                      color: Colors.indigo,
                      onTap: () => _selectChip(18),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '36. Ya-Sin',
                      icon: Icons.star_rounded,
                      color: Colors.indigo,
                      onTap: () => _selectChip(36),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: "56. Al-Waqi'ah",
                      icon: Icons.star_rounded,
                      color: Colors.indigo,
                      onTap: () => _selectChip(56),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '67. Al-Mulk',
                      icon: Icons.star_rounded,
                      color: Colors.indigo,
                      onTap: () => _selectChip(67),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: "78. An-Naba' (Juz 30)",
                      icon: Icons.auto_stories_rounded,
                      color: Colors.deepPurple,
                      onTap: () => _selectChip(78),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: widget.lang == 'en'
                          ? '114. An-Nas (End)'
                          : '114. An-Nas (Akhir)',
                      icon: Icons.last_page_rounded,
                      onTap: () => _selectChip(114),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // In-App Custom Numeric Keypad
              _buildKeypadRow([1, 2, 3], isDark, colorScheme),
              _buildKeypadRow([4, 5, 6], isDark, colorScheme),
              _buildKeypadRow([7, 8, 9], isDark, colorScheme),
              Row(
                children: [
                  _buildKeyButton(
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                      ),
                    ),
                    onTap: _onClearPressed,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                  _buildKeyButton(
                    child: Text(
                      '0',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () => _onDigitPressed(0),
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                  _buildKeyButton(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    onTap: _onBackspacePressed,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Buttons: Jump vs Open
              if (_enteredNumber.isNotEmpty && previewSurahName != null)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 46,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _onJumpPressed,
                          icon: const Icon(Icons.near_me_rounded, size: 18),
                          label: Text(
                            '${_SurahNavTranslations.getJumpTo(widget.lang)} $previewSurahName',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _onOpenPressed,
                          icon: const Icon(Icons.menu_book_rounded,
                              size: 16),
                          label: Text(
                            _SurahNavTranslations.getOpenSurah(widget.lang),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      disabledBackgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      disabledForegroundColor: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: null,
                    icon: const Icon(Icons.near_me_rounded, size: 18),
                    label: Text(
                      _SurahNavTranslations.getEnterNumber(widget.lang),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
