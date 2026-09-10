import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/app_state.dart';
import 'services/analytics_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/setup_hub_screen.dart';
import 'screens/home/blocked_app_screen.dart';
import 'screens/home/ghadhul_bashar_overlay.dart';
import 'screens/home/prohibited_app_overlay.dart';
import 'screens/home/permission_blocked_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.initialize();

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

  // Optimized image cache limits for low-spec and standard Android devices
  PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 200;

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState(prefs))],
      child: const MuslimLauncherApp(),
    ),
  );
}

class MuslimLauncherApp extends StatefulWidget {
  const MuslimLauncherApp({super.key});

  @override
  State<MuslimLauncherApp> createState() => _MuslimLauncherAppState();
}

class _MuslimLauncherAppState extends State<MuslimLauncherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.hasActiveOverlay) {
      state.clearAllOverlays();
      return true; // Handled: dismiss overlay without popping underlying screen
    }
    return false; // Let normal route popping occur
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);

    return MaterialApp(
      navigatorKey: state.navigatorKey,
      title: 'Muslim Launcher 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      navigatorObservers: [AnalyticsService.observer],
      home: const _HomeScreenSwitcher(),
      builder: (context, child) {
        final rootWidget = child ?? const _HomeScreenSwitcher();

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
          child: Consumer<AppState>(
            builder: (context, appState, _) {
              return PermissionBlockedOverlay(
                appState: appState,
                child: Stack(
                  children: [
                    rootWidget,
                    if (appState.lastAttemptedProhibitedPackage?.isNotEmpty ?? false)
                      ProhibitedAppOverlay(
                        packageName: appState.lastAttemptedProhibitedPackage!,
                      )
                    else if (appState.lastAttemptedBlockedPackage?.isNotEmpty ?? false)
                      BlockedAppScreen(
                        packageName: appState.lastAttemptedBlockedPackage!,
                      )
                    else if (appState.lastAttemptedGhadhulBasharPackage?.isNotEmpty ?? false)
                      GhadhulBasharOverlay(
                        packageName: appState.lastAttemptedGhadhulBasharPackage!,
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeScreenSwitcher extends StatelessWidget {
  const _HomeScreenSwitcher();

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, ({bool isReady, bool hasCompletedOnboarding, bool hasSelectedLanguage})>(
      selector: (context, state) => (
        isReady: state.isReady,
        hasCompletedOnboarding: state.hasCompletedOnboarding,
        hasSelectedLanguage: state.hasSelectedLanguage,
      ),
      builder: (context, status, _) {
        if (!status.isReady) {
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
        if (status.hasCompletedOnboarding) return const HomeScreen();
        if (status.hasSelectedLanguage) return const SetupHubScreen();
        return const LanguageScreen();
      },
    );
  }
}
