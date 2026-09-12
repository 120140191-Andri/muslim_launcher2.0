import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:android_intent_plus/android_intent.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../quran/surah_detail_screen.dart';
import '../quran/reading_history_screen.dart';
import '../hadith/hadith_list_screen.dart';
import '../dzikir/dzikir_screen.dart';
import 'app_list_screen.dart';
import 'accessibility_setup_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';
import '../../utils/quran_progress_helper.dart';
import '../../widgets/language_selection_dialog.dart';
import '../../widgets/growth_tree_widget.dart';
import '../../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin, RouteAware {
  // Spiritual Energy Transmission Animation
  AnimationController? _spiritualEnergyController;
  SpiritualEnergySession? _activeEnergySession;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      AppState.routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (mounted) {
      setState(() {});
    }
  }

  void _checkAndTriggerEnergySession(AppState appState) {
    if (appState.pendingEnergySession != null) {
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) {
        return; // Wait until HomeScreen is the top active visible route!
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentRoute = ModalRoute.of(context);
        if (currentRoute != null && !currentRoute.isCurrent) return;

        final session = appState.consumePendingEnergySession();
        if (session != null) {
          _startSpiritualEnergySession(session);
        }
      });
    }
  }

  void _startSpiritualEnergySession(SpiritualEnergySession session) {
    _spiritualEnergyController?.dispose();
    _activeEnergySession = session;

    final controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: session.durationSeconds),
    );
    _spiritualEnergyController = controller;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _activeEnergySession = null;
            _spiritualEnergyController?.dispose();
            _spiritualEnergyController = null;
          });
        }
      }
    });

    controller.forward(from: 0.0);
    setState(() {});
  }

  Future<void> _openSupportDeveloperUrl() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final url = appState.supportUrl;
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
      );
      await intent.launch();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('HomeScreen');
    WidgetsBinding.instance.addObserver(this);

    // Background sync apps without artificial delay since disk cache is already hydrated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      AppListScreen.preload(
        onRawAppsFetched: (raw) {
          if (mounted) appState.syncAppsWithCategories(raw);
        },
        onProgress: () {
          if (mounted) setState(() {});
        },
      ).then((_) {
        if (!mounted) return;
        setState(() {});
        _checkAccessibilityStatus();
      }).catchError((_) {});
    });
  }

  Future<void> _checkAccessibilityStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // 1. If it's already enabled, do nothing.
    if (appState.isAccessibilityEnabled) return;

    // 2. Only show the DISRUPTIVE dialog if they've never seen the setup before.
    // If they have seen it, but it's still off, the UI Banner (below in build) will remind them.
    final shouldShowDialog = !appState.hasSeenAccessibilitySetup;

    if (shouldShowDialog && mounted) {
      _showAccessibilitySetupPrompt();
    }
  }

  void _showAccessibilitySetupPrompt() {
    final appState = Provider.of<AppState>(context, listen: false);
    // Explicitly check if the service is already enabled to avoid redundant prompts
    if (appState.isAccessibilityEnabled) return;
    
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
      // Refresh status on re-entry
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshStatus();
      _checkAccessibilityStatus();

      // Only preload if cache is empty (first launch or after invalidateFull from install/uninstall).
      // Native 'onAppListChanged' callback already handles install/uninstall events via invalidateFull.
      if (AppListScreen.cachedApps == null) {
        AppListScreen.preload(
          onProgress: () {
            if (mounted) setState(() {});
          },
        );
      }
    }
  }

  @override
  void dispose() {
    AppState.routeObserver.unsubscribe(this);
    _spiritualEnergyController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _resumeReading(AppState appState) {
    if (appState.lastReadSurah.isNotEmpty && appState.quranData.isNotEmpty) {
      final surahIdx = appState.currentSurahIndex;
      if (surahIdx >= 0 && surahIdx < appState.quranData.length) {
        appState.navigatorKey.currentState
            ?.push(
              AppPageRoute(
                child: SurahDetailScreen(
                  surah: appState.quranData[surahIdx],
                  initialAyahIndex: appState.currentAyahIndex,
                ),
              ),
            )
            .then((_) {
              if (mounted) setState(() {});
            });
        return;
      }
    }

    appState.navigatorKey.currentState
        ?.push(
          AppPageRoute(child: const SurahListScreen()),
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  Widget _buildHeaderBadge({
    required BuildContext context,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
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

    _checkAndTriggerEnergySession(appState);

    final combinedSpiritualProgress =
        QuranProgressHelper.getCombinedSpiritualProgress(
      khatmCount: appState.khatmCount,
      currentSurahIndex: appState.currentSurahIndex,
      currentAyahNumber: appState.lastReadAyahNumber,
      quranData: appState.quranData,
      totalDzikirCount: appState.totalDzikirCount,
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFA),
      body: !appState.isReady
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
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.surface,
                          ],
                          stops: const [0.0, 0.45],
                        ),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: Column(
                      children: [
                        // Header with Clock, Dynamic Tree & Greeting
                        Stack(
                          alignment: Alignment.bottomCenter,
                          clipBehavior: Clip.none,
                          children: [
                            // 1. Dynamic Living Tree rooted behind the card curve and framing the clock
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -32,
                              top: 15,
                              child: AnimatedBuilder(
                                animation: _spiritualEnergyController ?? const AlwaysStoppedAnimation(0.0),
                                builder: (context, _) {
                                  double? activeAnimatedProgress;
                                  double? activeBreeze;
                                  if (_spiritualEnergyController != null && _activeEnergySession != null) {
                                    final t = _spiritualEnergyController!.value;
                                    final curvedT = Curves.easeInOutCubic.transform(t);
                                    activeAnimatedProgress = ui.lerpDouble(
                                      _activeEnergySession!.previousProgress,
                                      _activeEnergySession!.targetProgress,
                                      curvedT,
                                    );
                                    final double breezeCycle = t * math.pi * 2 * (_activeEnergySession!.durationSeconds / 4.2);
                                    final double envelope = math.sin(t * math.pi);
                                    activeBreeze = (math.sin(breezeCycle) * 0.25 + math.sin(breezeCycle * 0.45) * 0.1) * envelope;
                                  }

                                  return GrowthTreeWidget(
                                    progress: combinedSpiritualProgress,
                                    khatmCount: appState.khatmCount,
                                    animatedProgress: activeAnimatedProgress,
                                    externalBreeze: activeBreeze,
                                  );
                                },
                              ),
                            ),

                            // Spiritual energy emerging from behind the curved card into the landscape
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: -32,
                              height: 80,
                              child: AnimatedBuilder(
                                animation: _spiritualEnergyController ??
                                    const AlwaysStoppedAnimation(0.0),
                                builder: (context, _) {
                                  if (_spiritualEnergyController == null ||
                                      _activeEnergySession == null) {
                                    return const SizedBox.shrink();
                                  }
                                  final t = _spiritualEnergyController!.value;
                                  final fade = math.sin(t * math.pi);
                                  final pulse =
                                      math.sin(t * math.pi * 6) * 0.15 + 0.85;
                                  const primary = Color(0xFF0284C7);
                                  const secondary = Color(0xFF38BDF8);

                                  return IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            secondary.withValues(
                                              alpha: 0.35 * fade * pulse,
                                            ),
                                            primary.withValues(
                                              alpha: 0.16 * fade * pulse,
                                            ),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.45, 1.0],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 2. Foreground: Greeting & Clock
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: _GreetingWidget(lang: lang),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () =>
                                                  LanguageSelectionDialog.show(
                                                    context,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.18,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(
                                                      alpha: 0.25,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.language_rounded,
                                                      color: Colors.white,
                                                      size: 15,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      lang.toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => appState
                                                  .navigatorKey.currentState
                                                  ?.push(
                                                AppPageRoute(
                                                  child:
                                                      const ReadingHistoryScreen(),
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(
                                                    alpha: 0.18,
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
                                          ),
                                          const SizedBox(width: 8),
                                          _buildHeaderBadge(
                                            context: context,
                                            icon: Icons.stars_rounded,
                                            value: "${appState.points} Pts",
                                            color: Colors.amber,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const RepaintBoundary(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: _ClockWidget(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Main Content (Scrollable)
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: const BorderRadius.only(
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
                                                      Translations.get(
                                                        lang,
                                                        'accessibility_required_banner',
                                                      ),
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
                                                    Translations.get(
                                                      lang,
                                                      'setup_now',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    _SpiritualEnergyBeamWrapper(
                                      animation: _spiritualEnergyController,
                                      session: _activeEnergySession,
                                      lang: lang,
                                      khatmCount: appState.khatmCount,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Last Read Card Header with Khatam Count outside the card
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                Translations.get(
                                                  lang,
                                                  'continue_journey',
                                                ).toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.teal.shade900
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              // Badge jumlah khatam di luar card
                                              Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    QuranProgressHelper
                                                        .showKhatamLevelInfoModal(
                                                      context,
                                                      lang,
                                                      appState.khatmCount,
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 9,
                                                      vertical: 3.5,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: appState.khatmCount >
                                                              0
                                                          ? Colors.amber.shade50
                                                          : Colors.teal.shade50
                                                              .withValues(
                                                                alpha: 0.7,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: appState.khatmCount >
                                                                0
                                                            ? Colors.amber.shade400
                                                            : Colors.teal.shade200
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                ),
                                                        width: 0.8,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .workspace_premium_rounded,
                                                          size: 13,
                                                          color: appState.khatmCount >
                                                                  0
                                                              ? const Color(
                                                                  0xFFD97706,
                                                                )
                                                              : Colors.teal.shade700,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          "${appState.khatmCount}x ${Translations.get(lang, 'khatam')}",
                                                          style: TextStyle(
                                                            color: appState.khatmCount >
                                                                    0
                                                                ? const Color(
                                                                    0xFF92400E,
                                                                  )
                                                                : Colors.teal.shade800,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
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

                                              return RepaintBoundary(
                                                child: _LastAyatCard(
                                                  surah:
                                                      appState.lastReadSurah,
                                                  ayahNumber:
                                                      appState.lastReadAyahNumber,
                                                  totalAyahs: totalAyahs,
                                                  currentSurahIdx:
                                                      appState.currentSurahIndex,
                                                  lang: lang,
                                                  khatmCount:
                                                      appState.khatmCount,
                                                  quranData:
                                                      appState.quranData,
                                                  onTap: () =>
                                                      _resumeReading(appState),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    Text(
                                      Translations.get(
                                        lang,
                                        'quick_actions',
                                      ).toUpperCase(),
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
                                    const RepaintBoundary(child: _QuickDock()),
                                    const SizedBox(height: 24),

                                    // Daily Hadith / Inspiration
                                    RepaintBoundary(
                                      child: _DailyInspiration(
                                        lang: lang,
                                        hadithText:
                                            appState.getDailyHadithText(lang),
                                        narrator: appState
                                            .getDailyHadithNarrator(lang),
                                        arabic: appState.dailyHadithArabic,
                                        onTap: () => appState
                                            .navigatorKey
                                            .currentState
                                            ?.push(
                                              AppPageRoute(
                                                child:
                                                    const HadithListScreen(),
                                              ),
                                            ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: _GridAction(
                                            icon: Icons.menu_book_rounded,
                                            title: Translations.get(
                                              lang,
                                              'read_quran',
                                            ),
                                            subtitle: Translations.get(
                                              lang,
                                              'total_surahs',
                                            ),
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
                                            title: Translations.get(
                                              lang,
                                              'your_apps',
                                            ),
                                            subtitle: Translations.get(
                                              lang,
                                              'open_apps',
                                            ),
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

                                    const SizedBox(height: 24),
                                    _SupportDeveloperCard(
                                      lang: lang,
                                      onTap: _openSupportDeveloperUrl,
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
    final lang = appState.languageCode;
    final hadithLabel = (lang == 'en' || lang == 'sw' || lang == 'af') ? 'Hadith' : (lang == 'ar' ? 'الحديث' : 'Hadits');

    final dzikirLabel = lang == 'ar'
        ? 'ذكر'
        : lang == 'ms'
        ? 'Zikir'
        : lang == 'id'
        ? 'Dzikir'
        : 'Dhikr';

    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildDockItem(
                context: context,
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),
            ),
            Expanded(
              child: _buildDockItem(
                context: context,
                icon: Icons.menu_book_rounded,
                label: 'Quran',
                isActive: false,
                onTap: () => appState.navigatorKey.currentState?.push(
                  AppPageRoute(child: const SurahListScreen()),
                ),
              ),
            ),
            Expanded(
              child: _buildDockItem(
                context: context,
                icon: Icons.grain_rounded,
                label: dzikirLabel,
                isActive: false,
                onTap: () => appState.navigatorKey.currentState?.push(
                  AppPageRoute(child: const DzikirScreen()),
                ),
              ),
            ),
            Expanded(
              child: _buildDockItem(
                context: context,
                icon: Icons.spa_rounded,
                label: hadithLabel,
                isActive: false,
                onTap: () => appState.navigatorKey.currentState?.push(
                  AppPageRoute(child: const HadithListScreen()),
                ),
              ),
            ),
            Expanded(
              child: _buildDockItem(
                context: context,
                icon: Icons.apps_rounded,
                label: 'Apps',
                isActive: false,
                onTap: () => appState.navigatorKey.currentState?.push(
                  AppPageRoute(child: const AppListScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        highlightColor: colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // M3 Expressive Pill Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: isActive ? 52 : 36,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.2,
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

class _GreetingWidget extends StatelessWidget {
  final String lang;
  const _GreetingWidget({required this.lang});

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Translations.get(lang, 'good_morning');
    if (hour < 15) return Translations.get(lang, 'good_afternoon');
    if (hour < 18) return Translations.get(lang, 'good_evening');
    return Translations.get(lang, 'good_night');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTimeGreeting(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          Translations.get(lang, 'user_title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      final now = DateTime.now();
      if (now.minute != _now.minute || now.hour != _now.hour) {
        if (mounted) setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              _hourString,
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
              _minuteString,
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
            _dateString.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _QuickDock ───────────────────────────────────────────────────────────────
class _QuickDock extends StatelessWidget {
  const _QuickDock();

  static const _channel = MethodChannel('com.muslimlauncher/apps');

  Future<void> _openApp(String pkg) async {
    try {
      await _channel.invokeMethod('openApp', {'packageName': pkg});
    } catch (_) {}
  }

  Future<void> _openPhoneApp() async {
    try {
      const intent = AndroidIntent(
        action: 'android.intent.action.DIAL',
      );
      await intent.launch();
    } catch (_) {
      try {
        await _channel.invokeMethod('openPhoneApp');
      } catch (_) {}
    }
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
    final bool isLoading = AppListScreen.cachedApps == null;
    final List<Widget> items = [];

    if (!isLoading) {
      // 1. Strict Phone Dialer App (Always Present at the Far Left)
      final phonePkg = _findFirstAvailable([
        'com.google.android.dialer',
        'com.samsung.android.dialer',
        'com.sec.android.app.dialer',
        'com.android.dialer',
        'com.android.phone',
      ]);

      if (phonePkg != null) {
        items.add(_buildIcon(Icons.phone_rounded, phonePkg, overrideTap: () async {
          try {
            await _openApp(phonePkg);
          } catch (_) {
            await _openPhoneApp();
          }
        }));
      } else {
        // Fallback: Direct native ACTION_DIAL intent call
        items.add(
          InkWell(
            onTap: _openPhoneApp,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.phone_rounded, color: Colors.teal.shade700, size: 24),
            ),
          ),
        );
      }

      // 2. Messages App
      final msgPkg = _findFirstAvailable([
        'com.google.android.apps.messaging',
        'com.android.messaging',
        'com.samsung.android.messaging',
      ]);
      if (msgPkg != null) {
        items.add(_buildIcon(Icons.message_rounded, msgPkg));
      }

      // 3. Contacts App
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

      // 6. Gallery / Photos
      final galleryPkg = _findFirstAvailable([
        'com.google.android.apps.photos',
        'com.android.gallery',
        'com.sec.android.gallery3d',
        'com.miui.gallery',
      ]);
      if (galleryPkg != null) {
        items.add(_buildIcon(Icons.photo_library_rounded, galleryPkg));
      }
    } else {
      // Instant Fallback Dock: Render immediately during startup using iconCache if available
      items.add(_buildIcon(Icons.phone_rounded, 'com.google.android.dialer', overrideTap: _openPhoneApp));
      items.add(_buildIcon(Icons.message_rounded, 'com.google.android.apps.messaging'));
      items.add(_buildIcon(Icons.people_alt_rounded, 'com.google.android.contacts'));
      items.add(_buildIcon(Icons.chat_bubble_rounded, 'com.whatsapp'));
      items.add(_buildIcon(Icons.photo_library_rounded, 'com.google.android.apps.photos'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((w) => Flexible(child: w)).toList(),
      ),
    );
  }

  Widget _buildIcon(IconData fallback, String pkg, {VoidCallback? overrideTap}) {
    return _DockIcon(
      fallback: fallback,
      pkg: pkg,
      overrideTap: overrideTap,
    );
  }
}

class _DockIcon extends StatefulWidget {
  final IconData fallback;
  final String pkg;
  final VoidCallback? overrideTap;

  const _DockIcon({
    required this.fallback,
    required this.pkg,
    this.overrideTap,
  });

  @override
  State<_DockIcon> createState() => _DockIconState();
}

class _DockIconState extends State<_DockIcon> {
  Future<void> _openApp(String pkg) async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.openApp(pkg);
  }

  @override
  void initState() {
    super.initState();
    if (!AppListScreen.iconCache.containsKey(widget.pkg)) {
      AppListScreen.loadIconOnDemand(widget.pkg).then((bytes) {
        if (mounted && bytes != null) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconBytes = AppListScreen.iconCache[widget.pkg];

    return InkWell(
      onTap: widget.overrideTap ?? () => _openApp(widget.pkg),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        child: iconBytes != null
            ? Image.memory(
                iconBytes,
                width: 44,
                height: 44,
                cacheWidth: 88,
                cacheHeight: 88,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              )
            : Icon(widget.fallback, color: Colors.teal.shade700, size: 24),
      ),
    );
  }
}

class _SpiritualEnergyBeamWrapper extends StatelessWidget {
  final Animation<double>? animation;
  final SpiritualEnergySession? session;
  final String? lang;
  final int? khatmCount;
  final Widget child;

  const _SpiritualEnergyBeamWrapper({
    required this.animation,
    required this.session,
    this.lang,
    this.khatmCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (animation == null || session == null) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation!,
      builder: (context, _) {
        final t = animation!.value;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Soft subtle golden light beam rendered behind the reading card & header
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GoldenLightBeamPainter(
                    progress: t,
                  ),
                ),
              ),
            ),

            // Foreground: Header row (text on left, badge on right) and reading card
            child,
          ],
        );
      },
    );
  }
}

class _GoldenLightBeamPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _GoldenLightBeamPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double fade = math.sin(progress * math.pi); // smooth entrance and exit
    if (fade <= 0.005) return;

    // Gentle calm breathing pulse
    final double pulse = math.sin(progress * math.pi * 5.0) * 0.10 + 0.90;

    // The top edge of _LastAyatCard is at y = 36.0 (below header row and gap)
    const double cardTopY = 36.0;
    const double beamTopY = -65.0;
    final double beamHeight = cardTopY - beamTopY;

    // Celestial blue palette - soft and subtle (samar-samar)
    const Color deepBlue = Color(0xFF0284C7);
    const Color radiantBlue = Color(0xFF38BDF8);
    const Color softCelestial = Color(0xFFE0F2FE);

    // 1. Broad soft ambient upward wash across the full width
    // Emerges gently from behind card top and permeates softly upward past the header row
    final Paint broadWashPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.5, cardTopY + 8.0),
        Offset(size.width * 0.5, beamTopY),
        [
          deepBlue.withValues(alpha: 0.18 * fade * pulse),
          radiantBlue.withValues(alpha: 0.11 * fade * pulse),
          radiantBlue.withValues(alpha: 0.04 * fade * pulse),
          radiantBlue.withValues(alpha: 0.0),
        ],
        [0.0, 0.35, 0.70, 1.0],
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-8.0, beamTopY, size.width + 16.0, beamHeight + 16.0),
        const Radius.circular(20),
      ),
      broadWashPaint,
    );

    // 2. Soft subtle radial glow centered behind the card top edge
    final Paint centerGlow = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, cardTopY),
        size.width * 0.50,
        [
          radiantBlue.withValues(alpha: 0.15 * fade * pulse),
          deepBlue.withValues(alpha: 0.07 * fade * pulse),
          deepBlue.withValues(alpha: 0.0),
        ],
        [0.0, 0.55, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTWH(-12.0, beamTopY, size.width + 24.0, beamHeight + 16.0),
      centerGlow,
    );

    // 3. Delicate, subtle vertical light rays (samar-samar sunbeams)
    // Distributed across the width, rising gently upward into the upper space
    const int rayCount = 6;
    for (int i = 0; i < rayCount; i++) {
      final double rayX = size.width * (0.12 + i * 0.15);
      final double phase = progress * 3.5 + i * 1.25;
      final double shimmer = math.sin(phase) * 0.12 + 0.88;
      final double rayAlpha = (0.09 * shimmer * fade * pulse).clamp(0.0, 1.0);
      final double rayWidth = 14.0 + (i % 2) * 6.0;
      final double currentRayTop = beamTopY + (i % 3) * 8.0;

      final Paint rayPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(rayX, cardTopY + 5.0),
          Offset(rayX, currentRayTop),
          [
            softCelestial.withValues(alpha: rayAlpha * 1.0),
            radiantBlue.withValues(alpha: rayAlpha * 0.7),
            radiantBlue.withValues(alpha: 0.0),
          ],
          [0.0, 0.45, 1.0],
        );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rayX - rayWidth / 2,
            currentRayTop,
            rayWidth,
            cardTopY - currentRayTop + 8.0,
          ),
          Radius.circular(rayWidth / 2),
        ),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldenLightBeamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _LastAyatCard extends StatelessWidget {
  final String surah;
  final int ayahNumber;
  final int totalAyahs;
  final int currentSurahIdx;
  final String lang;
  final int khatmCount;
  final List<dynamic> quranData;
  final VoidCallback onTap;

  const _LastAyatCard({
    required this.surah,
    required this.ayahNumber,
    required this.totalAyahs,
    required this.currentSurahIdx,
    required this.lang,
    required this.khatmCount,
    required this.quranData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final int surahNumber = surah.isNotEmpty ? currentSurahIdx + 1 : 1;
    final int safeAyah =
        surah.isNotEmpty ? (ayahNumber > 0 ? ayahNumber : 1) : 1;
    final int juzNumber =
        QuranProgressHelper.getJuzNumber(surahNumber, safeAyah);
    final KhatamPhase currentPhase =
        QuranProgressHelper.getPhase(juzNumber);
    final String phaseEncouragement =
        QuranProgressHelper.getPhaseEncouragement(currentPhase, lang);
    final double overallProgress = QuranProgressHelper.getOverallProgress(
      currentSurahIdx,
      ayahNumber,
      quranData,
    );
    final String percentStr = (overallProgress * 100).toStringAsFixed(1);
    final int levelNum = QuranProgressHelper.getMaqamLevel(khatmCount);
    final String levelPrefix = Translations.get(lang, 'level_prefix');
    final String maqamTitle =
        QuranProgressHelper.getMaqamTitle(khatmCount, lang);

    final bool hasKhatam = khatmCount > 0;
    final String khatamBadgeText = "$levelPrefix $levelNum: $maqamTitle";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header Row: Tingkatan Khatam & Maqam on left, Real-time Juz on right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              QuranProgressHelper.showKhatamLevelInfoModal(
                                context,
                                lang,
                                khatmCount,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: hasKhatam
                                    ? Colors.amber.shade50
                                    : colorScheme.primaryContainer
                                        .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: hasKhatam
                                      ? Colors.amber.shade400
                                      : colorScheme.primary
                                          .withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasKhatam
                                        ? Icons.workspace_premium_rounded
                                        : Icons.military_tech_rounded,
                                    size: 13.5,
                                    color: hasKhatam
                                        ? const Color(0xFFD97706)
                                        : colorScheme.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      khatamBadgeText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: hasKhatam
                                            ? const Color(0xFF92400E)
                                            : colorScheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 13,
                                    color: hasKhatam
                                        ? const Color(0xFFD97706)
                                        : colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "Juz $juzNumber / 30",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 2. Middle Row: Book Icon + Surah Info + Play CTA
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.primary
                                .withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: colorScheme.primary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.isEmpty
                                  ? Translations.get(lang, 'start_reading')
                                  : surah,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              surah.isEmpty
                                  ? Translations.get(lang, 'find_guidance_today')
                                  : "${Translations.get(lang, 'ayah')} $ayahNumber • Surah ${currentSurahIdx + 1}/114",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary
                                  .withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3. Progress Section: Encouragement + Progress % + Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                phaseEncouragement,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        surah.isEmpty ? '0.0%' : '$percentStr%',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // Visual Progress Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double barWidth = constraints.maxWidth;
                      final double fillWidth =
                          (barWidth * overallProgress).clamp(0.0, barWidth);

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          // Base track
                          Container(
                            width: barWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),

                          // Active Fill
                          Container(
                            width: fillWidth,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.8),
                                  colorScheme.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 148),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _DailyInspiration ────────────────────────────────────────────────────────
class _DailyInspiration extends StatelessWidget {
  final String lang;
  final String hadithText;
  final String narrator;
  final String arabic;
  final VoidCallback? onTap;

  const _DailyInspiration({
    required this.lang,
    required this.hadithText,
    required this.narrator,
    this.arabic = '',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = hadithText.length < 60
        ? 18
        : hadithText.length < 120
        ? 16
        : hadithText.length < 200
        ? 14.5
        : 13.5;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F5E3B),
            Color(0xFF094027),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5C3A).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.amber,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            Translations.get(lang, 'insight_of_the_day'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.format_quote_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  hadithText.isNotEmpty
                      ? '"$hadithText"'
                      : '"${Translations.get(lang, 'daily_inspiration_default')}"',
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFFBFDFC),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
                if (narrator.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      narrator,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _SupportDeveloperCard ───────────────────────────────────────────────────
class _SupportDeveloperCard extends StatelessWidget {
  final String lang;
  final VoidCallback onTap;

  const _SupportDeveloperCard({required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get(lang, 'support_feature_request'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      Translations.get(lang, 'free_ad_free_app'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            Translations.get(lang, 'support_dev_long_desc'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.coffee_rounded, size: 20),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppState.getSupportButtonText(lang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFC2410C),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
