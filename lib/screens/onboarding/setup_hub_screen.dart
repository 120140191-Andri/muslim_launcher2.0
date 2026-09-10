import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../../providers/app_state.dart';
import '../home/home_screen.dart';
import '../home/app_list_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';
import '../../utils/device_instructions.dart';
import '../../widgets/language_selection_dialog.dart';

class SetupHubScreen extends StatefulWidget {
  final bool isOnboarding;
  const SetupHubScreen({super.key, this.isOnboarding = true});

  @override
  State<SetupHubScreen> createState() => _SetupHubScreenState();
}

class _SetupHubScreenState extends State<SetupHubScreen>
    with WidgetsBindingObserver {
  Timer? _statusTimer;
  int? _expandedStepIndex; 

  late AppState _appStateRef;
  bool _prevIsDefault = false;
  bool _prevIsAccess = false;
  bool _prevIsAutostart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Store reference for safe dispose
    _appStateRef = Provider.of<AppState>(context, listen: false);
    _prevIsDefault = _appStateRef.isDefaultLauncher;
    _prevIsAccess = _appStateRef.isAccessibilityEnabled;
    _prevIsAutostart = _appStateRef.hasAcknowledgedAutostart;

    // Fast check on enter
    _appStateRef.refreshStatus();

    // Auto expand first incomplete step
    _autoExpandNextStep();

    // Periodic check while screen is open
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.refreshStatus();
        _handleStepTransitions(appState);
      }
    });
  }

  void _handleStepTransitions(AppState appState) {
    bool hasChanged = false;
    
    if (appState.isDefaultLauncher != _prevIsDefault) {
      _prevIsDefault = appState.isDefaultLauncher;
      hasChanged = true;
    }
    if (appState.isAccessibilityEnabled != _prevIsAccess) {
      _prevIsAccess = appState.isAccessibilityEnabled;
      hasChanged = true;
    }
    if (appState.hasAcknowledgedAutostart != _prevIsAutostart) {
      _prevIsAutostart = appState.hasAcknowledgedAutostart;
      hasChanged = true;
    }

    if (hasChanged && mounted) {
      setState(() {});
      _autoExpandNextStep();
    }
  }

  void _autoExpandNextStep() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (!appState.hasSelectedLanguage) {
      _expandedStepIndex = 0;
    } else if (!appState.isDefaultLauncher) {
      _expandedStepIndex = 1;
    } else if (!appState.isAccessibilityEnabled) {
      _expandedStepIndex = 2;
    } else if (!appState.hasAcknowledgedAutostart) {
      _expandedStepIndex = 3;
    } else {
      _expandedStepIndex = null; // All done
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshStatus();
      _handleStepTransitions(appState);
    }
  }

  Future<void> _openSupportDeveloperUrl(String lang) async {
    try {
      final url = AppState.getSupportUrl(lang);
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
      );
      await intent.launch();
    } catch (_) {}
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _openHomeSettings() {
    try {
      const intent = AndroidIntent(action: 'android.settings.HOME_SETTINGS');
      intent.launch();
    } catch (_) {
      const intent = AndroidIntent(action: 'android.settings.SETTINGS');
      intent.launch();
    }
  }

  void _openAccessibilitySettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.appBlockService.openAccessibilitySettings();
  }

  void _openAutostartSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.appBlockService.openAutostartSettings();
  }

  void _finishSetup() {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;

    // Show a sleek loading dialog while ensuring app icons are loaded
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F5E3B),
                  Color(0xFF083C25),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: Color(0xFF34D399),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  Translations.get(lang, 'setup_preparing_home'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  Translations.get(lang, 'setup_loading_apps'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Await preload completion with a safe timeout
    AppListScreen.preload(
      onRawAppsFetched: (raw) {
        appState.syncAppsWithCategories(raw);
      },
    ).timeout(
      const Duration(milliseconds: 3500),
      onTimeout: () {},
    ).whenComplete(() {
      if (mounted) {
        appState.completeOnboarding();
        appState.navigatorKey.currentState?.pushAndRemoveUntil(
          AppPageRoute(child: const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  // ── UI Builder ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final isEn = lang == 'en';
    final manufacturer = appState.manufacturer;
    final model = appState.deviceModel;

    final isDefault = appState.isDefaultLauncher;
    final isAccess = appState.isAccessibilityEnabled;
    final isAutostart = appState.hasAcknowledgedAutostart;

    // Calculate completion progress
    int completedCount = 1; // Language is step 0 (done)
    if (isDefault) completedCount++;
    if (isAccess) completedCount++;
    if (isAutostart) completedCount++;
    final double progress = completedCount / 4.0;

    final String brandDisplay = manufacturer.isNotEmpty
        ? (manufacturer[0].toUpperCase() + manufacturer.substring(1))
        : "Android";
    final String modelDisplay = model.isNotEmpty ? model.toUpperCase() : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Column(
        children: [
          // ── Top Header with Emerald Gradient, Progress & Device Info ─────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F5E3B),
                  Color(0xFF083C25),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D5C3A).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    // Top Appbar Row
                    Row(
                      children: [
                        if (!widget.isOnboarding)
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => Navigator.maybePop(context),
                          )
                        else
                          const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isEn ? 'Launcher Setup Hub' : 'Pusat Pengaturan Launcher',
                            textAlign: widget.isOnboarding ? TextAlign.center : TextAlign.start,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (!widget.isOnboarding)
                          const SizedBox(width: 48)
                        else
                          const SizedBox(width: 4),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Phone badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.smartphone_rounded, color: Color(0xFF34D399), size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isEn
                                  ? 'Device: $brandDisplay $modelDisplay'
                                  : 'HP Anda: $brandDisplay $modelDisplay',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress text & count pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEn ? 'Setup Progress' : 'Progres Pengaturan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: progress == 1.0
                                ? Colors.amber.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: progress == 1.0
                                  ? Colors.amber.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (progress == 1.0) ...[
                                const Icon(Icons.check_circle_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '$completedCount / 4 ${Translations.get(lang, 'done')}',
                                style: TextStyle(
                                  color: progress == 1.0 ? Colors.amber : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0 ? Colors.amber : const Color(0xFF34D399),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Interactive Checklist Items ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              children: [
                // STEP 1: Language
                _buildStepCard(
                  index: 0,
                  stepNum: 1,
                  title: Translations.get(lang, 'language_selection'),
                  subtitle: '${_getLanguageDisplayName(lang)} • ${Translations.get(lang, 'done')}',
                  icon: Icons.language_rounded,
                  isDone: true,
                  instructions: const [],
                  brandDisplay: brandDisplay,
                  isEn: isEn,
                  lang: lang,
                  actionWidget: OutlinedButton.icon(
                    onPressed: () => LanguageSelectionDialog.show(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(Translations.get(lang, 'change_language')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D5C3A),
                      side: const BorderSide(color: Color(0xFF0D5C3A), width: 1.4),
                      backgroundColor: const Color(0xFF0D5C3A).withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // STEP 2: Default Launcher
                _buildStepCard(
                  index: 1,
                  stepNum: 2,
                  title: isEn ? 'Set Default Home Launcher' : 'Jadikan Launcher Utama',
                  subtitle: isDefault
                      ? (isEn ? 'Muslim Launcher 2 is active' : 'Muslim Launcher 2 sudah aktif')
                      : (isEn ? 'Action required for home screen' : 'Tindakan diperlukan untuk layar beranda'),
                  icon: Icons.home_rounded,
                  isDone: isDefault,
                  instructions: DeviceInstructions.getHomeInstructions(manufacturer, lang),
                  brandDisplay: brandDisplay,
                  isEn: isEn,
                  lang: lang,
                  actionWidget: isDefault
                      ? OutlinedButton.icon(
                          onPressed: _openHomeSettings,
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(isEn ? 'Check Home Settings' : 'Cek Pengaturan Beranda'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D5C3A),
                            side: BorderSide(color: const Color(0xFF0D5C3A).withValues(alpha: 0.4)),
                            backgroundColor: const Color(0xFF0D5C3A).withValues(alpha: 0.04),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _openHomeSettings,
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(isEn ? 'Open Home Settings' : 'Buka Pengaturan Beranda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5C3A),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFF0D5C3A).withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                ),
                const SizedBox(height: 14),

                // STEP 3: Accessibility Service
                _buildStepCard(
                  index: 2,
                  stepNum: 3,
                  title: isEn ? 'Accessibility Service (Blocker)' : 'Layanan Aksesibilitas (Pemblokir)',
                  subtitle: isAccess
                      ? (isEn ? 'App blocker service is running' : 'Sistem pemblokir aktif di latar belakang')
                      : (isEn ? 'Required for real-time app blocking' : 'Dibutuhkan agar pemblokir berfungsi real-time'),
                  icon: Icons.security_rounded,
                  isDone: isAccess,
                  instructions: DeviceInstructions.getAccessibilityInstructions(manufacturer, lang),
                  brandDisplay: brandDisplay,
                  isEn: isEn,
                  lang: lang,
                  actionWidget: isAccess
                      ? OutlinedButton.icon(
                          onPressed: _openAccessibilitySettings,
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: Text(isEn ? 'View Accessibility Settings' : 'Lihat Pengaturan Aksesibilitas'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D5C3A),
                            side: BorderSide(color: const Color(0xFF0D5C3A).withValues(alpha: 0.4)),
                            backgroundColor: const Color(0xFF0D5C3A).withValues(alpha: 0.04),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _openAccessibilitySettings,
                          icon: const Icon(Icons.lock_open_rounded, size: 18),
                          label: Text(isEn ? 'Open Accessibility Settings' : 'Buka Pengaturan Aksesibilitas'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D5C3A),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: const Color(0xFF0D5C3A).withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                ),
                const SizedBox(height: 14),

                // STEP 4: Autostart & Battery
                _buildStepCard(
                  index: 3,
                  stepNum: 4,
                  title: isEn ? 'Autostart & Battery Opt.' : 'Mulai Otomatis & Opt. Baterai',
                  subtitle: isAutostart
                      ? (isEn ? 'Autostart configured for $brandDisplay' : 'Autostart sudah disesuaikan untuk $brandDisplay')
                      : (isEn ? 'Prevent OS from killing background blocker' : 'Cegah sistem mematikan pemblokir di latar belakang'),
                  icon: Icons.bolt_rounded,
                  isDone: isAutostart,
                  instructions: DeviceInstructions.getAutostartInstructions(manufacturer, lang),
                  brandDisplay: brandDisplay,
                  isEn: isEn,
                  lang: lang,
                  actionWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _openAutostartSettings();
                          appState.setHasAcknowledgedAutostart(true);
                        },
                        icon: const Icon(Icons.speed_rounded, size: 18),
                        label: Text(
                          isEn ? 'Configure Autostart & Battery' : 'Atur Autostart & Baterai',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C3A),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFF0D5C3A).withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      if (!isAutostart) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => appState.setHasAcknowledgedAutostart(true),
                          child: Text(
                            Translations.get(lang, 'mark_as_configured'),
                            style: const TextStyle(
                              color: Color(0xFF0D5C3A),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Support Developer Card (Matching HomeScreen) ──────────
                Container(
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
                          onPressed: () => _openSupportDeveloperUrl(lang),
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
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Bottom Completion Action ──────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: (isDefault && isAccess)
                      ? const LinearGradient(
                          colors: [Color(0xFF0F5E3B), Color(0xFF094027)],
                        )
                      : null,
                  boxShadow: (isDefault && isAccess)
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0D5C3A).withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: (isDefault && isAccess) ? _finishSetup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isDefault && isAccess) ? Colors.transparent : Colors.grey.shade200,
                    foregroundColor: (isDefault && isAccess) ? Colors.white : Colors.grey.shade500,
                    disabledBackgroundColor: Colors.grey.shade200,
                    disabledForegroundColor: Colors.grey.shade400,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            (isDefault && isAccess)
                                ? (isEn ? 'START USING MUSLIM LAUNCHER 2' : 'MULAI GUNAKAN MUSLIM LAUNCHER 2')
                                : (isEn ? 'COMPLETE SETTINGS (STEP 2 & 3)' : 'SELESAIKAN PENGATURAN UTAMA (LANGKAH 2 & 3)'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: (isDefault && isAccess) ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      if (isDefault && isAccess) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step Card Widget ────────────────────────────────────────────────────────

  Widget _buildStepCard({
    required int index,
    required int stepNum,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDone,
    required List<String> instructions,
    required Widget actionWidget,
    String brandDisplay = 'Android',
    bool isEn = false,
    String? lang,
  }) {
    final bool isExpanded = _expandedStepIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone
              ? const Color(0xFF0D5C3A).withValues(alpha: 0.22)
              : (isExpanded ? const Color(0xFF0D5C3A) : Colors.black.withValues(alpha: 0.06)),
          width: isExpanded ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? const Color(0xFF0D5C3A).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.025),
            blurRadius: isExpanded ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () {
              setState(() {
                _expandedStepIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Step Badge / Check Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF0D5C3A).withValues(alpha: 0.1)
                          : (isExpanded
                              ? const Color(0xFF0D5C3A).withValues(alpha: 0.08)
                              : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle_rounded : icon,
                      color: isDone
                          ? const Color(0xFF0D5C3A)
                          : (isExpanded ? const Color(0xFF0D5C3A) : Colors.grey.shade600),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isEn ? 'STEP $stepNum' : 'LANGKAH $stepNum',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: isDone
                                    ? const Color(0xFF0D5C3A)
                                    : const Color(0xFF0D5C3A).withValues(alpha: 0.75),
                              ),
                            ),
                            if (isDone) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D5C3A).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_rounded, color: Color(0xFF0D5C3A), size: 11),
                                    const SizedBox(width: 3),
                                    Text(
                                      Translations.get(lang ?? 'id', 'done').toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF0D5C3A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand Chevron
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? const Color(0xFF0D5C3A).withValues(alpha: 0.08)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? const Color(0xFF0D5C3A) : Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instructions.isNotEmpty) ...[
                    Text(
                      isEn ? 'SPECIAL INSTRUCTIONS FOR $brandDisplay:' : 'PANDUAN KHUSUS HP $brandDisplay:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF0D5C3A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(instructions.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D5C3A).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D5C3A),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                instructions[i],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF374151),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  actionWidget,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Melayu';
      case 'ar':
        return 'العربية';
      case 'af':
        return 'Afrikaans';
      case 'sw':
        return 'Kiswahili';
      default:
        return code.toUpperCase();
    }
  }
}
