import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/utils/ghadhul_bashar_data.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ghadhul Bashar Verses Data (GhadhulBasharData)', () {
    test('Contains valid Quran verses forbidding indecency and lowering gaze', () {
      expect(GhadhulBasharData.verses.length, greaterThanOrEqualTo(6));

      for (final verse in GhadhulBasharData.verses) {
        expect(verse.surahName.isNotEmpty, isTrue);
        expect(verse.surahNumber, greaterThan(0));
        expect(verse.ayahNumber, greaterThan(0));
        expect(verse.arabic.isNotEmpty, isTrue);
        expect(verse.translations['id'], isNotNull);
        expect(verse.translations['en'], isNotNull);
        expect(verse.translations['ms'], isNotNull);
        expect(verse.translations['ar'], isNotNull);
        expect(verse.translations['af'], isNotNull);
        expect(verse.translations['sw'], isNotNull);
        expect(verse.getReference().startsWith('QS.'), isTrue);
      }
    });

    test('getRandomVerse returns a valid verse from the list', () {
      for (int i = 0; i < 20; i++) {
        final verse = GhadhulBasharData.getRandomVerse();
        expect(GhadhulBasharData.verses.contains(verse), isTrue);
      }
    });
  });

  group('Browser Detection (isBrowserApp)', () {
    test('Identifies popular web browsers', () {
      final browsers = [
        {'pkg': 'com.android.chrome', 'name': 'Google Chrome'},
        {'pkg': 'org.mozilla.firefox', 'name': 'Firefox'},
        {'pkg': 'com.sec.android.app.sbrowser', 'name': 'Samsung Internet'},
        {'pkg': 'com.microsoft.emmx', 'name': 'Microsoft Edge'},
        {'pkg': 'com.brave.browser', 'name': 'Brave Private Web Browser'},
        {'pkg': 'com.opera.browser', 'name': 'Opera Browser'},
        {'pkg': 'com.opera.mini.native', 'name': 'Opera Mini'},
        {'pkg': 'com.duckduckgo.mobile.android', 'name': 'DuckDuckGo Privacy Browser'},
        {'pkg': 'com.vivaldi.browser', 'name': 'Vivaldi Browser'},
        {'pkg': 'com.ucmobile.intl', 'name': 'UC Browser'},
        {'pkg': 'com.kiwibrowser.browser', 'name': 'Kiwi Browser'},
        {'pkg': 'org.torproject.torbrowser', 'name': 'Tor Browser'},
        {'pkg': 'com.heytap.browser', 'name': 'Heytap Browser'},
        {'pkg': 'com.mi.globalbrowser', 'name': 'Mi Browser'},
      ];

      for (final b in browsers) {
        expect(
          AppState.isBrowserApp(b['pkg']!, b['name']!),
          isTrue,
          reason: 'Failed to identify browser: ${b['name']} (${b['pkg']})',
        );
      }
    });

    test('Does not falsely flag non-browser apps', () {
      final nonBrowsers = [
        {'pkg': 'com.spotify.music', 'name': 'Spotify'},
        {'pkg': 'com.whatsapp', 'name': 'WhatsApp'},
        {'pkg': 'com.google.android.calculator', 'name': 'Calculator'},
        {'pkg': 'com.google.android.apps.photos', 'name': 'Google Photos'},
        {'pkg': 'com.camerasideas.instashot', 'name': 'InShot'},
      ];

      for (final nb in nonBrowsers) {
        expect(
          AppState.isBrowserApp(nb['pkg']!, nb['name']!),
          isFalse,
          reason: 'Falsely flagged as browser: ${nb['name']} (${nb['pkg']})',
        );
      }
    });
  });

  group('VPN Detection (isVpnApp)', () {
    test('Identifies popular VPN and Proxy apps', () {
      final vpns = [
        {'pkg': 'com.cloudflare.onedotonedotonedotone', 'name': '1.1.1.1 + WARP'},
        {'pkg': 'com.wireguard.android', 'name': 'WireGuard'},
        {'pkg': 'net.openvpn.openvpn', 'name': 'OpenVPN Connect'},
        {'pkg': 'ch.protonvpn.android', 'name': 'Proton VPN'},
        {'pkg': 'com.nordvpn.android', 'name': 'NordVPN'},
        {'pkg': 'com.expressvpn.vpn', 'name': 'ExpressVPN'},
        {'pkg': 'free.vpn.unblock.proxy.turbovpn', 'name': 'Turbo VPN'},
        {'pkg': 'com.surfshark.vpnclient.android', 'name': 'Surfshark'},
        {'pkg': 'com.vpn.free.hotspot', 'name': 'SuperVPN Fast VPN Client'},
      ];

      for (final v in vpns) {
        expect(
          AppState.isVpnApp(v['pkg']!, v['name']!),
          isTrue,
          reason: 'Failed to identify VPN: ${v['name']} (${v['pkg']})',
        );
      }
    });

    test('Does not falsely flag regular apps as VPN', () {
      final nonVpns = [
        {'pkg': 'com.spotify.music', 'name': 'Spotify'},
        {'pkg': 'com.google.android.gm', 'name': 'Gmail'},
        {'pkg': 'com.android.settings', 'name': 'Settings'},
      ];

      for (final nv in nonVpns) {
        expect(
          AppState.isVpnApp(nv['pkg']!, nv['name']!),
          isFalse,
          reason: 'Falsely flagged as VPN: ${nv['name']} (${nv['pkg']})',
        );
      }
    });
  });

  group('Restricted Adult Content Region Detection', () {
    test('Identifies Indonesian, Malaysian, and Arabic language settings as restricted regions', () {
      expect(AppState.isRestrictedAdultContentRegion('id'), isTrue);
      expect(AppState.isRestrictedAdultContentRegion('ms'), isTrue);
      expect(AppState.isRestrictedAdultContentRegion('ar'), isTrue);
    });
  });

  group('Ghadhul Bashar Reminder Trigger (shouldShowGhadhulBasharReminder)', () {
    test('Always triggers for web browsers regardless of language', () {
      expect(
        AppState.shouldShowGhadhulBasharReminder('com.android.chrome', 'Chrome', 'en'),
        isTrue,
      );
      expect(
        AppState.shouldShowGhadhulBasharReminder('org.mozilla.firefox', 'Firefox', 'id'),
        isTrue,
      );
      expect(
        AppState.shouldShowGhadhulBasharReminder('com.sec.android.app.sbrowser', 'Samsung Internet', 'ms'),
        isTrue,
      );
    });

    test('Triggers for VPN apps when language is from restricted region (id, ms, ar)', () {
      expect(
        AppState.shouldShowGhadhulBasharReminder('com.cloudflare.onedotonedotonedotone', '1.1.1.1', 'id'),
        isTrue,
      );
      expect(
        AppState.shouldShowGhadhulBasharReminder('free.vpn.unblock.proxy.turbovpn', 'Turbo VPN', 'ms'),
        isTrue,
      );
      expect(
        AppState.shouldShowGhadhulBasharReminder('ch.protonvpn.android', 'Proton VPN', 'ar'),
        isTrue,
      );
    });

    test('Does not trigger for general non-browser, non-VPN apps', () {
      expect(
        AppState.shouldShowGhadhulBasharReminder('com.spotify.music', 'Spotify', 'id'),
        isFalse,
      );
      expect(
        AppState.shouldShowGhadhulBasharReminder('com.whatsapp', 'WhatsApp', 'id'),
        isFalse,
      );
      expect(
        AppState.shouldShowGhadhulBasharReminder('com.google.android.calculator', 'Calculator', 'id'),
        isFalse,
      );
    });
  });

  group('Productivity Classification for Browsers & VPNs', () {
    test('Browsers and VPNs are classified as productive so they are not blocked by 50 points', () {
      expect(AppState.isProductiveApp('com.android.chrome', 'Chrome'), isTrue);
      expect(AppState.isProductiveApp('org.mozilla.firefox', 'Firefox'), isTrue);
      expect(AppState.isProductiveApp('com.cloudflare.onedotonedotonedotone', '1.1.1.1'), isTrue);
      expect(AppState.isProductiveApp('free.vpn.unblock.proxy.turbovpn', 'Turbo VPN'), isTrue);
    });
  });

  group('Translations for Ghadhul Bashar Dialog', () {
    test('All supported languages have ok, cancel, and ghadhul_bashar keys', () {
      final langs = ['id', 'en', 'ms', 'ar', 'af', 'sw'];
      for (final lang in langs) {
        expect(Translations.get(lang, 'ok').isNotEmpty, isTrue);
        expect(Translations.get(lang, 'cancel').isNotEmpty, isTrue);
        expect(Translations.get(lang, 'ghadhul_bashar_title').isNotEmpty, isTrue);
        expect(Translations.get(lang, 'ghadhul_bashar_subtitle').isNotEmpty, isTrue);
      }
    });
  });
}
