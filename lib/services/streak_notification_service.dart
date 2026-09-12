import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../providers/app_state.dart';
import '../screens/home/achievements_screen.dart';
import '../screens/dzikir/dzikir_screen.dart';
import '../screens/quran/surah_list_screen.dart';
import '../utils/page_transitions.dart';

class StreakNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int streakNotificationId = 1001;
  static const String channelId = 'muslim_launcher_streak_reminders';
  static const String channelName = 'Pengingat Istiqomah Harian';
  static const String channelDescription =
      'Pengingat harian tilawah Al-Qur\'an dan zikir agar streak tidak terputus';

  static bool _isInitialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Inisialisasi plugin notifikasi dan setup channel
  static Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;
    _navigatorKey = navigatorKey;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onNotificationResponse,
      );

      // Setup Android Notification Channel dengan prioritas tinggi
      final androidNotificationPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidNotificationPlugin != null) {
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidNotificationPlugin.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint('[StreakNotificationService] Initialized successfully');
    } catch (e) {
      debugPrint('[StreakNotificationService] Initialization error: $e');
    }
  }

  /// Meminta izin notifikasi (Android 13+ / iOS)
  static Future<bool> requestPermission() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[StreakNotificationService] Request permission error: $e');
    }
    return false;
  }

  /// Menangani aksi ketukan pada notifikasi
  static void onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('[StreakNotificationService] Notification tapped with payload: $payload');
    handlePayloadNavigation(payload);
  }

  /// Navigasi ke layar sesuai payload notifikasi
  static void handlePayloadNavigation(String? payload) {
    final navState = _navigatorKey?.currentState;
    if (navState == null) return;

    if (payload == 'quran') {
      navState.push(AppPageRoute(child: const SurahListScreen()));
    } else if (payload == 'dzikir') {
      navState.push(AppPageRoute(child: const DzikirScreen()));
    } else {
      // Default / keduanya belum: arahkan ke halaman Pencapaian & Lencana
      navState.push(AppPageRoute(child: const AchievementsScreen()));
    }
  }

  /// Konten judul dan pesan pengingat berdasarkan status Tilawah & Zikir
  static Map<String, String> getReminderContent({
    required bool hasQuranToday,
    required bool hasDzikirToday,
    String lang = 'id',
  }) {
    final isEn = lang == 'en';
    final isAr = lang == 'ar';

    if (!hasQuranToday && !hasDzikirToday) {
      return {
        'title': isAr
            ? 'حافظ على استقامتك اليومية! 🔥✨'
            : (isEn ? 'Keep Your Daily Streak Alive! 🔥✨' : 'Jaga Istiqomah Harianmu! 🔥✨'),
        'body': isAr
            ? 'بضع ساعات متبقية قبل نهاية اليوم. اقرأ آية واحدة واذكر الله للمحافظة على الورد!'
            : (isEn
                ? 'A few hours left before today ends. Read 1 ayah and complete 1 round of dhikr to keep your streak!'
                : 'Tinggal beberapa jam sebelum hari berganti. Yuk baca 1 ayat dan zikir 33x agar streak-mu tetap menyala!'),
        'payload': 'streak',
      };
    } else if (!hasQuranToday) {
      return {
        'title': isAr
            ? 'حان وقت التلاوة اليومية! 🔥'
            : (isEn ? 'Time for Daily Tilawah! 🔥' : 'Waktunya Tilawah Hari Ini! 🔥'),
        'body': isAr
            ? 'استمر في وردك القرآني! اقرأ آية واحدة على الأقل قبل نهاية اليوم.'
            : (isEn
                ? 'Your reading streak is active! Take 1 minute to read at least 1 ayah today.'
                : 'Streak tilawahmu sedang berjalan! Yuk luangkan 1 menit membaca minimal 1 ayat hari ini.'),
        'payload': 'quran',
      };
    } else if (!hasDzikirToday) {
      return {
        'title': isAr
            ? 'حان وقت الذكر اليومي! ✨'
            : (isEn ? 'Time for Daily Dhikr! ✨' : 'Sempatkan Zikir Hari Ini! ✨'),
        'body': isAr
            ? 'أكمل جولة تسبيح واحدة (33 مرة) للمحافظة على استقامة لسانك بذكر الله.'
            : (isEn
                ? 'Complete at least 1 round (33x) of tasbih dhikr to keep your daily streak.'
                : 'Yuk tuntaskan minimal 1 putaran (33x) zikir tasbih agar streak zikirmu tidak terputus.'),
        'payload': 'dzikir',
      };
    }

    return {
      'title': '',
      'body': '',
      'payload': '',
    };
  }

  /// Menjadwalkan pengingat harian jam 20:00 (atau jam yang ditentukan)
  static Future<void> scheduleDailyStreakReminder({
    required bool hasQuranToday,
    required bool hasDzikirToday,
    String lang = 'id',
    int hour = 20,
    int minute = 0,
  }) async {
    if (!_isInitialized) return;
    try {
      // Jika keduanya sudah selesai hari ini, batalkan notifikasi hari ini
      if (hasQuranToday && hasDzikirToday) {
        await cancelReminder();
        debugPrint('[StreakNotificationService] All streaks completed today. Reminder cancelled.');
        return;
      }

      final content = getReminderContent(
        hasQuranToday: hasQuranToday,
        hasDzikirToday: hasDzikirToday,
        lang: lang,
      );

      if (content['title']!.isEmpty) return;

      final scheduledTime = _nextInstanceOfTime(hour, minute);

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        color: Color(0xFFEA580C), // Orange hangat
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: streakNotificationId,
        title: content['title'],
        body: content['body'],
        scheduledDate: scheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: content['payload'],
      );

      debugPrint(
        '[StreakNotificationService] Scheduled daily reminder at ${scheduledTime.toString()} with payload: ${content["payload"]}',
      );
    } catch (e) {
      debugPrint('[StreakNotificationService] scheduleDailyStreakReminder error: $e');
    }
  }

  /// Menghitung jadwal waktu berikutnya
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika waktu hari ini sudah lewat, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Batalkan notifikasi pengingat hari ini
  static Future<void> cancelReminder() async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(id: streakNotificationId);
    } catch (e) {
      debugPrint('[StreakNotificationService] Cancel reminder error: $e');
    }
  }

  /// Tampilkan notifikasi pengingat instan untuk testing / reminder saat membuka app
  static Future<void> showInstantReminder({
    required bool hasQuranToday,
    required bool hasDzikirToday,
    String lang = 'id',
  }) async {
    if (!_isInitialized) return;
    try {
      if (hasQuranToday && hasDzikirToday) return;

      final content = getReminderContent(
        hasQuranToday: hasQuranToday,
        hasDzikirToday: hasDzikirToday,
        lang: lang,
      );

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        color: Color(0xFFEA580C),
        styleInformation: BigTextStyleInformation(''),
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id: streakNotificationId,
        title: content['title'],
        body: content['body'],
        notificationDetails: notificationDetails,
        payload: content['payload'],
      );
    } catch (e) {
      debugPrint('[StreakNotificationService] showInstantReminder error: $e');
    }
  }

  /// Sinkronisasi otomatis berdasarkan state terkini
  static Future<void> checkAndSyncReminder(AppState appState) async {
    try {
      if (!appState.isStreakReminderEnabled) {
        await cancelReminder();
        return;
      }

      await scheduleDailyStreakReminder(
        hasQuranToday: appState.hasReadQuranToday,
        hasDzikirToday: appState.hasDzikirToday,
        lang: appState.languageCode,
        hour: appState.streakReminderHour,
        minute: appState.streakReminderMinute,
      );
    } catch (e) {
      debugPrint('[StreakNotificationService] checkAndSyncReminder error: $e');
    }
  }
}
