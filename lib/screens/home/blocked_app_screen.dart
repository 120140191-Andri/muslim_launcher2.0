import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../hadith/hadith_list_screen.dart';
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
    final canUnlock = appState.points >= 50;

    return PopScope(
      canPop: false, // Prevent back button from bypassing block
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          appState.clearBlockedApp();
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: const Color(0xFF031E1B),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF063E36),
                  const Color(0xFF031E1B),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lock Icon Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade900.withValues(alpha: 0.25),
                          border: Border.all(
                            color: Colors.red.shade400.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Color(0xFFF87171),
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        Translations.get(lang, 'app_blocked'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      FutureBuilder<String>(
                        future: _appNameFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade900.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              snapshot.data!,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
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
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Points Balance Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "${appState.points} ${Translations.get(lang, 'points_available')}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 1. Unlock Button (Active if points >= 50)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: canUnlock
                            ? () async {
                                await appState.deductPoints(50);
                                await appState.allowAppTemporarily(widget.packageName);
                                await Future.delayed(const Duration(milliseconds: 800));
                                appState.openApp(widget.packageName);
                                appState.clearBlockedApp();
                              }
                            : null,
                          icon: Icon(
                            canUnlock ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade500,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                            disabledForegroundColor: Colors.white38,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          label: Text(
                            canUnlock
                              ? Translations.get(lang, 'unlock_60m')
                              : Translations.get(lang, 'need_50_points'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Divider / Header for Ways to Earn Points
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              lang == 'id'
                                  ? 'PILIHAN BACAAN (+POIN)'
                                  : Translations.get(lang, 'read_quran').toUpperCase(),
                              style: TextStyle(
                                color: Colors.teal.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Primary Option: Quran Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            appState.clearBlockedApp();
                            appState.navigatorKey.currentState?.push(
                              AppPageRoute(child: const SurahListScreen()),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded, size: 20, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.teal.shade300.withValues(alpha: 0.4)),
                            ),
                            elevation: 2,
                          ),
                          label: Text(
                            "${Translations.get(lang, 'read_quran')} (+10-25 Poin)",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),

                      // 3. Excused / Hadast Besar Option: Hadith Card Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF34D399).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              appState.clearBlockedApp();
                              appState.navigatorKey.currentState?.push(
                                AppPageRoute(child: const HadithListScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34D399).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.spa_rounded,
                                      color: Color(0xFF34D399),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lang == 'id'
                                                    ? 'Sedang Berhalangan / Haid?'
                                                    : Translations.get(lang, 'read_hadith_earn_points'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade400.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                '+3-8 Poin',
                                                style: TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang == 'id'
                                              ? 'Baca Kumpulan Hadits Shahih'
                                              : Translations.get(lang, 'read_hadith'),
                                          style: TextStyle(
                                            color: Colors.teal.shade200,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF34D399),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Gentle Hint Card for Hadast Besar / Excused Users
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Translations.get(lang, 'hadith_excused_hint'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
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
