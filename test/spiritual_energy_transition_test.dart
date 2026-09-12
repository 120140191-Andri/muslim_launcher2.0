import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => []);
  });

  group('Spiritual Energy Transition & Session Tests', () {
    test('triggerSpiritualEnergy sets pending session and consumePendingEnergySession retrieves it', () async {
      final appState = AppState(prefs);

      expect(appState.pendingEnergySession, isNull);

      // Trigger spiritual energy for 3 Quran ayahs read
      appState.triggerSpiritualEnergy(
        previousProgress: 0.05,
        targetProgress: 0.06,
        source: 'quran',
        itemsCount: 3,
      );

      final session = appState.pendingEnergySession;
      expect(session, isNotNull);
      expect(session!.source, 'quran');
      expect(session.itemsCount, 3);
      expect(session.previousProgress, 0.05);
      expect(session.targetProgress, 0.06);
      // Extra seconds: 3 * 4 = 12 -> 15 + 12 = 27 seconds
      expect(session.durationSeconds, 27);

      // Consuming session clears pendingEnergySession
      final consumed = appState.consumePendingEnergySession();
      expect(consumed, isNotNull);
      expect(consumed!.itemsCount, 3);
      expect(appState.pendingEnergySession, isNull);
    });

    test('triggerSpiritualEnergy for Dzikir scales properly', () async {
      final appState = AppState(prefs);

      // Trigger spiritual energy for 33 Dzikir taps
      appState.triggerSpiritualEnergy(
        previousProgress: 0.10,
        targetProgress: 0.12,
        source: 'dzikir',
        itemsCount: 33,
      );

      final session = appState.pendingEnergySession;
      expect(session, isNotNull);
      expect(session!.source, 'dzikir');
      expect(session.itemsCount, 33);
      // Extra seconds: 33 ~/ 3 = 11 -> 15 + 11 = 26 seconds
      expect(session.durationSeconds, 26);
    });

    test('triggerSpiritualEnergy ignores empty item counts', () async {
      final appState = AppState(prefs);

      appState.triggerSpiritualEnergy(
        previousProgress: 0.10,
        targetProgress: 0.10,
        source: 'quran',
        itemsCount: 0,
      );

      expect(appState.pendingEnergySession, isNull);
    });
  });
}
