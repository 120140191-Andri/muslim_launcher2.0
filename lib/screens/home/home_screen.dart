import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../quran/surah_detail_screen.dart';
import 'app_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (now.minute != _now.minute || now.hour != _now.hour) {
        if (mounted) setState(() => _now = now);
      }
    });

    // Delayed preload to avoid startup peak
    Future.delayed(const Duration(milliseconds: 500), () {
      AppListScreen.preload();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppListScreen.invalidate();
      AppListScreen.preload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer.cancel();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
  String get _hourString => _pad(_now.hour);
  String get _minuteString => _pad(_now.minute);

  String get _dateString {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return '${days[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  void _resumeReading(AppState appState) {
    if (appState.lastReadSurah.isNotEmpty && appState.quranData.isNotEmpty) {
      final surahIdx = appState.currentSurahIndex;
      if (surahIdx >= 0 && surahIdx < appState.quranData.length) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailScreen(
              surah: appState.quranData[surahIdx],
              initialAyahIndex: appState.currentAyahIndex,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: Column(
        children: [
          // Header area with clock
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: BoxDecoration(
              color: Colors.teal.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: RepaintBoundary(
              child: _ClockWidget(
                hourString: _hourString,
                minuteString: _minuteString,
                dateString: _dateString,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  RepaintBoundary(
                    child: _PointsCard(points: appState.points, lang: lang),
                  ),
                  const SizedBox(height: 16),
                  RepaintBoundary(
                    child: _LastAyatCard(
                      surah: appState.lastReadSurah,
                      ayahNumber: appState.lastReadAyahNumber,
                      lang: lang,
                      onTap: () => _resumeReading(appState),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ActionButton(
                    icon: Icons.menu_book_rounded,
                    label: lang == 'en' ? 'Read Qur\'an' : 'Baca Al-Qur\'an',
                    color: Colors.teal.shade800,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SurahListScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ActionButton(
                    icon: Icons.apps_rounded,
                    label: lang == 'en' ? 'All Apps' : 'Semua Aplikasi',
                    color: Colors.teal.shade600,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppListScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatelessWidget {
  final String hourString, minuteString, dateString;
  const _ClockWidget({
    required this.hourString,
    required this.minuteString,
    required this.dateString,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              hourString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                ':',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Text(
              minuteString,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 63,
                fontWeight: FontWeight.w400,
                letterSpacing: 1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          dateString.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  final int points;
  final String lang;
  const _PointsCard({required this.points, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              color: Colors.amber.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang == 'en' ? 'YOUR POINTS' : 'POIN ANDA',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$points ${lang == 'en' ? 'pts' : 'poin'}',
                style: TextStyle(
                  color: Colors.teal.shade900,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LastAyatCard extends StatelessWidget {
  final String surah;
  final int ayahNumber;
  final String lang;
  final VoidCallback onTap;
  const _LastAyatCard({
    required this.surah,
    required this.ayahNumber,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: surah.isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.teal.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (lang == 'en' ? 'RESUME READING' : 'LANJUT BACA')
                        .toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (surah.isNotEmpty)
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.teal.shade200,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              surah.isEmpty
                  ? Center(
                      child: Text(
                        lang == 'en'
                            ? 'Ready to read Quran today?'
                            : 'Siap tilawah hari ini?',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surah,
                                style: TextStyle(
                                  color: Colors.teal.shade900,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lang == 'en'
                                    ? 'Ayah $ayahNumber'
                                    : 'Ayat $ayahNumber',
                                style: TextStyle(
                                  color: Colors.teal.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.teal.shade600,
                          size: 36,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.teal.shade50),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.teal.shade100,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
