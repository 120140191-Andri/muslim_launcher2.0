import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'surah_detail_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  @override
  void initState() {
    super.initState();
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  Translations.get(lang, 'total_surahs'),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 60),
                    itemCount: appState.quranData.length,
                    itemBuilder: (context, index) {
                      final surah = appState.quranData[index];

                      final isLastRead = index == lastReadIdx;
                      final isFuture = index > unlockedUntilIndex;
                      final isFinished = index < highestSurah ||
                          (index == highestSurah && prevFinished);

                      return RepaintBoundary(
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
                    },
                  ),
          ),
        ],
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
