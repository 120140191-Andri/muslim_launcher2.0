import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_state.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/setup_launcher_screen.dart';
import 'screens/home/blocked_app_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Increase image cache limits for smoother launcher experience
  // 100MB maximum size and 500 images count to keep all app icons in memory
  PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 500;

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState(prefs))],
      child: const MuslimLauncherApp(),
    ),
  );
}

class MuslimLauncherApp extends StatelessWidget {
  const MuslimLauncherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          navigatorKey: appState.navigatorKey,
          title: 'Muslim Launcher 2',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: _determineHome(appState),
          builder: (context, child) {
            return Stack(
              children: [
                ?child,
                if (appState.lastAttemptedBlockedPackage != null &&
                    appState.lastAttemptedBlockedPackage!.isNotEmpty)
                  BlockedAppScreen(
                    packageName: appState.lastAttemptedBlockedPackage!,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _determineHome(AppState appState) {
    if (appState.hasCompletedOnboarding) return const HomeScreen();
    if (appState.hasSelectedLanguage) return const SetupLauncherScreen();
    return const LanguageScreen();
  }
}
