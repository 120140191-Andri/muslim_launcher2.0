import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/app_list_screen.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

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

    test('Games (category 0, GTA, Bully, Learn 2 Fly) are strictly non-productive without exception and can never be marked as productive', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      // Test category 0 game
      expect(AppState.isStrictlyNonProductive('com.tafusoft.pepelo', 'Pepelo', 0), isTrue);
      expect(AppState.isStrictlyNonProductive('com.heroicinteractive.learn2fly', 'Learn 2 Fly'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.rockstargames.gtasa', 'GTA: San Andreas'), isTrue);
      expect(AppState.isStrictlyNonProductive('com.rockstargames.bully', 'Bully: Anniversary Edition'), isTrue);

      // Attempting to mark any of these as productive must be rejected
      await appState.markAppAsProductive('com.rockstargames.gtasa', appName: 'GTA: San Andreas', category: 0);
      expect(appState.customProductiveApps.contains('com.rockstargames.gtasa'), isFalse);
      expect(AppState.isProductiveApp('com.rockstargames.gtasa', 'GTA: San Andreas', 0), isFalse);

      await appState.markAppAsProductive('com.heroicinteractive.learn2fly', appName: 'Learn 2 Fly', category: 0);
      expect(appState.customProductiveApps.contains('com.heroicinteractive.learn2fly'), isFalse);
      expect(AppState.isProductiveApp('com.heroicinteractive.learn2fly', 'Learn 2 Fly', 0), isFalse);
    });

    testWidgets('AppListScreen.showAppOptionsModal hides Tandai sebagai Aplikasi Produktif for games but shows for non-game blocked apps', (tester) async {
      final appState = AppState(prefs);
      await appState.setLanguage('id');
      await appState.toggleAppBlockedStatus('com.rockstargames.gtasa');
      await appState.toggleAppBlockedStatus('com.example.notes');

      final markProductiveText = Translations.get('id', 'mark_as_productive');

      // 1. Open modal for game -> must NOT show "Tandai sebagai Aplikasi Produktif"
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppListScreen.showAppOptionsModal(
                      context,
                      AppInfo(
                        appName: 'GTA SA',
                        packageName: 'com.rockstargames.gtasa',
                        category: 0,
                      ),
                    );
                  },
                  child: const Text('Open Game Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Game Modal'));
      await tester.pumpAndSettle();

      expect(find.text(markProductiveText), findsNothing);

      // Dismiss modal
      Navigator.of(tester.element(find.text('GTA SA'))).pop();
      await tester.pumpAndSettle();

      // 2. Open modal for non-game blocked app -> MUST show "Tandai sebagai Aplikasi Produktif"
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppListScreen.showAppOptionsModal(
                      context,
                      AppInfo(
                        appName: 'Work Notes',
                        packageName: 'com.example.notes',
                        category: -1,
                      ),
                    );
                  },
                  child: const Text('Open Notes Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Notes Modal'));
      await tester.pumpAndSettle();

      expect(find.text(markProductiveText), findsOneWidget);

      // Tap mark productive
      await tester.tap(find.text(markProductiveText));
      await tester.pumpAndSettle();

      expect(appState.customProductiveApps.contains('com.example.notes'), isTrue);
      expect(appState.blockedApps.contains('com.example.notes'), isFalse);
    });

    test('Scanner and Pemindai apps are always productive, never blocked, and never strictly non-productive', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      final scannerApps = [
        {'pkg': 'com.xiaomi.scanner', 'name': 'Pemindai'},
        {'pkg': 'com.intsig.camscanner', 'name': 'CamScanner'},
        {'pkg': 'com.adobe.scan.android', 'name': 'Adobe Scan'},
        {'pkg': 'com.gamma.scan', 'name': 'QR & Barcode Scanner'},
        {'pkg': 'com.google.ar.lens', 'name': 'Google Lens'},
        {'pkg': 'com.example.docscanner', 'name': 'Pemindai Dokumen'},
        {'pkg': 'com.example.qrscan', 'name': 'Pemindai QR & Barcode'},
        {'pkg': 'pdf.tap.scanner', 'name': 'TapScanner'},
        {'pkg': 'com.coolmobilesolution.fastscannerfree', 'name': 'Fast Scanner'},
      ];

      for (final app in scannerApps) {
        final pkg = app['pkg']!;
        final name = app['name']!;

        expect(AppState.isScannerApp(pkg, name), isTrue, reason: '$name ($pkg) should be recognized as scanner app');
        expect(AppState.isProductiveApp(pkg, name), isTrue, reason: '$name ($pkg) must be a productive app');
        expect(AppState.isStrictlyNonProductive(pkg, name), isFalse, reason: '$name ($pkg) must NEVER be strictly non-productive');
        expect(AppState.isNonProductiveApp(pkg, name), isFalse, reason: '$name ($pkg) must NEVER be classified as non-productive');
      }

      // Ensure Xiaomi apps do not collide with Omi dating app
      expect(AppState.isStrictlyNonProductive('com.xiaomi.scanner', 'Pemindai'), isFalse);
      expect(AppState.isStrictlyNonProductive('com.xiaomi.calendar', 'Kalender'), isFalse);
      expect(AppState.isStrictlyNonProductive('com.haoda.wuta.omichat', 'Omi'), isTrue);

      // Ensure English apps do not collide with NGL anonymous chat
      expect(AppState.isStrictlyNonProductive('com.example.english', 'English Dictionary'), isFalse);
      expect(AppState.isStrictlyNonProductive('com.nglreactnative', 'NGL'), isTrue);

      // Ensure Emoji apps do not collide with Moj short video platform
      expect(AppState.isStrictlyNonProductive('com.example.emoji', 'Emoji Keyboard'), isFalse);
      expect(AppState.isStrictlyNonProductive('in.mohalla.video.moj', 'Moj'), isTrue);

      // Test automatic unblocking in syncAppsWithCategories
      appState.blockedApps.add('com.xiaomi.scanner');
      expect(appState.blockedApps.contains('com.xiaomi.scanner'), isTrue);

      await appState.syncAppsWithCategories([
        {
          'packageName': 'com.xiaomi.scanner',
          'appName': 'Pemindai',
          'category': -1,
        }
      ]);

      expect(appState.blockedApps.contains('com.xiaomi.scanner'), isFalse);
    });

    test('Twitter / X (com.twitter.android) is strictly non-productive and blocked even if category is News (5)', () async {
      final appState = AppState(prefs);
      await pumpEventQueue();

      // Official X app (rebranded from Twitter by Elon Musk)
      const xPackage = 'com.twitter.android';
      const xLitePackage = 'com.twitter.android.lite';
      const xName = 'X';
      const xLiteName = 'X Lite';
      const newsCategory = 5; // CATEGORY_NEWS reported by Android OS for Twitter/X

      // Test X
      expect(AppState.isStrictlyNonProductive(xPackage, xName, newsCategory), isTrue);
      expect(AppState.isProductiveApp(xPackage, xName, newsCategory), isFalse);
      expect(AppState.isNonProductiveApp(xPackage, xName, newsCategory), isTrue);
      expect(AppState.isHighRiskSocialMediaApp(xPackage, xName), isTrue);

      // Test X Lite
      expect(AppState.isStrictlyNonProductive(xLitePackage, xLiteName, newsCategory), isTrue);
      expect(AppState.isProductiveApp(xLitePackage, xLiteName, newsCategory), isFalse);
      expect(AppState.isNonProductiveApp(xLitePackage, xLiteName, newsCategory), isTrue);

      // Test Instagram with Image category (3)
      expect(AppState.isStrictlyNonProductive('com.instagram.android', 'Instagram', 3), isTrue);
      expect(AppState.isProductiveApp('com.instagram.android', 'Instagram', 3), isFalse);
      expect(AppState.isNonProductiveApp('com.instagram.android', 'Instagram', 3), isTrue);

      // Test Reddit with News category (5)
      expect(AppState.isStrictlyNonProductive('com.reddit.frontpage', 'Reddit', 5), isTrue);
      expect(AppState.isProductiveApp('com.reddit.frontpage', 'Reddit', 5), isFalse);
      expect(AppState.isNonProductiveApp('com.reddit.frontpage', 'Reddit', 5), isTrue);

      // Ensure legitimate news apps are STILL productive with category 5
      expect(AppState.isStrictlyNonProductive('com.detik.portal', 'Detikcom', 5), isFalse);
      expect(AppState.isProductiveApp('com.detik.portal', 'Detikcom', 5), isTrue);
      expect(AppState.isNonProductiveApp('com.detik.portal', 'Detikcom', 5), isFalse);

      // Test automatic blocking of X in syncAppsWithCategories
      await appState.syncAppsWithCategories([
        {
          'packageName': xPackage,
          'appName': xName,
          'category': newsCategory,
        }
      ]);

      expect(appState.blockedApps.contains(xPackage), isTrue);
      expect(appState.isAppBlocked(xPackage), isTrue);
    });
  });
}



