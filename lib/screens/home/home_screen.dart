import 'dart:async';

import 'package:flutter/material.dart';

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

  String _getTimeGreeting(String lang) {
    final hour = _now.hour;
    if (hour < 12) return lang == 'en' ? 'Good Morning' : 'Selamat Pagi';
    if (hour < 15) return lang == 'en' ? 'Good Afternoon' : 'Selamat Siang';
    if (hour < 18) return lang == 'en' ? 'Good Evening' : 'Selamat Sore';
    return lang == 'en' ? 'Good Night' : 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: Stack(
        children: [
          // Background Gradient / Pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.teal.shade900, const Color(0xFFF8FAFA)],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header with Clock & Greeting
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTimeGreeting(lang),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang == 'en'
                                    ? 'Spread Kindness'
                                    : 'Pejuang Kebaikan',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  appState.points.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      RepaintBoundary(
                        child: _ClockWidget(
                          hourString: _hourString,
                          minuteString: _minuteString,
                          dateString: _dateString,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resume Section
                          Text(
                            (lang == 'en'
                                    ? 'CONTINUE JOURNEY'
                                    : 'LANJUTKAN PERJALANAN')
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.teal.shade900.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: Builder(
                              builder: (context) {
                                int totalAyahs = 0;
                                if (appState.quranData.isNotEmpty &&
                                    appState.currentSurahIndex >= 0 &&
                                    appState.currentSurahIndex <
                                        appState.quranData.length) {
                                  totalAyahs =
                                      (appState.quranData[appState
                                                  .currentSurahIndex]['ayahs']
                                              as List)
                                          .length;
                                }

                                return _LastAyatCard(
                                  surah: appState.lastReadSurah,
                                  ayahNumber: appState.lastReadAyahNumber,
                                  totalAyahs: totalAyahs,
                                  currentSurahIdx: appState.currentSurahIndex,
                                  lang: lang,
                                  onTap: () => _resumeReading(appState),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Quick Actions Grid
                          Text(
                            (lang == 'en' ? 'QUICK ACTIONS' : 'AKSES CEPAT')
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.teal.shade900.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _GridAction(
                                  icon: Icons.menu_book_rounded,
                                  title: lang == 'en'
                                      ? 'Read Quran'
                                      : 'Baca Quran',
                                  subtitle: lang == 'en'
                                      ? '114 Surahs'
                                      : '114 Surah',
                                  color: Colors.teal.shade700,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SurahListScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _GridAction(
                                  icon: Icons.apps_rounded,
                                  title: lang == 'en'
                                      ? 'Your Apps'
                                      : 'Aplikasi',
                                  subtitle: lang == 'en'
                                      ? 'Open Apps'
                                      : 'Buka Aplikasi',
                                  color: Colors.amber.shade800,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AppListScreen(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Inspirational Section (Now Last Read Ayah Translation)
                          Builder(
                            builder: (context) {
                              String translation = "";
                              if (appState.quranData.isNotEmpty &&
                                  appState.lastReadSurah.isNotEmpty) {
                                final sIdx = appState.currentSurahIndex;
                                final aIdx = appState.currentAyahIndex;
                                if (sIdx >= 0 &&
                                    sIdx < appState.quranData.length) {
                                  final surah = appState.quranData[sIdx];
                                  final ayahs = surah['ayahs'] as List<dynamic>;
                                  if (aIdx >= 0 && aIdx < ayahs.length) {
                                    final ayah = ayahs[aIdx];
                                    translation = lang == 'en'
                                        ? (ayah['translation_en'] ?? "")
                                        : (ayah['translation_id'] ?? "");
                                  }
                                }
                              }

                              return _DailyInspiration(
                                lang: lang,
                                surah: appState.lastReadSurah,
                                ayahNumber: appState.lastReadAyahNumber,
                                ayahText: translation,
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
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
                fontSize: 84,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                ':',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 54,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),
            Text(
              minuteString,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 72,
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateString.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _LastAyatCard extends StatelessWidget {
  final String surah;
  final int ayahNumber;
  final int totalAyahs;
  final int currentSurahIdx;
  final String lang;
  final VoidCallback onTap;

  const _LastAyatCard({
    required this.surah,
    required this.ayahNumber,
    required this.totalAyahs,
    required this.currentSurahIdx,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: surah.isEmpty ? null : onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.isEmpty
                                  ? (lang == 'en'
                                        ? 'Start Reading'
                                        : 'Mulai Baca')
                                  : surah,
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              surah.isEmpty
                                  ? (lang == 'en'
                                        ? 'Find guidance today'
                                        : 'Temukan petunjuk hari ini')
                                  : (lang == 'en'
                                        ? 'Ayah $ayahNumber'
                                        : 'Ayat $ayahNumber'),
                              style: TextStyle(
                                color: Colors.teal.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (surah.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Surah ${currentSurahIdx + 1}/114',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ayat $ayahNumber/$totalAyahs',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal.shade400,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (surah.isNotEmpty)
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.teal.shade600,
                          size: 40,
                        ),
                    ],
                  ),
                ),
                if (surah.isNotEmpty && totalAyahs > 0)
                  LinearProgressIndicator(
                    value: ayahNumber / totalAyahs,
                    backgroundColor: Colors.teal.shade50,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.teal.shade300,
                    ),
                    minHeight: 4,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GridAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyInspiration extends StatelessWidget {
  final String lang;
  final String surah;
  final int ayahNumber;
  final String ayahText;

  const _DailyInspiration({
    required this.lang,
    required this.surah,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  Widget build(BuildContext context) {
    final hasLastRead = surah.isNotEmpty && ayahText.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_quote_rounded,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                (hasLastRead
                        ? (lang == 'en'
                              ? 'LAST READ AYAH'
                              : 'AYAT TERAKHIR DIBACA')
                        : (lang == 'en'
                              ? 'DAILY INSPIRATION'
                              : 'INSPIRASI HARIAN'))
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasLastRead
                ? '"$ayahText"'
                : (lang == 'en'
                      ? '"Verily, with hardship, there is relief."'
                      : '"Karena sesungguhnya sesudah kesulitan itu ada kemudahan."'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasLastRead ? 'QS. $surah: $ayahNumber' : 'QS. Al-Insyirah: 5',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
