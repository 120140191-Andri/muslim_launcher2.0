import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'points': 500,
      'isPassiveMode': true,
    });
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getApps') {
        return [];
      }
      return true;
    });

    appState = AppState(prefs);
  });

  tearDown(() {
    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, null);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, null);
  });

  group('Ad Friction & Grace Period Tests (Aturan Iklan Pembatas)', () {
    test('1. Buka non-produktif < 3x tidak mewajibkan iklan', () {
      appState.setDailyUnlocksForTesting(0);
      expect(appState.dailyUnlocksCount, 0);
      expect(appState.shouldShowAdBeforeUnlock, false);

      appState.setDailyUnlocksForTesting(1);
      expect(appState.dailyUnlocksCount, 1);
      expect(appState.shouldShowAdBeforeUnlock, false);

      appState.setDailyUnlocksForTesting(2);
      expect(appState.dailyUnlocksCount, 2);
      expect(appState.shouldShowAdBeforeUnlock, false);
    });

    test('2. Buka non-produktif >= 3x mewajibkan iklan jika belum ada tiket santai aktif', () {
      appState.setDailyUnlocksForTesting(3);
      expect(appState.dailyUnlocksCount, 3);
      expect(appState.isAdGracePeriodActive, false);
      expect(appState.shouldShowAdBeforeUnlock, true);

      appState.setDailyUnlocksForTesting(5);
      expect(appState.shouldShowAdBeforeUnlock, true);
    });

    test('3. Menonton iklan mengaktifkan tiket bebas iklan 10 menit (Global Pass)', () async {
      appState.setDailyUnlocksForTesting(3);
      expect(appState.shouldShowAdBeforeUnlock, true);

      // Simulasi user menonton video dan mengaktifkan tiket 10 menit
      await appState.activateAdGracePeriod(durationMinutes: 10);

      expect(appState.isAdGracePeriodActive, true);
      expect(appState.remainingAdGracePeriodSeconds, greaterThan(500));
      expect(appState.remainingAdGracePeriodMinutes, 10);

      // Selama tiket aktif, tidak perlu nonton iklan lagi walaupun count >= 3
      expect(appState.shouldShowAdBeforeUnlock, false);
    });

    test('4. Ketika tiket 10 menit kadaluarsa, wajib nonton iklan lagi', () {
      appState.setDailyUnlocksForTesting(4);

      // Set masa aktif yang sudah lewat 1 detik lalu
      final pastTime = DateTime.now().subtract(const Duration(seconds: 1));
      appState.setAdGracePeriodForTesting(pastTime);

      expect(appState.isAdGracePeriodActive, false);
      expect(appState.remainingAdGracePeriodSeconds, 0);
      expect(appState.shouldShowAdBeforeUnlock, true);
    });

    test('5. Reset harian (00:00) mengembalikan hitungan ke 0 dan membebaskan iklan', () {
      appState.setDailyUnlocksForTesting(4, date: '2026-10-30'); // Kemarin sudah 4x

      // Tanggal hari ini berbeda, maka count reset ke 0
      expect(appState.dailyUnlocksCount, 0);
      expect(appState.shouldShowAdBeforeUnlock, false);
    });
  });
}
