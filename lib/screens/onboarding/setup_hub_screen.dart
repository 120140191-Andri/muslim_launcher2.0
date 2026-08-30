import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../../providers/app_state.dart';
import '../home/home_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';

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
    
    _appStateRef = Provider.of<AppState>(context, listen: false);
    _prevIsDefault = _appStateRef.isDefaultLauncher;
    _prevIsAccess = _appStateRef.isAccessibilityEnabled;
    _prevIsAutostart = _appStateRef.hasAcknowledgedAutostart;
    
    // Auto-expand first incomplete step initially
    if (!_prevIsDefault) {
      _expandedStepIndex = 1;
    } else if (!_prevIsAccess) {
      _expandedStepIndex = 2;
    } else if (!_prevIsAutostart) {
      _expandedStepIndex = 3;
    }

    _appStateRef.addListener(_onAppStateChanged);

    _refreshAllStatus();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshAllStatus(),
    );
  }

  void _onAppStateChanged() {
    final currentIsDefault = _appStateRef.isDefaultLauncher;
    final currentIsAccess = _appStateRef.isAccessibilityEnabled;
    final currentIsAutostart = _appStateRef.hasAcknowledgedAutostart;

    bool shouldUpdate = false;
    if (currentIsDefault && !_prevIsDefault) {
      _expandedStepIndex = 2; // Auto expand step 3
      shouldUpdate = true;
    } else if (currentIsAccess && !_prevIsAccess) {
      _expandedStepIndex = 3; // Auto expand step 4
      shouldUpdate = true;
    } else if (currentIsAutostart && !_prevIsAutostart) {
      _expandedStepIndex = null;
      shouldUpdate = true;
    }

    _prevIsDefault = currentIsDefault;
    _prevIsAccess = currentIsAccess;
    _prevIsAutostart = currentIsAutostart;

    if (shouldUpdate && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appStateRef.removeListener(_onAppStateChanged);
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllStatus();
    }
  }

  void _refreshAllStatus() {
    _appStateRef.refreshStatus();
  }

  Future<void> _openSupportDeveloperUrl() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final url = appState.languageCode == 'id'
          ? 'https://trakteer.id/andri_setiawan108/tip'
          : 'https://ko-fi.com/andrisetiawan84153';
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: url,
      );
      await intent.launch();
    } catch (_) {}
  }

  // ── Brand-Specific Instructions Builder ─────────────────────────────────────

  List<String> _getHomeInstructions(String brand, bool isEn) {
    final b = brand.toLowerCase();
    if (b.contains('xiaomi') || b.contains('poco') || b.contains('redmi') || b.contains('blackshark')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Look for "Default launcher" option.' : 'Pilih menu "Peluncur Utama / Beranda".',
        isEn ? 'Select "Muslim Launcher 2".' : 'Pilih "Muslim Launcher 2".',
        isEn ? 'Tap "Always" if prompted by MIUI/HyperOS.' : 'Konfirmasi dan pilih "Selalu" jika muncul dialog.',
      ];
    } else if (b.contains('samsung')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Select "Home app" from list.' : 'Pilih menu "Aplikasi Beranda".',
        isEn ? 'Choose "Muslim Launcher 2".' : 'Pilih "Muslim Launcher 2".',
      ];
    } else if (b.contains('oppo') || b.contains('oneplus') || b.contains('realme')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Go to Default Apps -> Home App.' : 'Masuk ke Aplikasi Default -> Aplikasi Beranda.',
        isEn ? 'Set to "Muslim Launcher 2".' : 'Setel ke "Muslim Launcher 2".',
      ];
    } else if (b.contains('vivo') || b.contains('iqoo')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Select Default App Settings -> Home app.' : 'Pilih Pengaturan Aplikasi Default -> Beranda.',
        isEn ? 'Enable "Muslim Launcher 2".' : 'Aktifkan "Muslim Launcher 2".',
      ];
    } else if (b.contains('infinix') || b.contains('tecno') || b.contains('itel') || b.contains('transsion')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Select XOS / HiOS Home app settings.' : 'Pilih menu Aplikasi Beranda (Desktop).',
        isEn ? 'Switch default to "Muslim Launcher 2".' : 'Ubah launcher default ke "Muslim Launcher 2".',
      ];
    } else if (b.contains('huawei') || b.contains('honor')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Go to Apps -> Default Apps -> Launcher.' : 'Masuk ke Aplikasi -> Aplikasi Default -> Peluncur.',
        isEn ? 'Select "Muslim Launcher 2".' : 'Pilih "Muslim Launcher 2".',
      ];
    } else if (b.contains('asus')) {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Go to ZenUI Launcher / Apps -> Default Apps.' : 'Masuk ke Aplikasi -> Aplikasi Default -> Beranda.',
        isEn ? 'Select "Muslim Launcher 2".' : 'Pilih "Muslim Launcher 2".',
      ];
    } else {
      return [
        isEn ? 'Tap "Open Home Settings" below.' : 'Ketuk "Buka Pengaturan Beranda" di bawah.',
        isEn ? 'Find "Default apps" or "Home app".' : 'Cari "Aplikasi Default" atau "Aplikasi Beranda".',
        isEn ? 'Select "Muslim Launcher 2".' : 'Pilih "Muslim Launcher 2".',
      ];
    }
  }

  List<String> _getAccessibilityInstructions(String brand, bool isEn) {
    final b = brand.toLowerCase();
    if (b.contains('xiaomi') || b.contains('poco') || b.contains('redmi') || b.contains('blackshark')) {
      return [
        isEn ? 'Tap "Open Accessibility Settings" below.' : 'Ketuk "Buka Pengaturan Aksesibilitas".',
        isEn ? 'Tap "Downloaded Apps" (Aplikasi Terunduh).' : 'Pilih menu "Aplikasi Terunduh / Downloaded Apps".',
        isEn ? 'Select "Muslim Launcher 2".' : 'Pilih "Muslim Launcher 2".',
        isEn ? 'Turn ON "Use Muslim Launcher 2".' : 'Aktifkan sakelar "Gunakan Muslim Launcher 2".',
      ];
    } else if (b.contains('samsung')) {
      return [
        isEn ? 'Tap "Open Accessibility Settings" below.' : 'Ketuk "Buka Pengaturan Aksesibilitas".',
        isEn ? 'Select "Installed Apps" or "Installed Services".' : 'Pilih "Layanan Terinstal / Installed Apps".',
        isEn ? 'Tap "Muslim Launcher 2" and turn ON.' : 'Pilih "Muslim Launcher 2" lalu aktifkan sakelar.',
      ];
    } else if (b.contains('oppo') || b.contains('oneplus') || b.contains('realme') || b.contains('vivo') || b.contains('iqoo')) {
      return [
        isEn ? 'Tap "Open Accessibility Settings" below.' : 'Ketuk "Buka Pengaturan Aksesibilitas".',
        isEn ? 'Find "Muslim Launcher 2" under Accessibility Services.' : 'Cari "Muslim Launcher 2" di daftar layanan.',
        isEn ? 'Enable the switch and grant permissions.' : 'Aktifkan sakelar dan izinkan akses.',
      ];
    } else if (b.contains('huawei') || b.contains('honor')) {
      return [
        isEn ? 'Tap "Open Accessibility Settings" below.' : 'Ketuk "Buka Pengaturan Aksesibilitas".',
        isEn ? 'Go to Accessibility -> Installed Services.' : 'Masuk ke Aksesibilitas -> Layanan Terinstal.',
        isEn ? 'Enable "Muslim Launcher 2".' : 'Aktifkan "Muslim Launcher 2".',
      ];
    } else {
      return [
        isEn ? 'Tap "Open Accessibility Settings" below.' : 'Ketuk "Buka Pengaturan Aksesibilitas".',
        isEn ? 'Find "Muslim Launcher 2" in the list.' : 'Cari "Muslim Launcher 2" di daftar aplikasi.',
        isEn ? 'Turn ON the switch & confirm warnings.' : 'Aktifkan sakelar & klik Izinkan.',
      ];
    }
  }

  List<String> _getAutostartInstructions(String brand, bool isEn) {
    final b = brand.toLowerCase();
    if (b.contains('xiaomi') || b.contains('poco') || b.contains('redmi') || b.contains('blackshark')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Find "Muslim Launcher 2" & Enable "Autostart".' : 'Cari "Muslim Launcher 2" & aktifkan "Mulai Otomatis".',
        isEn ? 'Tap the app -> "Battery Saver" -> "No restrictions".' : 'Ketuk aplikasinya -> "Penghemat Baterai" -> "Tanpa Pembatasan".',
      ];
    } else if (b.contains('samsung')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Go to Battery -> Background usage limits.' : 'Masuk ke Baterai -> Batas penggunaan latar belakang.',
        isEn ? 'Add Muslim Launcher 2 to "Never sleeping apps".' : 'Tambahkan Muslim Launcher 2 ke "Aplikasi yang tidak pernah tidur".',
      ];
    } else if (b.contains('oppo') || b.contains('oneplus') || b.contains('realme')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Find "Muslim Launcher 2" & Enable "Allow auto-launch".' : 'Cari "Muslim Launcher 2" & aktifkan "Izinkan Mulai Otomatis".',
        isEn ? 'Allow background activity.' : 'Izinkan aktivitas latar belakang.',
      ];
    } else if (b.contains('vivo') || b.contains('iqoo')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Find "Muslim Launcher 2" & Enable "Autostart".' : 'Cari "Muslim Launcher 2" & aktifkan "Mulai Otomatis".',
      ];
    } else if (b.contains('huawei') || b.contains('honor')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Go to App Launch -> Turn off Automatic for Muslim Launcher 2.' : 'Masuk ke Peluncuran Aplikasi -> Matikan Otomatis untuk Muslim Launcher 2.',
        isEn ? 'Enable Auto-launch, Secondary Launch & Run in background.' : 'Aktifkan Peluncuran Otomatis, Peluncuran Sekunder & Latar Belakang.',
      ];
    } else if (b.contains('infinix') || b.contains('tecno') || b.contains('itel') || b.contains('transsion')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Open Phone Manager -> Auto-start management.' : 'Buka Pengelola Telepon -> Manajemen Mulai Otomatis.',
        isEn ? 'Enable Muslim Launcher 2 auto-start switch.' : 'Aktifkan sakelar mulai otomatis Muslim Launcher 2.',
      ];
    } else if (b.contains('asus')) {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Open Mobile Manager -> Auto-start Manager.' : 'Buka Manajer Seluler -> Manajer Mulai Otomatis.',
        isEn ? 'Allow Muslim Launcher 2 to auto-start.' : 'Izinkan Muslim Launcher 2 mulai otomatis.',
      ];
    } else {
      return [
        isEn ? 'Tap "Configure Autostart & Battery" below.' : 'Ketuk "Atur Autostart & Baterai" di bawah.',
        isEn ? 'Select Battery -> Set to "Unrestricted".' : 'Pilih menu Baterai -> Ubah ke "Tanpa Pembatasan".',
        isEn ? 'Allow auto-start in background if available.' : 'Izinkan jalankan otomatis jika ada pilihan.',
      ];
    }
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
                    title: isEn ? 'Language Setting' : 'Pengaturan Bahasa',
                    subtitle: lang == 'en' ? 'English (Aktif)' : 'Bahasa Indonesia (Aktif)',
                    icon: Icons.language_rounded,
                    isDone: true,
                    instructions: [],
                    actionWidget: OutlinedButton.icon(
                      onPressed: () => _showLanguageDialog(context, appState),
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(isEn ? 'Change Language' : 'Ubah Bahasa'),
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
                    instructions: _getHomeInstructions(manufacturer, isEn),
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
                    instructions: _getAccessibilityInstructions(manufacturer, isEn),
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
                    instructions: _getAutostartInstructions(manufacturer, isEn),
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
                            onPressed: _openSupportDeveloperUrl,
                            icon: const Icon(Icons.coffee_rounded, size: 18),
                            label: Text(
                              isEn ? 'Support / Request Features via Ko-fi' : 'Dukung / Usulkan Fitur via Trakteer',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
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

  // ── Language Dialog ─────────────────────────────────────────────────────────

  void _showLanguageDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(Translations.get(appState.languageCode, 'language_selection')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
              title: const Text('Bahasa Indonesia'),
              trailing: appState.languageCode == 'id'
                  ? const Icon(Icons.check_circle, color: Color(0xFF0F5132))
                  : null,
              onTap: () {
                appState.setLanguage('id');
                Navigator.pop(ctx);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: appState.languageCode == 'en'
                  ? const Icon(Icons.check_circle, color: Color(0xFF0F5132))
                  : null,
              onTap: () {
                appState.setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
