import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/home/prohibited_app_overlay.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

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
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getApps') {
        return [
          {'packageName': 'ru.yandex.searchplugin', 'appName': 'Yandex Start', 'category': 7},
          {'packageName': 'com.android.chrome', 'appName': 'Chrome', 'category': 7},
        ];
      }
      return true;
    });
  });

  group('Prohibited Bypass Browser Detection (isProhibitedBypassBrowser)', () {
    test('Correctly identifies known bypass / proxy / anti-censorship browsers', () {
      // Yandex
      expect(AppState.isProhibitedBypassBrowser('ru.yandex.searchplugin', 'Yandex Start'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.yandex.browser', 'Yandex Browser'), isTrue);

      // Aloha Browser
      expect(AppState.isProhibitedBypassBrowser('com.alohamobile.browser', 'Aloha Browser'), isTrue);

      // UPX Proxy Browser
      expect(AppState.isProhibitedBypassBrowser('com.upx.browser', 'UPX Browser'), isTrue);

      // Puffin Cloud Browser
      expect(AppState.isProhibitedBypassBrowser('com.cloudmosa.puffinfree', 'Puffin'), isTrue);

      // Tor Browser
      expect(AppState.isProhibitedBypassBrowser('org.torproject.torbrowser', 'Tor Browser'), isTrue);

      // Opera Browser Family (built-in free VPN)
      expect(AppState.isProhibitedBypassBrowser('com.opera.browser', 'Opera Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.opera.mini.native', 'Opera Mini'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.opera.gx', 'Opera GX'), isTrue);

      // UC Browser Family (cloud proxy / bypass)
      expect(AppState.isProhibitedBypassBrowser('com.UCMobile.intl', 'UC Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.uc.browser.en', 'UC Browser Turbo'), isTrue);

      // Dedicated VPN / Privacy Browsers
      expect(AppState.isProhibitedBypassBrowser('net.epicbrowser.epic', 'Epic Privacy Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.avast.android.secure.browser', 'Avast Secure Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.tenta.android', 'Tenta Private VPN Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('org.hola.browser', 'Hola Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('org.nuplayer.inbrowser', 'InBrowser Incognito Tor'), isTrue);

      // Video Downloader / Bypass / Cloud Proxy Browsers
      expect(AppState.isProhibitedBypassBrowser('com.transsion.phoenix', 'Phoenix Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.ksmobile.cb', 'CM Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.coccoc.trinhduyet', 'Coc Coc Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.mx.browser', 'Maxthon Cloud Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('mobi.mfront.android.browser', 'Dolphin Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.brobrowser', 'Bro Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.croxyproxy', 'CroxyProxy Browser'), isTrue);

      // Anti-Blokir & Bokeh Browsers
      expect(AppState.isProhibitedBypassBrowser('com.bf.browser.antiblokir', 'BF Browser Anti Blokir'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.xnx.browser.antiblokir', 'XNX Browser Anti Blokir'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.browser.bokeh', 'Video Bokeh Browser'), isTrue);

      // Generic browser with VPN/proxy keyword
      expect(AppState.isProhibitedBypassBrowser('com.fast.browser.vpn', 'Fast VPN Browser'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.some.browser', 'Proxy Browser Unblock'), isTrue);
      expect(AppState.isProhibitedBypassBrowser('com.some.stealth', 'Secret Stealth Browser'), isTrue);
    });

    test('Does NOT flag standard web browsers as prohibited', () {
      expect(AppState.isProhibitedBypassBrowser('com.android.chrome', 'Chrome'), isFalse);
      expect(AppState.isProhibitedBypassBrowser('org.mozilla.firefox', 'Firefox'), isFalse);
      expect(AppState.isProhibitedBypassBrowser('com.sec.android.app.sbrowser', 'Samsung Internet'), isFalse);
      expect(AppState.isProhibitedBypassBrowser('com.microsoft.emmx', 'Edge'), isFalse);
      expect(AppState.isProhibitedBypassBrowser('com.brave.browser', 'Brave'), isFalse);
    });
  });

  group('Pure VPN Apps Protection (isPureVpnApp & Ghadhul Bashar)', () {
    test('Pure VPN apps are recognized and NEVER flagged as prohibited', () {
      final pureVpns = [
        {'pkg': 'free.vpn.unblock.proxy.turbovpn', 'name': 'Turbo VPN'},
        {'pkg': 'com.cloudflare.onedotonedotonedotone', 'name': '1.1.1.1'},
        {'pkg': 'com.psiphon3', 'name': 'Psiphon Pro'},
        {'pkg': 'com.wireguard.android', 'name': 'WireGuard'},
        {'pkg': 'de.blinkt.openvpn', 'name': 'OpenVPN for Android'},
        {'pkg': 'com.nordvpn.android', 'name': 'NordVPN'},
        {'pkg': 'com.expressvpn.vpn', 'name': 'ExpressVPN'},
        {'pkg': 'ch.protonvpn.android', 'name': 'Proton VPN'},
        {'pkg': 'com.surfshark.vpnclient.android', 'name': 'Surfshark'},
        {'pkg': 'com.jrzheng.supervpnfree', 'name': 'SuperVPN'},
        {'pkg': 'com.fast.free.unblock.thunder.vpn', 'name': 'Thunder VPN'},
      ];

      for (final vpn in pureVpns) {
        // Must be recognized as pure VPN
        expect(AppState.isPureVpnApp(vpn['pkg']!, vpn['name']!), isTrue,
            reason: 'Should be recognized as pure VPN: ${vpn['name']}');

        // Must NOT be flagged as prohibited bypass browser
        expect(AppState.isProhibitedBypassBrowser(vpn['pkg']!, vpn['name']!), isFalse,
            reason: 'Pure VPN should not be prohibited: ${vpn['name']}');

        // Must NOT be prohibited even in restricted regions
        expect(AppState.isProhibitedAppStatic(vpn['pkg']!, vpn['name']!, 'id'), isFalse,
            reason: 'Pure VPN should not be prohibited in ID: ${vpn['name']}');

        // MUST trigger Ghadhul Bashar Islamic reminder in restricted regions
        expect(AppState.shouldShowGhadhulBasharReminder(vpn['pkg']!, vpn['name']!, 'id'), isTrue,
            reason: 'Pure VPN should trigger Ghadhul Bashar reminder in ID: ${vpn['name']}');
      }
    });

    test('Bypass browsers with built-in VPNs are NOT pure VPN apps', () {
      expect(AppState.isPureVpnApp('com.opera.browser', 'Opera Browser'), isFalse);
      expect(AppState.isPureVpnApp('com.alohamobile.browser', 'Aloha Browser'), isFalse);
      expect(AppState.isPureVpnApp('com.upx.browser', 'UPX Browser'), isFalse);
      expect(AppState.isPureVpnApp('org.torproject.torbrowser', 'Tor Browser'), isFalse);
    });
  });

  group('Explicit Adult Content Apps Detection (isExplicitAdultApp)', () {
    test('Correctly identifies dedicated adult content applications', () {
      // Nekopoi & Hentai/Doujin
      expect(AppState.isExplicitAdultApp('com.nekopoi.care', 'Nekopoi'), isTrue);
      expect(AppState.isExplicitAdultApp('app.nekopoi', 'Nekopoi Care'), isTrue);
      expect(AppState.isExplicitAdultApp('com.hanime', 'Hanime TV'), isTrue);
      expect(AppState.isExplicitAdultApp('com.doujindesu', 'Doujindesu'), isTrue);
      expect(AppState.isExplicitAdultApp('com.mangasusu', 'Mangasusu 18+'), isTrue);

      // Major Adult Tubes
      expect(AppState.isExplicitAdultApp('com.pornhub.android', 'Pornhub'), isTrue);
      expect(AppState.isExplicitAdultApp('com.xvideos.app', 'XVideos'), isTrue);
      expect(AppState.isExplicitAdultApp('com.xhamster.app', 'XHamster'), isTrue);
      expect(AppState.isExplicitAdultApp('com.redtube', 'RedTube'), isTrue);
      expect(AppState.isExplicitAdultApp('com.youporn', 'YouPorn'), isTrue);
      expect(AppState.isExplicitAdultApp('com.brazzers', 'Brazzers'), isTrue);
      expect(AppState.isExplicitAdultApp('com.spankbang', 'SpankBang'), isTrue);

      // Indonesian / Regional Adult APKs
      expect(AppState.isExplicitAdultApp('com.simontox.app', 'Simontox'), isTrue);
      expect(AppState.isExplicitAdultApp('com.simontok.app', 'SiMontok'), isTrue);
      expect(AppState.isExplicitAdultApp('com.simont9k', 'Simont9k'), isTrue);
      expect(AppState.isExplicitAdultApp('com.maxtube', 'Maxtube'), isTrue);
      expect(AppState.isExplicitAdultApp('com.overhot', 'Overhot'), isTrue);

      // Adult Cam & Streaming
      expect(AppState.isExplicitAdultApp('com.stripchat', 'Stripchat'), isTrue);
      expect(AppState.isExplicitAdultApp('com.chaturbate', 'Chaturbate'), isTrue);
      expect(AppState.isExplicitAdultApp('com.onlyfans', 'OnlyFans'), isTrue);

      // Adult Solicitation & Prostitution Platforms (MiChat)
      expect(AppState.isExplicitAdultApp('com.michat', 'MiChat'), isTrue);
      expect(AppState.isExplicitAdultApp('com.michat.lite', 'MiChat Lite'), isTrue);

      // Adult Leaked Content & Storage Hubs (TeraBox)
      expect(AppState.isExplicitAdultApp('com.dubox.drive', 'TeraBox'), isTrue);
      expect(AppState.isExplicitAdultApp('com.terabox.app', 'TeraBox Cloud'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.dubox.drive', 'TeraBox', 'id'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.dubox.drive', 'TeraBox', 'en'), isTrue);

      // Adult colloquial keywords
      expect(AppState.isExplicitAdultApp('com.app.bokep', 'Koleksi Bokep'), isTrue);
      expect(AppState.isExplicitAdultApp('com.javhd.player', 'JAV HD Player'), isTrue);
    });

    test('Does NOT flag legitimate non-adult apps', () {
      expect(AppState.isExplicitAdultApp('com.android.chrome', 'Chrome'), isFalse);
      expect(AppState.isExplicitAdultApp('com.whatsapp', 'WhatsApp'), isFalse);
      expect(AppState.isExplicitAdultApp('free.vpn.unblock.proxy.turbovpn', 'Turbo VPN'), isFalse);
      expect(AppState.isExplicitAdultApp('com.google.android.youtube', 'YouTube'), isFalse);
      expect(AppState.isExplicitAdultApp('org.telegram.messenger', 'Telegram'), isFalse);
    });

    test('Explicit adult apps are prohibited globally across ALL countries', () {
      // Even in non-restricted regions (en, sw, af), explicit adult apps are strictly prohibited
      expect(AppState.isProhibitedAppStatic('com.pornhub.android', 'Pornhub', 'en'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.nekopoi.care', 'Nekopoi', 'en'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.simontox.app', 'Simontox', 'sw'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.xvideos.app', 'XVideos', 'af'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.hanime', 'Hanime', 'id'), isTrue);
      expect(AppState.isProhibitedAppStatic('com.michat', 'MiChat', 'en'), isTrue);
    });
  });

  group('Regional Enforcement (isAppProhibited)', () {
    test('Prohibits bypass browsers in restricted adult content regions (id, ms, ar)', () {
      expect(
        AppState.isProhibitedAppStatic('ru.yandex.searchplugin', 'Yandex Start', 'id'),
        isTrue,
      );
      expect(
        AppState.isProhibitedAppStatic('com.alohamobile.browser', 'Aloha Browser', 'ms'),
        isTrue,
      );
      expect(
        AppState.isProhibitedAppStatic('org.torproject.torbrowser', 'Tor Browser', 'ar'),
        isTrue,
      );
    });

    test('Standard browsers remain unprohibited in restricted regions (handled by Ghadhul Bashar)', () {
      expect(
        AppState.isProhibitedAppStatic('com.android.chrome', 'Chrome', 'id'),
        isFalse,
      );
      expect(
        AppState.isProhibitedAppStatic('org.mozilla.firefox', 'Firefox', 'ms'),
        isFalse,
      );
    });
  });

  group('ProhibitedAppOverlay UI Test', () {
    testWidgets('Renders prohibition shield, title, verse, and Back to Home button for bypass browsers', (tester) async {
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: ProhibitedAppOverlay(packageName: 'ru.yandex.searchplugin'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(Translations.get('id', 'prohibited_app_title')), findsOneWidget);
      expect(find.text(Translations.get('id', 'prohibited_suggestion_title')), findsOneWidget);
      expect(find.text(Translations.get('id', 'go_back')), findsOneWidget);
      expect(find.byIcon(Icons.gpp_bad_rounded), findsOneWidget);
    });

    testWidgets('Renders Islamic advice and uninstall button for explicit adult content apps', (tester) async {
      final appState = AppState(prefs);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: ProhibitedAppOverlay(packageName: 'com.nekopoi.care'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Checks that adult app specific description & suggestion title appear
      expect(find.text(Translations.get('id', 'prohibited_adult_desc')), findsOneWidget);
      expect(find.text(Translations.get('id', 'prohibited_adult_suggestion_title')), findsOneWidget);
      expect(find.text(Translations.get('id', 'uninstall_prohibited_app')), findsOneWidget);
      expect(find.text(Translations.get('id', 'go_back')), findsOneWidget);
    });

    testWidgets('Tapping Kembali button clears prohibited state', (tester) async {
      final appState = AppState(prefs);
      appState.setProhibitedPackage('ru.yandex.searchplugin');
      expect(appState.lastAttemptedProhibitedPackage, equals('ru.yandex.searchplugin'));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: ProhibitedAppOverlay(packageName: 'ru.yandex.searchplugin'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(Translations.get('id', 'go_back')));
      await tester.tap(find.text(Translations.get('id', 'go_back')));
      await tester.pumpAndSettle();

      expect(appState.lastAttemptedProhibitedPackage, isNull);
    });
  });
}
