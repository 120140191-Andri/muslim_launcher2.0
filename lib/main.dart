import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_state.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/setup_hub_screen.dart';
import 'screens/home/blocked_app_screen.dart';
import 'screens/home/permission_blocked_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Boundary - Move to main for production safety
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint("Flutter Error: ${details.exception}");
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFF004D40), // Teal 900
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 64),
                const SizedBox(height: 24),
                const Text(
                  "Oops! Something went wrong",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "A minor error occurred. Please try again or restart the app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Increase image cache limits
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
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
      builder: (context, state, child) {
        final homeWidget = _determineHome(state);
        
        return MaterialApp(
          navigatorKey: state.navigatorKey,
          title: 'Muslim Launcher 2',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: homeWidget,
          builder: (context, child) {
            // CRITICAL: Ensure we always have a child to render.
            // If child is null, something in MaterialApp initialization failed.
            final rootWidget = child ?? homeWidget;

            // Clamp text scale factor to prevent layout overflows on extreme accessibility font settings
            final mediaQuery = MediaQuery.of(context);
            final clampedMediaQuery = mediaQuery.copyWith(
              textScaler: mediaQuery.textScaler.clamp(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.15,
              ),
            );

            return MediaQuery(
              data: clampedMediaQuery,
              child: PermissionBlockedOverlay(
                appState: state,
                child: Stack(
                  children: [
                    rootWidget,
                    if (state.lastAttemptedBlockedPackage?.isNotEmpty ?? false)
                      BlockedAppScreen(
                        packageName: state.lastAttemptedBlockedPackage!,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _determineHome(AppState appState) {
    if (!appState.isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF052C28),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mosque_rounded, size: 72, color: Color(0xFF34D399)),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFF34D399)),
            ],
          ),
        ),
      );
    }
    if (appState.hasCompletedOnboarding) return const HomeScreen();
    if (appState.hasSelectedLanguage) return const SetupHubScreen();
    return const LanguageScreen();
  }
}
