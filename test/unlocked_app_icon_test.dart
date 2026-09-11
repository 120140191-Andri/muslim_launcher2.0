import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => true);

    SharedPreferences.setMockInitialValues({
      'blockedApps': ['com.instagram.android', 'com.tiktok.android'],
      'unlockedExpirations': json.encode({
        'com.instagram.android': DateTime.now().millisecondsSinceEpoch + 3600000, // 60 mins
      }),
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('Unlocked App Status & Expiration', () {
    test('isAppUnlocked returns true for active unlock and false otherwise', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      expect(appState.isAppUnlocked('com.instagram.android'), isTrue);
      expect(appState.isAppUnlocked('com.tiktok.android'), isFalse);
      expect(appState.isAppUnlocked('com.whatsapp'), isFalse);
    });

    test('isAppBlocked returns false for temporarily unlocked app and true for locked app', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      expect(appState.isAppBlocked('com.instagram.android'), isFalse);
      expect(appState.isAppBlocked('com.tiktok.android'), isTrue);
    });

    test('getUnlockRemainingMinutes returns correct minutes', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      expect(appState.getUnlockRemainingMinutes('com.instagram.android'), greaterThan(0));
      expect(appState.getUnlockRemainingMinutes('com.tiktok.android'), equals(0));
    });

    test('isStrictlyNonProductive correctly classifies pure non-productive vs community apps', () {
      // Pure non-productive apps: MUST BE TRUE
      expect(AppState.isStrictlyNonProductive('com.zhiliaoapp.musically', 'TikTok'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.instagram.android', 'Instagram'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.facebook.katana', 'Facebook'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.twitter.android', 'X'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.tafusoft.pepelo', 'Pepelo', 0), isTrue);
      expect(AppState.isStrictlyNonProductive('com.tinder', 'Tinder'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.google.android.youtube', 'YouTube'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.litatom.litmatch', 'Litmatch'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.bd.nproject', 'Lemon8'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.haoda.wuta', 'Omi'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.ninegag.android.app', '9GAG'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.badoo.mobile', 'Badoo'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.sgiggle.production', 'Tango'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.hyperconnect.azar', 'Azar'), isTrue);
      expect(AppState.isStrictlyNonProductive('me.zepeto.main', 'ZEPETO'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.yalla.yallagroup', 'Yalla'), isTrue);
      expect(AppState.isStrictlyNonProductive('enterprises.dating.boo', 'Boo'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.sugar.live', 'SugarLive'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.bereal.ft', 'BeReal'), isTrue);

      // Non-strict apps (like community or developer tools): MUST BE FALSE
      expect(AppState.isStrictlyNonProductive('com.testerscommunity', 'Testers Community', 4), isFalse);
      expect(AppState.isStrictlyNonProductive('com.example.communityapp', 'My Community App', 4), isFalse);
    });

    test('markAppAsProductive whitelists non-strict app and rejects strict non-productive app', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      // Attempt to mark TikTok as productive -> MUST FAIL / BE REJECTED
      await appState.markAppAsProductive('com.zhiliaoapp.musically', appName: 'TikTok');
      expect(appState.customProductiveApps.contains('com.zhiliaoapp.musically'), isFalse);
      expect(AppState.isProductiveApp('com.zhiliaoapp.musically', 'TikTok'), isFalse);

      // Mark community app as productive -> MUST SUCCEED
      await appState.markAppAsProductive('com.example.communityapp', appName: 'My Community App');
      expect(appState.customProductiveApps.contains('com.example.communityapp'), isTrue);
      expect(AppState.isProductiveApp('com.example.communityapp', 'My Community App'), isTrue);
    });

    test('markAppAsPermanentlyNonProductive permanently locks app and prevents reverting', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      const testPkg = 'com.productive.distractingapp';
      // Initially not blocked
      expect(appState.isAppBlocked(testPkg), isFalse);

      // User marks as permanently non-productive
      await appState.markAppAsPermanentlyNonProductive(testPkg, appName: 'Distracting App');

      // Now blocked and strictly non-productive
      expect(appState.userNonProductiveApps.contains(testPkg), isTrue);
      expect(AppState.isStrictlyNonProductive(testPkg, 'Distracting App'), isTrue);
      expect(AppState.isProductiveApp(testPkg, 'Distracting App'), isFalse);
      expect(appState.isAppBlocked(testPkg), isTrue);

      // User tries to revert by marking as productive -> MUST BE REJECTED
      await appState.markAppAsProductive(testPkg, appName: 'Distracting App');
      expect(appState.customProductiveApps.contains(testPkg), isFalse);
      expect(AppState.isProductiveApp(testPkg, 'Distracting App'), isFalse);
      expect(appState.isAppBlocked(testPkg), isTrue);

      // Check system essential apps cannot be marked as permanently non-productive
      expect(AppState.isSystemEssentialApp('com.android.settings'), isTrue);
      expect(AppState.isSystemEssentialApp('com.android.vending'), isTrue);
      await appState.markAppAsPermanentlyNonProductive('com.android.settings', appName: 'Settings');
      expect(appState.userNonProductiveApps.contains('com.android.settings'), isFalse);
    });
  });

  group('Gambling Apps Permanent Prohibition & Islamic Reminder', () {
    test('isGamblingApp correctly identifies gambling, casino, slot, and betting apps', () {
      expect(AppState.isGamblingApp('com.neptune.domino', 'Higgs Domino Island'), isTrue);
      expect(AppState.isGamblingApp('com.higgs.dominoisland', 'Domino Island'), isTrue);
      expect(AppState.isGamblingApp('com.playtika.slotomania', 'Slotomania'), isTrue);
      expect(AppState.isGamblingApp('com.zynga.livepoker', 'Zynga Poker'), isTrue);
      expect(AppState.isGamblingApp('com.bet365', 'Bet365'), isTrue);
      expect(AppState.isGamblingApp('com.game.slot777', 'Slot Gacor 777'), isTrue);
      expect(AppState.isGamblingApp('com.pragmatic.olympus', 'Gates of Olympus'), isTrue);
      expect(AppState.isGamblingApp('com.judionline.taruhan', 'Taruhan Bola Sbobet'), isTrue);
      expect(AppState.isGamblingApp('com.toto.togel', 'Togel Online'), isTrue);

      // Exclusions
      expect(AppState.isGamblingApp('com.dominospizza', "Domino's Pizza"), isFalse);
      expect(AppState.isGamblingApp('com.sloth.care', 'Sloth Sanctuary'), isFalse);
      expect(AppState.isGamblingApp('com.android.settings', 'Settings'), isFalse);
      expect(AppState.isGamblingApp('com.google.android.calendar', 'Google Calendar'), isFalse);
    });

    test('Gambling apps are permanently prohibited (isAppProhibited) across all languages', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      expect(appState.isAppProhibited('com.neptune.domino', 'Higgs Domino'), isTrue);
      expect(appState.isAppProhibited('com.playtika.slotomania', 'Slotomania'), isTrue);
      expect(appState.isAppProhibited('com.bet365', 'Bet365'), isTrue);

      expect(AppState.isProhibitedAppStatic('com.neptune.domino', 'Higgs Domino', 'id'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.neptune.domino', 'Higgs Domino', 'en'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.neptune.domino', 'Higgs Domino', 'ar'), isTrue);
    });

    test('Gambling apps can never be marked as productive', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      expect(AppState.isStrictlyNonProductive('com.neptune.domino', 'Higgs Domino'), isTrue);
      expect(AppState.isProductiveApp('com.neptune.domino', 'Higgs Domino'), isFalse);

      // Attempt to mark as productive must be rejected
      await appState.markAppAsProductive('com.neptune.domino', appName: 'Higgs Domino');
      expect(appState.customProductiveApps.contains('com.neptune.domino'), isFalse);
      expect(AppState.isProductiveApp('com.neptune.domino', 'Higgs Domino'), isFalse);
    });
  });
}

