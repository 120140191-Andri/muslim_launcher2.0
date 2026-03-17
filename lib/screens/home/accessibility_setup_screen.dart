import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'home_screen.dart';
import '../../utils/page_transitions.dart';

class AccessibilitySetupScreen extends StatefulWidget {
  final bool isOnboarding;
  const AccessibilitySetupScreen({super.key, this.isOnboarding = false});

  @override
  State<AccessibilitySetupScreen> createState() =>
      _AccessibilitySetupScreenState();
}

class _AccessibilitySetupScreenState extends State<AccessibilitySetupScreen>
    with WidgetsBindingObserver {
  bool _isEnabled = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final enabled = await appState.appBlockService.isAccessibilityEnabled();
    if (mounted && enabled != _isEnabled) {
      setState(() => _isEnabled = enabled);
    }
  }

  List<String> _getBrandInstructions(String manufacturer, String lang) {
    bool isEn = lang == 'en';
    if (manufacturer.contains('xiaomi') ||
        manufacturer.contains('poco') ||
        manufacturer.contains('redmi')) {
      return [
        isEn
            ? 'Click "Open Settings" below.'
            : 'Klik "Buka Pengaturan" di bawah.',
        isEn
            ? 'Look for "Downloaded Apps" (Aplikasi Terunduh).'
            : 'Cari menu "Aplikasi Yang Didownload".',
        isEn ? 'Select "Muslim Launcher".' : 'Pilih "Muslim Launcher".',
        isEn
            ? 'Enable "Use Muslim Launcher".'
            : 'Aktifkan "Aktifkan Muslim Launcher".',
      ];
    } else if (manufacturer.contains('samsung')) {
      return [
        isEn
            ? 'Click "Open Settings" below.'
            : 'Klik "Buka Pengaturan" di bawah.',
        isEn
            ? 'Find "Installed Apps" (Layanan Terinstal).'
            : 'Cari menu "Layanan Terinstal".',
        isEn ? 'Select "Muslim Launcher".' : 'Pilih "Muslim Launcher".',
        isEn ? 'Turn the switch to ON.' : 'Geser tombol ke posisi AKTIF.',
      ];
    } else if (manufacturer.contains('oppo') ||
        manufacturer.contains('realme') ||
        manufacturer.contains('vivo')) {
      return [
        isEn
            ? 'Click "Open Settings" below.'
            : 'Klik "Buka Pengaturan" di bawah.',
        isEn
            ? 'Find "Muslim Launcher" in the list.'
            : 'Cari "Muslim Launcher" di daftar layanan.',
        isEn
            ? 'If not seen, check for "More" or "Installed Services".'
            : 'Jika tidak ditemukan, cek menu "Lainnya" atau "Layanan Terinstal".',
        isEn ? 'Enable the permission switch.' : 'Aktifkan izin atau tombolnya.',
      ];
    } else {
      return [
        isEn
            ? 'Click "Open Settings" below.'
            : 'Klik "Buka Pengaturan" di bawah.',
        isEn
            ? 'Find "Muslim Launcher" in the list.'
            : 'Cari "Muslim Launcher" di daftar.',
        isEn
            ? 'Select it and turn ON the toggle.'
            : 'Pilih aplikasinya dan aktifkan tombolnya.',
        isEn
            ? 'Confirm any system warnings.'
            : 'Klik "OK" atau "Izinkan" jika ada peringatan.',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final manufacturer = appState.manufacturer;
    final isEn = lang == 'en';

    final instructions = _getBrandInstructions(manufacturer, lang);
    final brandDisplay = manufacturer.isNotEmpty
        ? manufacturer[0].toUpperCase() + manufacturer.substring(1)
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(isEn ? 'App Blocker Setup' : 'Keamanan Fokus'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B4332),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _isEnabled
                          ? const Color(0xFFD8F3DC)
                          : const Color(0xFFE9F5F2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isEnabled ? Colors.green : Colors.teal)
                              .withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isEnabled
                          ? Icons.verified_user_rounded
                          : Icons.app_blocking_rounded,
                      color: _isEnabled
                          ? const Color(0xFF2D6A4F)
                          : const Color(0xFF0891B2),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isEnabled
                        ? (isEn ? 'Ready to Focus!' : 'Siap Beribadah!')
                        : (isEn ? 'Enable App Blocker' : 'Aktifkan Fokus'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isEnabled
                        ? (isEn
                              ? 'Muslim Launcher will help you stay away from distractions.'
                              : 'Aplikasi akan otomatis membatasi gangguan saat Anda sedang belajar Al-Quran.')
                        : (isEn
                              ? 'To block disruptive apps, we need your permission in Accessibility settings.'
                              : 'Agar fitur pembatas gangguan bekerja, kami perlu izin di menu Aksesibilitas HP Anda.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.blueGrey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEnabled) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF0891B2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEn
                              ? "FOR YOUR $brandDisplay DEVICE:"
                              : "PETUNJUK HP $brandDisplay:",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            fontSize: 12,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(instructions.length, (index) {
                          return _buildFancyStep(
                            index + 1,
                            instructions[index],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade900,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEn
                                  ? "Tip: Look for the 'Downloaded' or 'Services' section first."
                                  : "Tips: Biasanya ada di bagian 'Aplikasi Yang Didownload' atau 'Layanan'.",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () =>
                          appState.appBlockService.openAccessibilitySettings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEnabled
                            ? Colors.white
                            : const Color(0xFF1B4332),
                        foregroundColor: _isEnabled
                            ? const Color(0xFF1B4332)
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: _isEnabled
                                ? Colors.grey.shade300
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Text(
                        _isEnabled
                            ? (isEn
                                  ? 'Adjust Settings'
                                  : 'Buka Pengaturan Lagi')
                            : (isEn
                                  ? 'Open Settings Now'
                                  : 'Buka Pengaturan Sekarang'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (_isEnabled) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.isOnboarding) {
                            appState.completeOnboarding();
                            Navigator.pushAndRemoveUntil(
                              context,
                              AppPageRoute(child: const HomeScreen()),
                              (route) => false,
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4332),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF1B4332).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          widget.isOnboarding
                              ? (isEn ? 'START EXPLORING' : 'MULAI SEKARANG')
                              : (isEn ? 'Done' : 'Selesai'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFancyStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD8F3DC),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$num",
              style: const TextStyle(
                color: Color(0xFF1B4332),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2D3142),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
