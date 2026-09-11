import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'surah_detail_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';
import '../../utils/quran_progress_helper.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
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
          _PointsBadge(
            points: appState.points,
            khatmCount: appState.khatmCount,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
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
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    cacheExtent: 80,
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 60),
                    itemCount: appState.quranData.length,
                    itemBuilder: (context, index) {
                      final surah = appState.quranData[index];

                      final isLastRead = index == lastReadIdx;
                      final isFuture = index > unlockedUntilIndex;
                      final isFinished = index < highestSurah ||
                          (index == highestSurah && prevFinished);

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
                          opacity: isFuture ? 0.5 : 1.0,
                          child: _SurahTile(
                            surah: surah,
                            lang: lang,
                            isLastRead: isLastRead,
                            isFinished: isFinished,
                            isFuture: isFuture,
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
  final VoidCallback onTap;

  const _SurahTile({
    required this.surah,
    required this.lang,
    required this.isLastRead,
    required this.isFinished,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: isLastRead
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLastRead
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isLastRead ? 1.5 : 1.0,
        ),
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
                  isFuture: isFuture,
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
                else if (isFuture)
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
