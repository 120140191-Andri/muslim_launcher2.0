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
  State<AccessibilitySetupScreen> createState() => _AccessibilitySetupScreenState();
}

class _AccessibilitySetupScreenState extends State<AccessibilitySetupScreen> with WidgetsBindingObserver {
  bool _isEnabled = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
    // Periodically check if user enabled it in settings
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(lang == 'en' ? 'App Blocker Setup' : 'Setup Blokir Aplikasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade900,
        elevation: 0,
        automaticallyImplyLeading: !widget.isOnboarding, // Hide back button during onboarding
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isEnabled ? Colors.green.shade50 : Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEnabled ? Icons.check_circle_rounded : Icons.security_rounded,
                  color: _isEnabled ? Colors.green : Colors.teal,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isEnabled 
                ? (lang == 'en' ? 'Service is Active!' : 'Layanan Sudah Aktif!')
                : (lang == 'en' ? 'Action Required' : 'Butuh Perizinan'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isEnabled ? Colors.green.shade800 : Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEnabled 
                ? (lang == 'en' 
                    ? 'The app blocker is now monitoring your device to help you stay focused.' 
                    : 'Aplikasi sekarang dapat memonitor HP Anda agar tetap fokus baca Al-Quran.')
                : (lang == 'en' 
                    ? 'To block apps system-wide, you need to enable the Accessibility Service for Muslim Launcher.' 
                    : 'Agar fitur blokir aplikasi di luar Launcher bekerja, Anda perlu mengaktifkan izin Aksesibilitas.'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
            
            const SizedBox(height: 40),
            
            if (!_isEnabled) ...[
              Text(
                lang == 'en' ? 'STEPS TO ENABLE:' : 'LANGKAH-LANGKAH:',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
              const SizedBox(height: 16),
              _buildStep(1, lang == 'en' ? 'Click "Open Settings" button below.' : 'Klik tombol "Buka Pengaturan" di bawah.'),
              _buildStep(2, lang == 'en' ? 'Find "Muslim Launcher" in the list.' : 'Cari "Muslim Launcher" di daftar layanan.'),
              _buildStep(3, lang == 'en' ? 'Turn ON the switch/permission.' : 'Aktifkan (ON) tombol izinnya.'),
              _buildStep(4, lang == 'en' ? 'Return here to confirm.' : 'Kembali ke sini untuk memastikan.'),
            ],
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => appState.appBlockService.openAccessibilitySettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEnabled ? Colors.grey.shade200 : Colors.teal.shade700,
                  foregroundColor: _isEnabled ? Colors.grey.shade700 : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _isEnabled 
                    ? (lang == 'en' ? 'Open Settings Again' : 'Buka Pengaturan Lagi')
                    : (lang == 'en' ? 'Open Settings Now' : 'Buka Pengaturan Sekarang'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            if (_isEnabled) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
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
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.isOnboarding 
                      ? (lang == 'en' ? 'START APP' : 'MULAI APLIKASI')
                      : (lang == 'en' ? 'Done' : 'Selesai'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.teal.shade100, shape: BoxShape.circle),
            child: Text("$num", style: TextStyle(color: Colors.teal.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
