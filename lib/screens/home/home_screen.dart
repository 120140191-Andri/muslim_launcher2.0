import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../quran/surah_detail_screen.dart';
import '../quran/reading_history_screen.dart';
import 'app_list_screen.dart';
import 'accessibility_setup_screen.dart';
import '../../utils/page_transitions.dart';

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
      if (!mounted) return;
      AppListScreen.preload()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _checkAccessibilityStatus();

            // PROACTIVE SYNC: Force category-based blocking on startup
            final appState = Provider.of<AppState>(context, listen: false);
            const MethodChannel('com.muslimlauncher/apps')
                .invokeMethod('getApps')
                .then((raw) {
                  if (!mounted) return;
                  appState.syncAppsWithCategories(raw);
                })
                .catchError((_) {});
          })
          .catchError((_) {});
    });
  }

  Future<void> _checkAccessibilityStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    // Show if apps are blocked OR if it's the first time and service is not enabled
    final shouldShow =
        (appState.blockedApps.isNotEmpty ||
            !appState.hasSeenAccessibilitySetup) &&
        !appState.isAccessibilityEnabled;

    if (shouldShow && mounted) {
      _showAccessibilitySetupPrompt();
    }
  }

  void _showAccessibilitySetupPrompt() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setHasSeenAccessibilitySetup(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.teal),
            SizedBox(width: 12),
            Text('Aktifkan Blokir'),
          ],
        ),
        content: const Text(
          'Beberapa aplikasi telah Anda blokir. Agar pemblokiran bekerja di seluruh sistem (termasuk via Play Store), Anda perlu mengaktifkan Layanan Aksesibilitas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              appState.setIgnorePermissionGuard(true);
              Navigator.pop(ctx);
              appState.navigatorKey.currentState
                  ?.push(AppPageRoute(child: const AccessibilitySetupScreen()))
                  .then((_) => appState.setIgnorePermissionGuard(false));
            },
            child: const Text('Setup Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Only invalidate app list, keep icon cache intact for smooth re-entry
      AppListScreen.invalidateAppsOnly();
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
        appState.navigatorKey.currentState?.push(
          AppPageRoute(
            child: SurahDetailScreen(
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

  Widget _buildHeaderBadge({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: !appState.isReady
            ? _buildLoadingState()
            : Stack(
                key: const ValueKey('home_content'),
                children: [
                  // Background Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.teal.shade900,
                            const Color(0xFFF8FAFA),
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      children: [
                        // Header with Clock & Greeting
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getTimeGreeting(lang),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Pejuang Kebaikan',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => appState
                                            .navigatorKey
                                            .currentState
                                            ?.push(
                                              AppPageRoute(
                                                child:
                                                    const ReadingHistoryScreen(),
                                              ),
                                            ),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.history_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildHeaderBadge(
                                        icon: Icons.stars_rounded,
                                        value: "${appState.points} Pts",
                                        color: Colors.amber,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              RepaintBoundary(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _ClockWidget(
                                    hourString: _hourString,
                                    minuteString: _minuteString,
                                    dateString: _dateString,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Main Content (Scrollable)
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFA),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 24),

                                    // Accessibility Warning
                                    if (appState.blockedApps.isNotEmpty &&
                                        !appState.isAccessibilityEnabled)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 24,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.shade100,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.red.shade800,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      lang == 'en'
                                                          ? 'Accessibility service is required for global app blocking.'
                                                          : 'Layanan aksesibilitas diperlukan agar fitur blokir bekerja di luar Launcher.',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.red.shade900,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    appState
                                                        .setIgnorePermissionGuard(
                                                          true,
                                                        );
                                                    appState
                                                        .navigatorKey
                                                        .currentState
                                                        ?.push(
                                                          AppPageRoute(
                                                            child:
                                                                const AccessibilitySetupScreen(),
                                                          ),
                                                        )
                                                        .then(
                                                          (_) => appState
                                                              .setIgnorePermissionGuard(
                                                                false,
                                                              ),
                                                        );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red.shade700,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    lang == 'en'
                                                        ? 'Setup Now'
                                                        : 'Atur Sekarang',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Last Read Card
                                    Text(
                                      (lang == 'en'
                                              ? 'CONTINUE JOURNEY'
                                              : 'LANJUTKAN PERJALANAN')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.teal.shade900.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Builder(
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
                                          ayahNumber:
                                              appState.lastReadAyahNumber,
                                          totalAyahs: totalAyahs,
                                          currentSurahIdx:
                                              appState.currentSurahIndex,
                                          lang: lang,
                                          khatmCount: appState.khatmCount,
                                          onTap: () => _resumeReading(appState),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 24),
                                    Text(
                                      (lang == 'en'
                                              ? 'QUICK ACTIONS'
                                              : 'AKSES CEPAT')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.teal.shade900.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                    _QuickDock(),
                                    const SizedBox(height: 24),

                                    // Daily Inspiration
                                    _DailyInspiration(
                                      lang: lang,
                                      surah: appState.dailySurahName,
                                      ayahNumber: appState.dailyAyahNumber,
                                      ayahText: lang == 'en'
                                          ? appState.dailyAyahTextEn
                                          : appState.dailyAyahTextId,
                                    ),

                                    const SizedBox(height: 24),

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
                                            onTap: () => appState
                                                .navigatorKey
                                                .currentState
                                                ?.push(
                                                  AppPageRoute(
                                                    child:
                                                        const SurahListScreen(),
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
                                            onTap: () => appState
                                                .navigatorKey
                                                .currentState
                                                ?.push(
                                                  AppPageRoute(
                                                    child:
                                                        const AppListScreen(),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(
                                      height:
                                          80 +
                                          MediaQuery.of(context).padding.bottom,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Dock
                  Positioned(
                    bottom: 24 + MediaQuery.of(context).padding.bottom,
                    left: 24,
                    right: 24,
                    child: _buildBottomDock(appState, context),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      key: const ValueKey('loading_state'),
      width: double.infinity,
      color: Colors.teal.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "MUSLIM LAUNCHER",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Menyiapkan Ruang Fokus",
            style: TextStyle(
              color: Colors.teal.shade100,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Colors.teal.shade200,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock(AppState appState, BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildDockItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: true,
              onTap: () {},
            ),
            _buildDockItem(
              icon: Icons.menu_book_rounded,
              label: 'Quran',
              isActive: false,
              onTap: () => appState.navigatorKey.currentState?.push(
                AppPageRoute(child: const SurahListScreen()),
              ),
            ),
            _buildDockItem(
              icon: Icons.apps_rounded,
              label: 'Apps',
              isActive: false,
              onTap: () => appState.navigatorKey.currentState?.push(
                AppPageRoute(child: const AppListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.teal.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.teal : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.teal : Colors.grey.shade500,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
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
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 54,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ),
            Text(
              minuteString,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
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
            color: Colors.black.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateString.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
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

// ── _QuickDock ───────────────────────────────────────────────────────────────
class _QuickDock extends StatelessWidget {
  static const _channel = MethodChannel('com.muslimlauncher/apps');

  Future<void> _openApp(String pkg) async {
    try {
      await _channel.invokeMethod('openApp', {'packageName': pkg});
    } catch (_) {}
  }

  String? _findFirstAvailable(List<String> candidates) {
    final apps = AppListScreen.cachedApps;
    if (apps == null) return null;
    for (final pkg in candidates) {
      if (apps.any((a) => a.packageName == pkg)) {
        return pkg;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Determine dynamic icons
    final List<Widget> items = [];

    // 1. Phone Icons (Trying to find two different ones if available)
    final phonePkgs = [
      'com.google.android.dialer',
      'com.android.dialer',
      'com.samsung.android.dialer',
      'com.android.phone',
      'com.oppo.launcher', // Some manufacturers bake it in
      'com.coloros.safecenter',
    ];

    final availablePhones = <String>[];
    for (var p in phonePkgs) {
      if (AppListScreen.cachedApps?.any((a) => a.packageName == p) ?? false) {
        if (!availablePhones.contains(p)) availablePhones.add(p);
      }
      if (availablePhones.length >= 2) break;
    }

    // Add first phone (if many found, add first two; otherwise just what's found)
    if (availablePhones.isNotEmpty) {
      items.add(_buildIcon(Icons.phone_rounded, availablePhones[0]));
    }
    // Add second phone if available
    if (availablePhones.length > 1) {
      items.add(_buildIcon(Icons.phone_callback_rounded, availablePhones[1]));
    } else if (availablePhones.isNotEmpty) {
      // If only one system dialer, maybe user wants a duplicate or just one?
      // User asked for "1 more phone app on the far left"
      // If we only find one, we'll only show one to avoid confusion,
      // but the logic allows showing 2 if found.
    }

    // 2. Messages
    final msgPkg = _findFirstAvailable([
      'com.google.android.apps.messaging',
      'com.android.messaging',
      'com.samsung.android.messaging',
    ]);
    if (msgPkg != null) {
      items.add(_buildIcon(Icons.message_rounded, msgPkg));
    }

    // 3. Contacts
    final contactPkg = _findFirstAvailable([
      'com.google.android.contacts',
      'com.android.contacts',
      'com.samsung.android.contacts',
    ]);
    if (contactPkg != null) {
      items.add(_buildIcon(Icons.people_alt_rounded, contactPkg));
    }

    // 4. WhatsApp (Conditional)
    if (_findFirstAvailable(['com.whatsapp']) != null) {
      items.add(_buildIcon(Icons.chat_bubble_rounded, 'com.whatsapp'));
    }

    // 5. WhatsApp Business (Conditional)
    if (_findFirstAvailable(['com.whatsapp.w4b']) != null) {
      items.add(_buildIcon(Icons.business_center_rounded, 'com.whatsapp.w4b'));
    }

    // 6. Gallery
    final galleryPkg = _findFirstAvailable([
      'com.google.android.apps.photos',
      'com.android.gallery',
      'com.sec.android.gallery3d',
      'com.miui.gallery',
    ]);
    if (galleryPkg != null) {
      items.add(_buildIcon(Icons.photo_library_rounded, galleryPkg));
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 12,
      ), // Reduced horizontal padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((w) => Flexible(child: w))
            .toList(), // Make each icon flexible to prevent overflow
      ),
    );
  }

  Widget _buildIcon(IconData fallback, String pkg) {
    // Try to get real icon from cache
    final app = AppListScreen.cachedApps?.firstWhere(
      (a) => a.packageName == pkg,
      orElse: () => AppInfo(appName: '', packageName: '', category: -1),
    );

    final iconBytes = (app != null) ? AppListScreen.iconCache[pkg] : null;

    return InkWell(
      onTap: () => _openApp(pkg),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44, // Reduced from 56
        height: 44, // Reduced from 56
        padding: const EdgeInsets.all(4), // Tighter padding
        child: iconBytes != null
            ? Image.memory(iconBytes, filterQuality: FilterQuality.medium)
            : Icon(fallback, color: Colors.teal.shade700, size: 24),
      ),
    );
  }
}

class _LastAyatCard extends StatelessWidget {
  final String surah;
  final int ayahNumber;
  final int totalAyahs;
  final int currentSurahIdx;
  final String lang;
  final int khatmCount;
  final VoidCallback onTap;

  const _LastAyatCard({
    required this.surah,
    required this.ayahNumber,
    required this.totalAyahs,
    required this.currentSurahIdx,
    required this.lang,
    required this.khatmCount,
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
            color: Colors.teal.shade900.withValues(alpha: 0.05),
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
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16), // Reduced from 20
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
                            // Add extra padding at the top for the badge if needed,
                            // but let's see if we can just push the text down a bit
                            const SizedBox(height: 8),
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

                // Khatm Badge Overlay
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF5D4037),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Khatm: ${khatmCount}x",
                          style: const TextStyle(
                            color: Color(0xFF5D4037),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Progress Indicator at Bottom
                if (surah.isNotEmpty && totalAyahs > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: ayahNumber / totalAyahs,
                      backgroundColor: Colors.teal.shade50,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.teal.shade300,
                      ),
                      minHeight: 4,
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
      height:
          150, // Increased from 140 to fix 6px overflow while remaining compact
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    final double fontSize = ayahText.length < 60
        ? 22
        : ayahText.length < 120
        ? 18
        : ayahText.length < 200
        ? 16
        : 14;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade800, Colors.teal.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                (lang == 'en' ? 'INSIGHT OF THE DAY' : 'INSIGHT HARI INI'),
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.format_quote_rounded,
                color: Colors.amber,
                size: 24,
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
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              hasLastRead ? 'QS. $surah: $ayahNumber' : 'QS. Al-Insyirah: 5',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
