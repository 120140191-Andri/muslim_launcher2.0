import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Music & Audio App Classification (isMusicOrAudioApp)', () {
    test('Identifies online music streaming apps', () {
      final onlineApps = [
        {'pkg': 'com.spotify.music', 'name': 'Spotify'},
        {'pkg': 'com.spotify.lite', 'name': 'Spotify Lite'},
        {'pkg': 'com.soundcloud.android', 'name': 'SoundCloud'},
        {'pkg': 'com.google.android.apps.youtube.music', 'name': 'YouTube Music'},
        {'pkg': 'com.apple.android.music', 'name': 'Apple Music'},
        {'pkg': 'deezer.android.app', 'name': 'Deezer'},
        {'pkg': 'com.aspiro.tidal', 'name': 'TIDAL'},
        {'pkg': 'com.amazon.mp3', 'name': 'Amazon Music'},
        {'pkg': 'com.tencent.ibg.joox', 'name': 'JOOX Music'},
        {'pkg': 'com.moonvideo.android.resso', 'name': 'Resso'},
        {'pkg': 'com.pandora.android', 'name': 'Pandora'},
        {'pkg': 'com.shazam.android', 'name': 'Shazam'},
        {'pkg': 'com.bandcamp.android', 'name': 'Bandcamp'},
        {'pkg': 'com.audiomack', 'name': 'Audiomack'},
        {'pkg': 'com.qobuz.music', 'name': 'Qobuz'},
        {'pkg': 'com.anghami', 'name': 'Anghami'},
        {'pkg': 'com.gaana', 'name': 'Gaana'},
        {'pkg': 'com.jio.media.jiobeats', 'name': 'JioSaavn'},
        {'pkg': 'com.bsb.hza.media', 'name': 'Wynk Music'},
        {'pkg': 'com.muserk.trebel', 'name': 'TREBEL Music'},
        {'pkg': 'tunein.player', 'name': 'TuneIn Radio'},
      ];

      for (var app in onlineApps) {
        expect(
          AppState.isMusicOrAudioApp(app['pkg']!, app['name']!),
          isTrue,
          reason: 'Failed to recognize online music app: ${app['name']} (${app['pkg']})',
        );
      }
    });

    test('Identifies offline music players (OEM & popular 3rd party)', () {
      final offlineApps = [
        {'pkg': 'com.sec.android.app.music', 'name': 'Samsung Music'},
        {'pkg': 'com.miui.player', 'name': 'Mi Music'},
        {'pkg': 'com.sonyericsson.music', 'name': 'Music'},
        {'pkg': 'com.huawei.music', 'name': 'Huawei Music'},
        {'pkg': 'com.vivo.music', 'name': 'i Music'},
        {'pkg': 'com.oppo.music', 'name': 'Music'},
        {'pkg': 'com.heytap.music', 'name': 'Heytap Music'},
        {'pkg': 'com.android.music', 'name': 'Default Music'},
        {'pkg': 'com.google.android.music', 'name': 'Google Play Music'},
        {'pkg': 'in.krosbits.musicolet', 'name': 'Musicolet'},
        {'pkg': 'com.maxmpz.audioplayer', 'name': 'Poweramp'},
        {'pkg': 'com.aimp.player', 'name': 'AIMP'},
        {'pkg': 'com.piyush.oto', 'name': 'Oto Music'},
        {'pkg': 'code.name.monkey.retromusic', 'name': 'Retro Music'},
        {'pkg': 'com.rhmsoft.pulsar', 'name': 'Pulsar'},
        {'pkg': 'com.rhmsoft.omnia', 'name': 'Omnia'},
        {'pkg': 'com.foobar2000.foobar2000', 'name': 'foobar2000'},
        {'pkg': 'ru.stellio.player', 'name': 'Stellio'},
        {'pkg': 'com.kodarkooperativet.blackplayerfree', 'name': 'BlackPlayer'},
        {'pkg': 'media.audioplayer.musicplayer', 'name': 'Muzio Player'},
        {'pkg': 'com.ringdroid.player', 'name': 'Lark Player'},
        {'pkg': 'com.example.customplayer', 'name': 'Pemutar Musik Offline'},
        {'pkg': 'com.example.audioplayer', 'name': 'Pemutar Audio'},
        {'pkg': 'com.example.mp3player', 'name': 'MP3 Player'},
        {'pkg': 'com.example.lagu', 'name': 'Pemutar Lagu'},
      ];

      for (var app in offlineApps) {
        expect(
          AppState.isMusicOrAudioApp(app['pkg']!, app['name']!),
          isTrue,
          reason: 'Failed to recognize offline music player: ${app['name']} (${app['pkg']})',
        );
      }
    });

    test('Recognizes Android Category 1 (Audio)', () {
      expect(
        AppState.isMusicOrAudioApp('com.random.customapp', 'Custom Audio App', 1),
        isTrue,
      );
    });

    test('Excludes Games, TikTok, and regular YouTube from music classification', () {
      expect(
        AppState.isMusicOrAudioApp('com.zhiliaoapp.musically', 'TikTok', 4),
        isFalse,
      );
      expect(
        AppState.isMusicOrAudioApp('com.google.android.youtube', 'YouTube', 2),
        isFalse,
      );
      expect(
        AppState.isMusicOrAudioApp('com.amanotes.pianotiles', 'Magic Tiles 3 - Music Game', 0),
        isFalse,
      );
      expect(
        AppState.isMusicOrAudioApp('com.game.musicracer', 'Music Racer', 0),
        isFalse,
      );
      expect(
        AppState.isMusicOrAudioApp('com.instagram.android', 'Instagram', 4),
        isFalse,
      );
    });
  });

  group('Productive Apps Classification (isProductiveApp)', () {
    test('Correctly identifies all essential productive apps as productive', () {
      final productiveApps = [
        // Phone, Dialer, SMS, Contacts
        {'pkg': 'com.google.android.dialer', 'name': 'Phone'},
        {'pkg': 'com.samsung.android.dialer', 'name': 'Telepon'},
        {'pkg': 'com.google.android.contacts', 'name': 'Contacts'},
        {'pkg': 'com.google.android.apps.messaging', 'name': 'Messages'},
        {'pkg': 'com.android.settings', 'name': 'Settings'},
        {'pkg': 'com.android.vending', 'name': 'Google Play Store'},
        // System tools
        {'pkg': 'com.google.android.deskclock', 'name': 'Clock'},
        {'pkg': 'com.google.android.calculator', 'name': 'Calculator'},
        {'pkg': 'com.google.android.calendar', 'name': 'Calendar'},
        {'pkg': 'com.google.android.googlecamera', 'name': 'Camera'},
        {'pkg': 'com.google.android.apps.photos', 'name': 'Photos'},
        {'pkg': 'com.google.android.apps.nbu.files', 'name': 'Files'},
        // Communication
        {'pkg': 'com.whatsapp', 'name': 'WhatsApp'},
        {'pkg': 'com.whatsapp.w4b', 'name': 'WhatsApp Business'},
        {'pkg': 'org.telegram.messenger', 'name': 'Telegram'},
        {'pkg': 'us.zoom.videomeetings', 'name': 'Zoom Workplace'},
        {'pkg': 'com.google.android.apps.tachyon', 'name': 'Google Meet'},
        {'pkg': 'com.microsoft.teams', 'name': 'Microsoft Teams'},
        {'pkg': 'com.slack', 'name': 'Slack'},
        {'pkg': 'com.google.android.gm', 'name': 'Gmail'},
        {'pkg': 'com.microsoft.office.outlook', 'name': 'Microsoft Outlook'},
        // Office, Docs & Cloud
        {'pkg': 'com.google.android.apps.docs', 'name': 'Google Drive'},
        {'pkg': 'com.google.android.apps.docs.editors.docs', 'name': 'Google Docs'},
        {'pkg': 'com.google.android.apps.docs.editors.sheets', 'name': 'Google Sheets'},
        {'pkg': 'com.google.android.keep', 'name': 'Google Keep'},
        {'pkg': 'com.microsoft.office.word', 'name': 'Microsoft Word'},
        {'pkg': 'cn.wps.moffice_eng', 'name': 'WPS Office'},
        {'pkg': 'so.notion.app', 'name': 'Notion'},
        {'pkg': 'com.adobe.reader', 'name': 'Adobe Acrobat Reader'},
        // Browsers
        {'pkg': 'com.android.chrome', 'name': 'Chrome'},
        {'pkg': 'org.mozilla.firefox', 'name': 'Firefox'},
        {'pkg': 'com.sec.android.app.sbrowser', 'name': 'Samsung Internet'},
        {'pkg': 'com.microsoft.emmx', 'name': 'Microsoft Edge'},
        // Navigation & Maps
        {'pkg': 'com.google.android.apps.maps', 'name': 'Google Maps'},
        {'pkg': 'com.waze', 'name': 'Waze'},
        // Transportation
        {'pkg': 'com.gojek.app', 'name': 'Gojek'},
        {'pkg': 'com.grabtaxi.passenger', 'name': 'Grab'},
        {'pkg': 'com.taxsee.taxsee', 'name': 'Maxim'},
        // Banking & Finance
        {'pkg': 'com.bca', 'name': 'BCA mobile'},
        {'pkg': 'id.co.bankmandiri.livin', 'name': 'Livin by Mandiri'},
        {'pkg': 'id.co.bri.brimo', 'name': 'BRImo'},
        {'pkg': 'id.co.bankbsi.mobilebanking', 'name': 'BSI Mobile'},
        {'pkg': 'id.dana', 'name': 'DANA'},
        {'pkg': 'ovo.id', 'name': 'OVO'},
        {'pkg': 'com.gopay.consumer', 'name': 'GoPay'},
        // Islamic Apps
        {'pkg': 'com.al.quran.indonesia', 'name': 'Al Quran Indonesia'},
        {'pkg': 'com.bitsmedia.muslimpro', 'name': 'Muslim Pro'},
        {'pkg': 'com.jadwal.sholat', 'name': 'Jadwal Sholat & Adzan'},
        // Music Apps (Online & Offline)
        {'pkg': 'com.spotify.music', 'name': 'Spotify'},
        {'pkg': 'com.soundcloud.android', 'name': 'SoundCloud'},
        {'pkg': 'com.maxmpz.audioplayer', 'name': 'Poweramp'},
        {'pkg': 'com.sec.android.app.music', 'name': 'Samsung Music'},
      ];

      for (var app in productiveApps) {
        expect(
          AppState.isProductiveApp(app['pkg']!, app['name']!),
          isTrue,
          reason: 'Productive app was NOT recognized: ${app['name']} (${app['pkg']})',
        );
        expect(
          AppState.isNonProductiveApp(app['pkg']!, app['name']!),
          isFalse,
          reason: 'Productive app was mistakenly marked non-productive: ${app['name']} (${app['pkg']})',
        );
      }
    });

    test('Recognizes Android OS Productive Categories (7: Productivity, 6: Maps, 5: News, 3: Image, 1: Audio)', () {
      expect(AppState.isProductiveApp('com.custom.office', 'My Tool', 7), isTrue);
      expect(AppState.isProductiveApp('com.custom.maps', 'My Maps', 6), isTrue);
      expect(AppState.isProductiveApp('com.custom.news', 'My News', 5), isTrue);
      expect(AppState.isProductiveApp('com.custom.gallery', 'My Gallery', 3), isTrue);
      expect(AppState.isProductiveApp('com.custom.audio', 'My Audio', 1), isTrue);
    });
  });

  group('Non-Productive Apps Classification (isNonProductiveApp)', () {
    test('Correctly identifies games, social media, entertainment video, and web novels', () {
      final nonProductiveApps = [
        // Games
        {'pkg': 'com.mobile.legends', 'name': 'Mobile Legends: Bang Bang', 'cat': 0},
        {'pkg': 'com.dts.freefireth', 'name': 'Free Fire', 'cat': 0},
        {'pkg': 'com.tencent.ig', 'name': 'PUBG MOBILE', 'cat': 0},
        {'pkg': 'com.mihoyo.genshinimpact', 'name': 'Genshin Impact', 'cat': 0},
        {'pkg': 'com.roblox.client', 'name': 'Roblox', 'cat': -1},
        {'pkg': 'com.kiloo.subwaysurf', 'name': 'Subway Surfers', 'cat': -1},
        {'pkg': 'com.king.candycrushsaga', 'name': 'Candy Crush Saga', 'cat': -1},
        {'pkg': 'com.supercell.clashofclans', 'name': 'Clash of Clans', 'cat': 0},
        {'pkg': 'com.kitkagames.fallbuddies', 'name': 'Stumble Guys', 'cat': -1},
        {'pkg': 'com.neptune.domino', 'name': 'Higgs Domino Island', 'cat': -1},
        {'pkg': 'com.ea.gp.fifamobile', 'name': 'EA SPORTS FC Mobile', 'cat': -1},
        {'pkg': 'com.konami.pesam', 'name': 'eFootball', 'cat': -1},
        // Social Media & Mindless Scrolling
        {'pkg': 'com.zhiliaoapp.musically', 'name': 'TikTok', 'cat': 4},
        {'pkg': 'com.ss.android.ugc.trill', 'name': 'TikTok Lite', 'cat': 4},
        {'pkg': 'com.instagram.android', 'name': 'Instagram', 'cat': 4},
        {'pkg': 'com.instagram.barcelona', 'name': 'Threads', 'cat': 4},
        {'pkg': 'com.facebook.katana', 'name': 'Facebook', 'cat': 4},
        {'pkg': 'com.twitter.android', 'name': 'X', 'cat': 4},
        {'pkg': 'com.snapchat.android', 'name': 'Snapchat', 'cat': 4},
        {'pkg': 'com.pinterest', 'name': 'Pinterest', 'cat': 4},
        {'pkg': 'com.reddit.frontpage', 'name': 'Reddit', 'cat': 4},
        {'pkg': 'com.kwai.video', 'name': 'SnackVideo', 'cat': 4},
        {'pkg': 'video.like', 'name': 'Likee', 'cat': 4},
        {'pkg': 'sg.bigo.live', 'name': 'Bigo Live', 'cat': 4},
        {'pkg': 'com.tinder', 'name': 'Tinder', 'cat': 4},
        {'pkg': 'com.michat', 'name': 'MiChat', 'cat': 4},
        // Video Streaming & Binge Entertainment
        {'pkg': 'com.google.android.youtube', 'name': 'YouTube', 'cat': 2},
        {'pkg': 'com.netflix.mediaclient', 'name': 'Netflix', 'cat': 2},
        {'pkg': 'in.startv.hotstar', 'name': 'Disney+ Hotstar', 'cat': 2},
        {'pkg': 'tv.twitch.android.app', 'name': 'Twitch', 'cat': 2},
        {'pkg': 'com.vidio.android', 'name': 'Vidio', 'cat': 2},
        {'pkg': 'com.vuclip.viu', 'name': 'Viu', 'cat': 2},
        {'pkg': 'com.tencent.qqlivei18n', 'name': 'WeTV', 'cat': 2},
        {'pkg': 'com.qiyi.video', 'name': 'iQIYI', 'cat': 2},
        {'pkg': 'com.bstar.intl', 'name': 'Bstation', 'cat': 2},
        // Web Novels & Comics
        {'pkg': 'wp.wattpad', 'name': 'Wattpad', 'cat': -1},
        {'pkg': 'com.naver.linewebtoon', 'name': 'LINE WEBTOON', 'cat': -1},
        {'pkg': 'com.fizzonovel', 'name': 'Fizzo Novel', 'cat': -1},
        {'pkg': 'mobi.mangatoon.novel', 'name': 'MangaToon', 'cat': -1},
        // Social Video Editors
        {'pkg': 'com.lemon.lvoverseas', 'name': 'CapCut', 'cat': -1},
        {'pkg': 'com.camerasideas.instashot', 'name': 'InShot', 'cat': -1},
      ];

      for (var app in nonProductiveApps) {
        expect(
          AppState.isNonProductiveApp(app['pkg'] as String, app['name'] as String, app['cat'] as int),
          isTrue,
          reason: 'Non-productive app escaped classification: ${app['name']} (${app['pkg']})',
        );
        expect(
          AppState.isProductiveApp(app['pkg'] as String, app['name'] as String, app['cat'] as int),
          isFalse,
          reason: 'Non-productive app was mistakenly marked productive: ${app['name']} (${app['pkg']})',
        );
      }
    });
  });

  group('AppState Auto-Ejection and Syncing', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        // Simulate productive apps that were previously mistakenly blocked, along with actual non-productive ones
        'blockedApps': [
          'com.spotify.music',
          'com.soundcloud.android',
          'com.maxmpz.audioplayer',
          'com.sec.android.app.music',
          'org.telegram.messenger', // Productive (should be ejected)
          'us.zoom.videomeetings', // Productive (should be ejected)
          'com.zhiliaoapp.musically', // TikTok (must stay blocked)
          'com.instagram.android', // Instagram (must stay blocked)
          'com.mobile.legends', // Game (must stay blocked)
        ],
      });
      prefs = await SharedPreferences.getInstance();

      // Mock MethodChannels
      const channelBlock = MethodChannel('com.muslimlauncher/block');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelBlock, (call) async => true);

      const channelApps = MethodChannel('com.muslimlauncher/apps');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channelApps, (call) async => true);
    });

    test('Ejects all productive apps and keeps non-productive apps locked upon syncAppsWithCategories', () async {
      final appState = AppState(prefs);

      // Verify startup sanitization immediately unblocks productive apps
      expect(appState.isAppBlocked('com.spotify.music'), isFalse);
      expect(appState.isAppBlocked('com.soundcloud.android'), isFalse);
      expect(appState.isAppBlocked('com.maxmpz.audioplayer'), isFalse);
      expect(appState.isAppBlocked('com.sec.android.app.music'), isFalse);
      expect(appState.isAppBlocked('org.telegram.messenger'), isFalse);
      expect(appState.isAppBlocked('us.zoom.videomeetings'), isFalse);

      // Non-productive apps must remain blocked
      expect(appState.isAppBlocked('com.zhiliaoapp.musically'), isTrue);
      expect(appState.isAppBlocked('com.instagram.android'), isTrue);
      expect(appState.isAppBlocked('com.mobile.legends'), isTrue);

      // Full app sync simulation with mix of productive and non-productive apps
      final installedApps = [
        // Productive Apps (Must NOT be blocked)
        {'packageName': 'com.whatsapp', 'appName': 'WhatsApp', 'category': 4},
        {'packageName': 'org.telegram.messenger', 'appName': 'Telegram', 'category': 4},
        {'packageName': 'us.zoom.videomeetings', 'appName': 'Zoom', 'category': -1},
        {'packageName': 'com.google.android.apps.tachyon', 'appName': 'Google Meet', 'category': -1},
        {'packageName': 'com.google.android.apps.maps', 'appName': 'Google Maps', 'category': 6},
        {'packageName': 'com.gojek.app', 'appName': 'Gojek', 'category': -1},
        {'packageName': 'com.bca', 'appName': 'BCA mobile', 'category': -1},
        {'packageName': 'com.al.quran.indonesia', 'appName': 'Al Quran Indonesia', 'category': -1},
        {'packageName': 'com.spotify.music', 'appName': 'Spotify', 'category': 1},
        {'packageName': 'in.krosbits.musicolet', 'appName': 'Musicolet', 'category': 1},
        {'packageName': 'com.aimp.player', 'appName': 'AIMP', 'category': 1},
        {'packageName': 'com.custom.player', 'appName': 'Pemutar Musik Offline', 'category': -1},
        // Non-Productive Apps (MUST be blocked)
        {'packageName': 'com.zhiliaoapp.musically', 'appName': 'TikTok', 'category': 4},
        {'packageName': 'com.instagram.android', 'appName': 'Instagram', 'category': 4},
        {'packageName': 'com.facebook.katana', 'appName': 'Facebook', 'category': 4},
        {'packageName': 'com.twitter.android', 'appName': 'X', 'category': 4},
        {'packageName': 'com.google.android.youtube', 'appName': 'YouTube', 'category': 2},
        {'packageName': 'com.netflix.mediaclient', 'appName': 'Netflix', 'category': 2},
        {'packageName': 'com.mobile.legends', 'appName': 'Mobile Legends', 'category': 0},
        {'packageName': 'com.dts.freefireth', 'appName': 'Free Fire', 'category': 0},
        {'packageName': 'com.roblox.client', 'appName': 'Roblox', 'category': -1},
        {'pkg': 'com.neptune.domino', 'appName': 'Higgs Domino', 'packageName': 'com.neptune.domino', 'category': -1},
        {'packageName': 'wp.wattpad', 'appName': 'Wattpad', 'category': -1},
        {'packageName': 'com.lemon.lvoverseas', 'appName': 'CapCut', 'category': -1},
      ];

      await appState.syncAppsWithCategories(installedApps);

      // Verify all productive apps are unlocked
      expect(appState.isAppBlocked('com.whatsapp'), isFalse);
      expect(appState.isAppBlocked('org.telegram.messenger'), isFalse);
      expect(appState.isAppBlocked('us.zoom.videomeetings'), isFalse);
      expect(appState.isAppBlocked('com.google.android.apps.tachyon'), isFalse);
      expect(appState.isAppBlocked('com.google.android.apps.maps'), isFalse);
      expect(appState.isAppBlocked('com.gojek.app'), isFalse);
      expect(appState.isAppBlocked('com.bca'), isFalse);
      expect(appState.isAppBlocked('com.al.quran.indonesia'), isFalse);
      expect(appState.isAppBlocked('com.spotify.music'), isFalse);
      expect(appState.isAppBlocked('in.krosbits.musicolet'), isFalse);
      expect(appState.isAppBlocked('com.aimp.player'), isFalse);
      expect(appState.isAppBlocked('com.custom.player'), isFalse);

      // Verify all non-productive apps are locked
      expect(appState.isAppBlocked('com.zhiliaoapp.musically'), isTrue);
      expect(appState.isAppBlocked('com.instagram.android'), isTrue);
      expect(appState.isAppBlocked('com.facebook.katana'), isTrue);
      expect(appState.isAppBlocked('com.twitter.android'), isTrue);
      expect(appState.isAppBlocked('com.google.android.youtube'), isTrue);
      expect(appState.isAppBlocked('com.netflix.mediaclient'), isTrue);
      expect(appState.isAppBlocked('com.mobile.legends'), isTrue);
      expect(appState.isAppBlocked('com.dts.freefireth'), isTrue);
      expect(appState.isAppBlocked('com.roblox.client'), isTrue);
      expect(appState.isAppBlocked('com.neptune.domino'), isTrue);
      expect(appState.isAppBlocked('wp.wattpad'), isTrue);
      expect(appState.isAppBlocked('com.lemon.lvoverseas'), isTrue);

      // Verify manual lock is strictly blocked for productive apps
      await appState.toggleAppBlockedStatus('com.whatsapp', appName: 'WhatsApp');
      expect(appState.isAppBlocked('com.whatsapp'), isFalse);

      await appState.toggleAppBlockedStatus('us.zoom.videomeetings', appName: 'Zoom');
      expect(appState.isAppBlocked('us.zoom.videomeetings'), isFalse);

      await appState.toggleAppBlockedStatus('com.spotify.music', appName: 'Spotify');
      expect(appState.isAppBlocked('com.spotify.music'), isFalse);
    });
  });
}
