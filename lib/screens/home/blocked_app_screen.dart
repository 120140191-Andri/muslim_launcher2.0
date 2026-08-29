import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../../utils/page_transitions.dart';

class BlockedAppScreen extends StatelessWidget {
  final String packageName;

  const BlockedAppScreen({super.key, required this.packageName});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

    return PopScope(
      canPop: false, // Prevent back button from passing through
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          appState.clearBlockedApp();
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: const Color(0xFF052C28),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.teal.shade900,
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_person_rounded,
                        color: Colors.white,
                        size: 80,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        lang == 'en' ? 'APP BLOCKED' : 'APLIKASI DIBLOKIR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang == 'en'
                            ? 'To open this app, read the Quran or spend 50 Points to unlock for 60 minutes.'
                            : 'Untuk membuka aplikasi ini, silakan baca Al-Quran atau gunakan 50 Poin untuk membuka selama 60 menit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 36),
                      
                      // Points available
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              lang == 'en' ? "${appState.points} Points Available" : "${appState.points} Poin Tersedia",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Unlock Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: appState.points >= 50 
                            ? () async {
                                await appState.deductPoints(50);
                                await appState.allowAppTemporarily(packageName);
                                await Future.delayed(const Duration(milliseconds: 1000));
                                appState.openApp(packageName);
                                appState.clearBlockedApp();
                              }
                            : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade500,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            appState.points >= 50
                              ? (lang == 'en' ? 'Unlock 60 Min (50 Points)' : 'Buka Blokir 60 Menit (50 Poin)')
                              : (lang == 'en' ? 'Need 50 Points' : 'Butuh 50 Poin'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 14),
                      
                      // Go to Quran Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            appState.clearBlockedApp();
                            appState.navigatorKey.currentState?.push(
                              AppPageRoute(child: const SurahListScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            lang == 'en' ? 'Read Quran to Earn Points' : 'Baca Al-Quran Cari Poin',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => appState.clearBlockedApp(),
                        child: Text(
                          lang == 'en' ? 'Go Back' : 'Kembali',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

