import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';

class BlockedAppScreen extends StatefulWidget {
  final String packageName;

  const BlockedAppScreen({super.key, required this.packageName});

  @override
  State<BlockedAppScreen> createState() => _BlockedAppScreenState();
}

class _BlockedAppScreenState extends State<BlockedAppScreen> {
  late final Future<String> _appNameFuture;

  @override
  void initState() {
    super.initState();
    _appNameFuture = _getAppName(widget.packageName);
  }

  Future<String> _getAppName(String pkg) async {
    const channel = MethodChannel('com.muslimlauncher/apps');
    try {
      final List<dynamic> apps = await channel.invokeMethod('getApps');
      for (var app in apps) {
        if (app != null && app['packageName'] == pkg) {
          return app['appName'] as String;
        }
      }
    } catch (_) {}
    return pkg;
  }

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
                        Translations.get(lang, 'app_blocked'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      FutureBuilder<String>(
                        future: _appNameFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              snapshot.data!,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Translations.get(lang, 'app_blocked_desc'),
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
                              "${appState.points} ${Translations.get(lang, 'points_available')}",
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
                                await appState.allowAppTemporarily(widget.packageName);
                                await Future.delayed(const Duration(milliseconds: 1000));
                                appState.openApp(widget.packageName);
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
                              ? Translations.get(lang, 'unlock_60m')
                              : Translations.get(lang, 'need_50_points'),
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
                            Translations.get(lang, 'read_quran_earn_points'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => appState.clearBlockedApp(),
                        child: Text(
                          Translations.get(lang, 'go_back'),
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

