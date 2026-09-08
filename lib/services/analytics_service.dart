import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Central service for Google Analytics (Firebase Analytics)
/// Provides resilient tracking for:
/// - Screen views / Page visits
/// - Quran reading success & khatm
/// - Dzikir completions
/// - Hadith reading success
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _isInitialized = false;
  static final AnalyticsNavigatorObserver _observer = AnalyticsNavigatorObserver();

  /// Whether Firebase Analytics has been successfully initialized.
  static bool get isInitialized => _isInitialized;

  /// Underlying FirebaseAnalytics instance (null if not initialized or fallback mode).
  static FirebaseAnalytics? get analytics => _analytics;

  /// Custom NavigatorObserver to automatically track screen views.
  static AnalyticsNavigatorObserver get observer => _observer;

  /// Initialize Firebase Analytics with fail-safe error handling.
  /// If google-services.json is missing or Firebase fails to initialize,
  /// the app continues running without crashing, and events are logged to console.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      debugPrint('[AnalyticsService] ✅ Firebase Analytics initialized successfully.');
    } catch (e) {
      _isInitialized = false;
      _analytics = null;
      debugPrint(
        '[AnalyticsService] ⚠️ Firebase initialization skipped or failed: $e\n'
        '[AnalyticsService] Running in fallback mode. Events will be logged to debug console.',
      );
    }
  }

  /// Log screen/page visits
  static Future<void> logScreenView(
    String screenName, {
    String? screenClass,
  }) async {
    final sanitizedName = _sanitizeName(screenName);
    final targetClass = screenClass ?? sanitizedName;
    debugPrint('[Analytics] 📱 Screen View: $sanitizedName');

    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logScreenView(
        screenName: sanitizedName,
        screenClass: targetClass,
        parameters: {
          'page_title': sanitizedName,
          'screen_name': sanitizedName,
        },
      );
      // Keep engagement and background events tagged with the active screen and page_title
      await _analytics!.setDefaultEventParameters({
        'screen_name': sanitizedName,
        'page_title': sanitizedName,
      });
    } catch (e) {
      debugPrint('[Analytics] Failed to log screen view: $e');
    }
  }

  /// Log successful Quran ayah reading
  static Future<void> logQuranSuccess({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    int pointsEarned = 0,
    String method = 'voice',
    bool isSequential = true,
    int durationSeconds = 0,
  }) async {
    final surahAyah = '$surahName: $ayahNumber';
    final durStr = durationSeconds > 0 ? ' (durasi: ${durationSeconds}s)' : '';
    debugPrint(
      '[Analytics] 📖 Quran Reading Success: QS. $surahName Ayat $ayahNumber (Surah #$surahNumber)$durStr '
      '(+$pointsEarned pts, method: $method, sequential: $isSequential)',
    );

    if (!_isInitialized || _analytics == null) return;
    try {
      final params = <String, Object>{
        'surah_number': surahNumber,
        'surah_name': surahName,
        'ayah_number': ayahNumber,
        'surah_ayah': surahAyah,
        'points_earned': pointsEarned,
        'verification_method': method,
        'is_sequential': isSequential ? 1 : 0,
      };
      if (durationSeconds > 0) {
        params['duration_seconds'] = durationSeconds;
      }

      await _analytics!.logEvent(
        name: 'quran_reading_success',
        parameters: params,
      );
    } catch (e) {
      debugPrint('[Analytics] Failed to log quran_reading_success: $e');
    }
  }

  /// Log Quran full khatm achievement
  static Future<void> logQuranKhatm({required int khatmCount}) async {
    debugPrint('[Analytics] 🏆 Quran Khatm Achieved! Total khatm: $khatmCount');

    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: 'quran_khatm_achieved',
        parameters: {
          'khatm_count': khatmCount,
        },
      );
    } catch (e) {
      debugPrint('[Analytics] Failed to log quran_khatm_achieved: $e');
    }
  }

  /// Log completion of a dzikir round
  static Future<void> logDzikirCompleted({
    required String dzikirTitle,
    String? dzikirTransliteration,
    String? dzikirArabic,
    required int targetCount,
    int pointsEarned = 0,
    int durationSeconds = 0,
  }) async {
    final detailStr = dzikirTransliteration != null ? ' ($dzikirTransliteration)' : '';
    final durStr = durationSeconds > 0 ? ' (durasi: ${durationSeconds}s)' : '';
    debugPrint(
      '[Analytics] 📿 Dzikir Completed: "$dzikirTitle"$detailStr$durStr '
      '(target: $targetCount, +$pointsEarned pts)',
    );

    if (!_isInitialized || _analytics == null) return;
    try {
      final params = <String, Object>{
        'dzikir_title': dzikirTitle,
        'target_count': targetCount,
        'points_earned': pointsEarned,
      };
      if (dzikirTransliteration != null && dzikirTransliteration.isNotEmpty) {
        params['dzikir_transliteration'] = dzikirTransliteration;
      }
      if (dzikirArabic != null && dzikirArabic.isNotEmpty) {
        params['dzikir_arabic'] = dzikirArabic;
      }
      if (durationSeconds > 0) {
        params['duration_seconds'] = durationSeconds;
      }

      await _analytics!.logEvent(
        name: 'dzikir_completed',
        parameters: params,
      );
    } catch (e) {
      debugPrint('[Analytics] Failed to log dzikir_completed: $e');
    }
  }

  /// Log completion/reading of a Hadith
  static Future<void> logHadithSuccess({
    required int hadithId,
    required String hadithTitle,
    int pointsEarned = 0,
    bool isFirstTime = true,
    int durationSeconds = 0,
  }) async {
    final durStr = durationSeconds > 0 ? ' (durasi: ${durationSeconds}s)' : '';
    debugPrint(
      '[Analytics] 📜 Hadith Reading Success: #$hadithId "$hadithTitle"$durStr '
      '(+$pointsEarned pts, firstTime: $isFirstTime)',
    );

    if (!_isInitialized || _analytics == null) return;
    try {
      final params = <String, Object>{
        'hadith_id': hadithId,
        'hadith_title': hadithTitle,
        'points_earned': pointsEarned,
        'is_first_time': isFirstTime ? 1 : 0,
      };
      if (durationSeconds > 0) {
        params['duration_seconds'] = durationSeconds;
      }

      await _analytics!.logEvent(
        name: 'hadith_reading_success',
        parameters: params,
      );
    } catch (e) {
      debugPrint('[Analytics] Failed to log hadith_reading_success: $e');
    }
  }

  /// General custom event logging helper
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final sanitizedEvent = _sanitizeName(name);
    debugPrint('[Analytics] ⚡ Event: $sanitizedEvent, params: $parameters');

    if (!_isInitialized || _analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: sanitizedEvent,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('[Analytics] Failed to log event $sanitizedEvent: $e');
    }
  }

  /// Sanitize names to match Firebase Analytics guidelines (up to 40 chars, alphanumeric & underscores)
  static String _sanitizeName(String raw) {
    if (raw == '/' || raw.isEmpty) return 'HomeScreen';
    var cleaned = raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty) cleaned = 'HomeScreen';
    if (cleaned.length > 40) {
      cleaned = cleaned.substring(0, 40);
    }
    return cleaned;
  }
}

/// Custom NavigatorObserver that intercepts navigation and logs screen views.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  void _sendScreenView(Route<dynamic>? route) {
    if (route == null) return;
    var screenName = route.settings.name;
    if (screenName == null || screenName.isEmpty) return;
    if (screenName == '/') {
      screenName = 'HomeScreen';
    }
    AnalyticsService.logScreenView(screenName);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _sendScreenView(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _sendScreenView(previousRoute);
  }
}
