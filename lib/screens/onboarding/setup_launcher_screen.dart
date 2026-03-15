import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:android_intent_plus/android_intent.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';
import '../home/home_screen.dart';

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
      if (isDefault) {
        _finishOnboarding();
      }
    } catch (_) {}
  }

  void _openSettings() {
    const intent = AndroidIntent(action: 'android.settings.HOME_SETTINGS');
    intent.launch();
  }

  void _finishOnboarding() {
    Provider.of<AppState>(context, listen: false).completeOnboarding();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<AppState>(context).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  _isDefaultLauncher ? Icons.check_circle_rounded : Icons.home_rounded,
                  size: 80,
                  color: _isDefaultLauncher ? Colors.green.shade600 : Colors.teal.shade800,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _isDefaultLauncher
                    ? (lang == 'en' ? 'You\'re All Set!' : 'Semua Sudah Siap!')
                    : (lang == 'en' ? 'Set as Default' : 'Jadikan Default'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _isDefaultLauncher
                      ? (lang == 'en'
                          ? 'Muslim Launcher 2 is now your main home application. Enjoy your productive journey!'
                          : 'Muslim Launcher 2 telah menjadi aplikasi utama Anda. Selamat berproses!')
                      : (lang == 'en'
                          ? 'To make the points and blocking system work, please set Muslim Launcher 2 as your default Home App.'
                          : 'Agar sistem poin dan pemblokiran berjalan, silakan jadikan Muslim Launcher 2 sebagai Beranda Utama.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
                ),
              ),
              const SizedBox(height: 60),
              if (!_isDefaultLauncher)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_suggest_rounded),
                    label: Text(
                      Translations.get(lang, 'open_settings').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => _finishOnboarding(),
                child: Text(
                  Translations.get(lang, 'done').toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
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
