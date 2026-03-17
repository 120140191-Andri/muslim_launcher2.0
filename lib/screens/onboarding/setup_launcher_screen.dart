import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/app_state.dart';
import '../home/accessibility_setup_screen.dart';
import '../../utils/page_transitions.dart';

class SetupLauncherScreen extends StatefulWidget {
  const SetupLauncherScreen({super.key});

  @override
  State<SetupLauncherScreen> createState() => _SetupLauncherScreenState();
}

class _SetupLauncherScreenState extends State<SetupLauncherScreen> with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.muslimlauncher/apps');
  bool _isDefaultLauncher = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDefaultLauncher();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDefaultLauncher();
    }
  }

  Future<void> _checkDefaultLauncher() async {
    try {
      final bool isDefault = await _platform.invokeMethod('isDefaultLauncher');
      if (mounted) setState(() => _isDefaultLauncher = isDefault);
    } catch (_) {}
  }

  void _openSettings() {
    const intent = AndroidIntent(action: 'android.settings.HOME_SETTINGS');
    intent.launch();
  }

  void _goToNextStep() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.navigatorKey.currentState?.push(
      AppPageRoute(child: const AccessibilitySetupScreen(isOnboarding: true)),
    );
  }

  List<String> _getHomeBrandInstructions(String manufacturer, String lang) {
    bool isEn = lang == 'en';
    if (manufacturer.contains('xiaomi') ||
        manufacturer.contains('poco') ||
        manufacturer.contains('redmi')) {
      return [
        isEn ? 'Click "Open Settings" below.' : 'Klik "Buka Pengaturan" di bawah.',
        isEn ? 'Select "Muslim Launcher" (ML2).' : 'Pilih "Muslim Launcher" (ML2).',
        isEn ? 'Confirm if the system asks.' : 'Konfirmasi jika sistem meminta.',
      ];
    } else {
      return [
        isEn ? 'Click "Open Settings" below.' : 'Klik "Buka Pengaturan" di bawah.',
        isEn ? 'Select "Muslim Launcher 2" from the list.' : 'Pilih "Muslim Launcher 2" dari daftar.',
        isEn ? 'Choose "Always" if prompted.' : 'Pilih "Selalu" atau "Default" jika ditanya.',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final isEn = lang == 'en';
    final manufacturer = appState.manufacturer;
    
    final instructions = _getHomeBrandInstructions(manufacturer, lang);
    final brandDisplay = manufacturer.isNotEmpty 
        ? manufacturer[0].toUpperCase() + manufacturer.substring(1) 
        : "Android";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _isDefaultLauncher ? const Color(0xFFD8F3DC) : const Color(0xFFE9F5F2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isDefaultLauncher ? Colors.green : Colors.teal).withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isDefaultLauncher ? Icons.home_work_rounded : Icons.home_rounded,
                        color: _isDefaultLauncher ? const Color(0xFF2D6A4F) : const Color(0xFF0891B2),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isDefaultLauncher
                          ? (isEn ? 'Home App Ready!' : 'Beranda Aktif!')
                          : (isEn ? 'Set Default Home' : 'Jadikan Beranda Utama'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _isDefaultLauncher
                            ? (isEn
                                ? 'Muslim Launcher is now your main home app. You can now use all focus features.'
                                : 'Muslim Launcher sudah menjadi beranda utama HP Anda. Fitur fokus kini siap digunakan.')
                            : (isEn
                                ? 'To block distractions effectively, Muslim Launcher must be your default Home App.'
                                : 'Agar pembatasan gangguan bekerja maksimal, jadikan aplikasi ini sebagai Beranda Utama Anda.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade600, height: 1.5),
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
                    if (!_isDefaultLauncher) ...[
                      Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFF0891B2)),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? "STEPS FOR $brandDisplay:" : "LANGKAH UNTUK $brandDisplay:",
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
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(instructions.length, (index) {
                            return _buildFancyStep(index + 1, instructions[index]);
                          }),
                        ),
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              isEn ? "Excellent choice!" : "Pilihan yang tepat!",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isDefaultLauncher ? null : _openSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isDefaultLauncher ? Colors.white : const Color(0xFF1B4332),
                          foregroundColor: _isDefaultLauncher ? Colors.grey.shade400 : Colors.white,
                          elevation: _isDefaultLauncher ? 0 : 4,
                          shadowColor: const Color(0xFF1B4332).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: _isDefaultLauncher ? Colors.grey.shade200 : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          _isDefaultLauncher 
                            ? (isEn ? 'Already Default' : 'Sudah Menjadi Default')
                            : (isEn ? 'OPEN SETTINGS' : 'BUKA PENGATURAN'),
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: TextButton(
                        onPressed: _isDefaultLauncher ? _goToNextStep : null,
                        style: TextButton.styleFrom(
                          foregroundColor: _isDefaultLauncher ? const Color(0xFF1B4332) : Colors.grey.shade400,
                          backgroundColor: _isDefaultLauncher ? const Color(0xFFD8F3DC) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (isEn ? 'NEXT STEP' : 'LANGKAH BERIKUTNYA').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFancyStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE9F5F2),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$num", 
              style: const TextStyle(
                color: Color(0xFF0891B2), 
                fontSize: 12, 
                fontWeight: FontWeight.w900,
              )
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(
                fontSize: 14, 
                color: Color(0xFF4B5563),
                height: 1.4,
              )
            ),
          ),
        ],
      ),
    );
  }
}
