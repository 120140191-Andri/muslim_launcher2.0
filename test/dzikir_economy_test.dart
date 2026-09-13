import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/dzikir/dzikir_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => true);
  });

  group('Dzikir Per-Preset Points Economy Tests', () {
    test('Each of the 8 presets gives full 5 base points on first daily completion', () async {
      final appState = AppState(prefs);

      expect(appState.dailyDzikirRounds, 0);
      expect(appState.dailyDzikirPoints, 0);
      expect(appState.points, 0);

      int totalExpectedPoints = 0;
      for (int i = 0; i < kDzikirPresets.length; i++) {
        final preset = kDzikirPresets[i];
        expect(appState.isDzikirPresetReadToday(preset.title), false);
        expect(appState.getDzikirPresetRounds(preset.title), 0);

        final result = await appState.saveDzikirProgress(preset.title, 33, 10);
        expect(result['round'], i + 1);
        expect(result['presetRound'], 1);
        expect(result['isFirstPresetRound'], true);
        expect(result['pointsEarned'], 5); // 5 base points for first round today

        totalExpectedPoints += 5;
        expect(appState.dailyDzikirPoints, totalExpectedPoints);
        expect(appState.points, totalExpectedPoints);
        expect(appState.isDzikirPresetReadToday(preset.title), true);
        expect(appState.getDzikirPresetRounds(preset.title), 1);
      }

      // User earns points from all 8 presets: 8 * 5 = 40 points
      expect(totalExpectedPoints, 40);
      expect(appState.dailyDzikirPoints, 40);
      expect(appState.dailyDzikirRounds, 8);
    });

    test('Repeat rounds on the same preset reduce points to 2 base points and do not yield 0', () async {
      final appState = AppState(prefs);

      // 1st round of Subhanallah -> 5 points
      final r1 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r1['presetRound'], 1);
      expect(r1['isFirstPresetRound'], true);
      expect(r1['pointsEarned'], 5);
      expect(appState.points, 5);

      // 2nd round of Subhanallah (repeat) -> 2 points (reduced, higher than hadith)
      final r2 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r2['presetRound'], 2);
      expect(r2['isFirstPresetRound'], false);
      expect(r2['pointsEarned'], 2); // reduced to 2, not 0!
      expect(appState.points, 7);

      // 3rd round of Subhanallah (repeat) -> 2 points (reduced)
      final r3 = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(r3['presetRound'], 3);
      expect(r3['isFirstPresetRound'], false);
      expect(r3['pointsEarned'], 2);
      expect(appState.points, 9);

      // Switch to a fresh preset (Alhamdulillah) -> still gets full 5 points!
      final rFresh = await appState.saveDzikirProgress('Alhamdulillah', 33, 10);
      expect(rFresh['presetRound'], 1);
      expect(rFresh['isFirstPresetRound'], true);
      expect(rFresh['pointsEarned'], 5);
      expect(appState.points, 14);
    });

    test('Maqam boost multiplier correctly scales fresh (5 pts) and repeat (2 pts) rounds', () async {
      // Level 2 (1.25x multiplier)
      await prefs.setInt('khatmCount', 1);
      final appStateL2 = AppState(prefs);

      final l2Fresh = await appStateL2.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l2Fresh['pointsEarned'], (5 * 1.25).round()); // 6 points

      final l2Repeat = await appStateL2.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l2Repeat['pointsEarned'], (2 * 1.25).round()); // 3 points

      // Level 5 (2.0x multiplier)
      final prefsL5 = await SharedPreferences.getInstance();
      await prefsL5.clear();
      await prefsL5.setInt('khatmCount', 5);
      final appStateL5 = AppState(prefsL5);

      final l5Fresh = await appStateL5.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l5Fresh['pointsEarned'], (5 * 2.0).round()); // 10 points

      final l5Repeat = await appStateL5.saveDzikirProgress('Subhanallah', 33, 10);
      expect(l5Repeat['pointsEarned'], (2 * 2.0).round()); // 4 points
    });

    test('Preset tracking resets on date change', () async {
      final appState = AppState(prefs);
      await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(appState.getDzikirPresetRounds('Subhanallah'), 1);

      // Simulate next day
      await appState.setDzikirStreakForTesting(1, lastDate: '2026-09-01');
      expect(appState.getDzikirPresetRounds('Subhanallah'), 0);
      expect(appState.isDzikirPresetReadToday('Subhanallah'), false);

      // Now Subhanallah is fresh again!
      final rNextDay = await appState.saveDzikirProgress('Subhanallah', 33, 10);
      expect(rNextDay['presetRound'], 1);
      expect(rNextDay['isFirstPresetRound'], true);
      expect(rNextDay['pointsEarned'], 5);
    });

    testWidgets('DzikirScreen selector shows +5 Poin badge for fresh and checkmark for read presets', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState(prefs);
      // Mark Subhanallah as read once
      await appState.saveDzikirProgress('Subhanallah', 33, 10);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: DzikirScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Dzikir Selector modal
      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
      await tester.pumpAndSettle();

      // Subhanallah was read once today -> shows checkmark and repeat points (+2)
      expect(find.text('✓ 1x (+2)'), findsOneWidget);

      // Other unread presets show +5 Poin badge
      expect(find.text('+5 Poin'), findsWidgets);
    });
  });
}
