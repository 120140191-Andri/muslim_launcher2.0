import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../hadith/hadith_list_screen.dart';
import '../dzikir/dzikir_screen.dart';
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
                        padding: const EdgeInsets.all(18),
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
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. App Name (ABOVE the blocked label)
                      FutureBuilder<String>(
                        future: _appNameFuture,
                        builder: (context, snapshot) {
                          final name = (snapshot.hasData && snapshot.data!.isNotEmpty)
                              ? snapshot.data!
                              : widget.packageName;
                          return Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 6),

                      // 2. Status Label (BELOW app name)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          Translations.get(lang, 'app_blocked'),
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        Translations.get(lang, 'app_blocked_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      
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
                      
                      const SizedBox(height: 22),
                      
                      // 1. Unlock Button (Active if points >= 50)
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          label: Text(
                            canUnlock
                              ? Translations.get(lang, 'unlock_60m')
                              : Translations.get(lang, 'need_50_points'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 18),
                      
                      // Header for Ways to Earn Points
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              lang == 'id'
                                  ? 'PILIHAN BACAAN & IBADAH (+POIN)'
                                  : Translations.get(lang, 'earn_points').toUpperCase(),
                              style: TextStyle(
                                color: Colors.teal.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Primary Option: Baca Al-Quran (Di atas sendiri)
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.teal.shade300.withValues(alpha: 0.4)),
                            ),
                            elevation: 1,
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  Translations.get(lang, 'read_quran'),
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '+10-25 Poin',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // 3. Keterangan Sedang Berhalangan / Haid / Rukhsah (Di bawah Quran)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade900.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade400.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                Translations.get(lang, 'hadith_excused_hint'),
                                style: TextStyle(
                                  color: Colors.teal.shade100,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4. Pilihan Berhalangan A: Dzikir Khusyu' (33x Tasbih)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF04433A).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2DD4BF).withValues(alpha: 0.5),
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
                                AppPageRoute(child: const DzikirScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.grain_rounded,
                                      color: Color(0xFF2DD4BF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                Translations.get(lang, 'dzikir'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
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
                                                '+10 Poin',
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
                                              ? 'Tasbih 33x & Deteksi Wajah (Boleh Meram)'
                                              : Translations.get(lang, 'dzikir_mode_title'),
                                          style: TextStyle(
                                            color: Colors.teal.shade200,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF2DD4BF),
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 5. Pilihan Berhalangan B: Hadith Card Button
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                Translations.get(lang, 'read_hadith'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
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
                                              ? '50 Kumpulan Hadits Shahih Harian'
                                              : Translations.get(lang, 'read_hadith'),
                                          style: TextStyle(
                                            color: Colors.teal.shade200,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF34D399),
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ),
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
