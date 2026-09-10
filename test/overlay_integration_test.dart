import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/main.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Triggering all 3 overlays within MuslimLauncherApp renders with 0 errors', (tester) async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
    });
    final prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getApps') {
        return [
          {'packageName': 'com.opera.browser', 'appName': 'Opera', 'category': 7},
          {'packageName': 'com.instagram.android', 'appName': 'Instagram', 'category': 3},
          {'packageName': 'com.android.chrome', 'appName': 'Chrome', 'category': 7},
        ];
      }
      return true;
    });

    final appState = AppState(prefs);
    appState.setIgnorePermissionGuard(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
        child: const MuslimLauncherApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Prohibited overlay
    appState.setProhibitedPackage('com.opera.browser');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);

    // Tap Kembali on Prohibited overlay
    final prohibitedBack = find.byIcon(Icons.arrow_back_rounded).first;
    await tester.tap(prohibitedBack);
    await tester.pump(const Duration(milliseconds: 100));
    expect(appState.lastAttemptedProhibitedPackage, isNull);

    // 2. Blocked overlay
    appState.setBlockedPackage('com.instagram.android');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);

    // Tap Home on Blocked overlay
    final blockedHome = find.byIcon(Icons.home_rounded).first;
    await tester.tap(blockedHome);
    await tester.pump(const Duration(milliseconds: 100));
    expect(appState.lastAttemptedBlockedPackage, isNull);

    // 3. Ghadhul Bashar overlay
    appState.setGhadhulBasharPackage('com.android.chrome');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

    // Tap Kembali on Ghadhul Bashar overlay
    final ghadhulBack = find.byIcon(Icons.arrow_back_rounded).first;
    await tester.tap(ghadhulBack);
    await tester.pump(const Duration(milliseconds: 100));
    expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
  });

  testWidgets('Android system back navigation button (handlePopRoute) dismisses active overlay without leaving current screen', (tester) async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
    });
    final prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => true);

    final appState = AppState(prefs);
    appState.setIgnorePermissionGuard(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
        child: const MuslimLauncherApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Prohibited App: simulate system back
    appState.setProhibitedPackage('com.opera.browser');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);

    final handled1 = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(handled1, isTrue);
    expect(appState.lastAttemptedProhibitedPackage, isNull);
    expect(find.byIcon(Icons.gpp_bad_rounded), findsNothing);

    // 2. Blocked App: simulate system back
    appState.setBlockedPackage('com.instagram.android');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.lock_person_rounded), findsOneWidget);

    final handled2 = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(handled2, isTrue);
    expect(appState.lastAttemptedBlockedPackage, isNull);
    expect(find.byIcon(Icons.lock_person_rounded), findsNothing);

    // 3. Ghadhul Bashar: simulate system back
    appState.setGhadhulBasharPackage('com.android.chrome');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byIcon(Icons.visibility_off_rounded), findsOneWidget);

    final handled3 = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(handled3, isTrue);
    expect(appState.lastAttemptedGhadhulBasharPackage, isNull);
    expect(find.byIcon(Icons.visibility_off_rounded), findsNothing);
  });
}
