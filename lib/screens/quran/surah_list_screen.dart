import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'surah_detail_screen.dart';
import '../../utils/page_transitions.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Select Surah' : 'Pilih Surah'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  lang == 'en' ? '114 Surahs' : 'Total 114 Surah',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: appState.quranData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 60),

                    itemCount: appState.quranData.length,
                    itemBuilder: (context, index) {
                      final surah = appState.quranData[index];

                      final isLastRead = index == lastReadIdx;
                      final isFuture = !appState.isSurahUnlocked(index);
                      final isFinished = appState.isSurahFinished(index);

                      return RepaintBoundary(
                        child: Opacity(
                          opacity: isFuture ? 0.5 : 1.0,
                          child: _SurahTile(
                            surah: surah,
                            isLastRead: isLastRead,
                            isFinished: isFinished,
                            isFuture: isFuture,
                            onTap: () {
                              Navigator.push(
                                context,
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
  final bool isLastRead;
  final bool isFinished;
  final bool isFuture;
  final VoidCallback onTap;

  const _SurahTile({
    required this.surah,
    required this.isLastRead,
    required this.isFinished,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isLastRead ? Colors.teal.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLastRead
            ? Border.all(color: Colors.teal.shade200, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                              ? Colors.teal.shade900
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${surah['total_ayah']} Ayat",
                        style: TextStyle(
                          fontSize: 12,
                          color: isLastRead
                              ? Colors.teal.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFinished)
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.teal.shade400,
                    size: 20,
                  )
                else if (isLastRead)
                  Icon(
                    Icons.history_rounded,
                    color: Colors.teal.shade400,
                    size: 20,
                  )
                else if (isFuture)
                  Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.teal.shade100,
                    size: 20,
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.teal.shade300,
                    size: 16,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amber,
                size: 10,
              ),
              const SizedBox(width: 4),
              Text(
                "Khatm $khatmCount'x",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 10),
              const SizedBox(width: 4),
              Text(
                points.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
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
    Color color = isLastRead ? Colors.teal.shade200 : Colors.teal.shade50;
    Color textColor = isLastRead ? Colors.teal.shade900 : Colors.teal.shade800;

    if (isFuture) {
      color = Colors.grey.shade200;
      textColor = Colors.grey.shade400;
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
