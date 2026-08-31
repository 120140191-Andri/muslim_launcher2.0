import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../../providers/app_state.dart';
import '../home/home_screen.dart';
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
      final url = lang == 'id'
          ? 'https://trakteer.id/andri_setiawan108/tip'
          : 'https://ko-fi.com/andrisetiawan84153';
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
    appState.completeOnboarding();
    appState.navigatorKey.currentState?.pushAndRemoveUntil(
      AppPageRoute(child: const HomeScreen()),
      (route) => false,
    );
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
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F5132),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.isOnboarding,
        title: Text(
          isEn ? 'Launcher Setup Hub' : 'Pusat Pengaturan Launcher',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header with Progress & Device Info ────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0F5132),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                children: [
                  // Phone badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Setup Progress' : 'Progres Pengaturan',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$completedCount / 4 ${isEn ? 'Completed' : 'Selesai'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0 ? Colors.amber : const Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Interactive Checklist Items ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // STEP 1: Language
                  _buildStepCard(
                    index: 0,
                    stepNum: 1,
                    title: Translations.get(lang, 'language_selection'),
                    subtitle: '${_getLanguageDisplayName(lang)} - ${Translations.get(lang, 'done')}',
                    icon: Icons.language_rounded,
                    isDone: true,
                    instructions: [],
                    actionWidget: OutlinedButton.icon(
                      onPressed: () => LanguageSelectionDialog.show(context),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(Translations.get(lang, 'change_language')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F5132),
                        side: const BorderSide(color: Color(0xFF0F5132)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    actionWidget: ElevatedButton.icon(
                      onPressed: _openHomeSettings,
                      icon: Icon(isDefault ? Icons.settings_rounded : Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        isDefault
                            ? (isEn ? 'Check Home Settings' : 'Cek Pengaturan Beranda')
                            : (isEn ? 'Open Home Settings' : 'Buka Pengaturan Beranda'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDefault ? Colors.grey.shade200 : const Color(0xFF0F5132),
                        foregroundColor: isDefault ? const Color(0xFF0F5132) : Colors.white,
                        elevation: isDefault ? 0 : 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    actionWidget: ElevatedButton.icon(
                      onPressed: _openAccessibilitySettings,
                      icon: Icon(isAccess ? Icons.verified_rounded : Icons.lock_open_rounded, size: 18),
                      label: Text(
                        isAccess
                            ? (isEn ? 'View Accessibility Settings' : 'Lihat Pengaturan Aksesibilitas')
                            : (isEn ? 'Open Accessibility Settings' : 'Buka Pengaturan Aksesibilitas'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAccess ? Colors.grey.shade200 : const Color(0xFF0F5132),
                        foregroundColor: isAccess ? const Color(0xFF0F5132) : Colors.white,
                        elevation: isAccess ? 0 : 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            backgroundColor: const Color(0xFF0F5132),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        if (!isAutostart) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => appState.setHasAcknowledgedAutostart(true),
                            child: Text(
                              isEn ? 'Mark as Configured' : 'Tandai Sudah Selesai',
                              style: TextStyle(color: Colors.teal.shade800, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Support Developer Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade700, Colors.orange.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade900.withValues(alpha: 0.2),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'Support / Request Features' : 'Dukung / Usulkan Fitur',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEn
                                        ? 'Help us keep this app free & ad-free'
                                        : 'Bantu kami menjaga aplikasi ini tetap gratis & tanpa iklan',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openSupportDeveloperUrl(lang),
                            icon: const Icon(Icons.coffee_rounded, size: 18),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                isEn ? 'Support / Request Features via Ko-fi' : 'Dukung / Usulkan Fitur via Trakteer',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange.shade900,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── Bottom Completion Action ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (isDefault && isAccess) ? _finishSetup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F5132),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: (isDefault && isAccess) ? 4 : 0,
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (isDefault && isAccess) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
  }) {
    final bool isExpanded = _expandedStepIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? const Color(0xFF86EFAC) : (isExpanded ? const Color(0xFF0F5132) : Colors.grey.shade200),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? const Color(0xFF0F5132).withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
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
            borderRadius: BorderRadius.circular(20),
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
                          ? const Color(0xFFDCFCE7)
                          : (isExpanded ? const Color(0xFFE6F4EA) : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle_rounded : icon,
                      color: isDone ? const Color(0xFF166534) : const Color(0xFF0F5132),
                      size: 24,
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
                              'STEP $stepNum',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: isDone ? const Color(0xFF166534) : const Color(0xFF0F5132),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isDone)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'AKTIF / READY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand Chevron
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instructions.isNotEmpty) ...[
                    Text(
                      'INSTRUKSI KHUSUS HP ANDA:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(instructions.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade900,
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
                                  height: 1.4,
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
