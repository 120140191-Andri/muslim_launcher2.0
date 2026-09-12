import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_block_service.dart';
import '../services/analytics_service.dart';
import '../services/streak_notification_service.dart';
import '../screens/home/app_list_screen.dart';
import '../utils/translations.dart';
import '../utils/quran_progress_helper.dart';

class SpiritualEnergySession {
  final double previousProgress;
  final double targetProgress;
  final int durationSeconds;
  final String source; // 'quran' or 'dzikir'
  final int itemsCount;

  const SpiritualEnergySession({
    required this.previousProgress,
    required this.targetProgress,
    required this.durationSeconds,
    required this.source,
    required this.itemsCount,
  });
}

class AppState extends ChangeNotifier {
  static final RouteObserver<ModalRoute<void>> routeObserver =
      RouteObserver<ModalRoute<void>>();

  final SharedPreferences prefs;

  SpiritualEnergySession? _pendingEnergySession;
  SpiritualEnergySession? get pendingEnergySession => _pendingEnergySession;

  SpiritualEnergySession? consumePendingEnergySession() {
    final session = _pendingEnergySession;
    _pendingEnergySession = null;
    return session;
  }

  void triggerSpiritualEnergy({
    required double previousProgress,
    required double targetProgress,
    required String source,
    required int itemsCount,
  }) {
    if (itemsCount <= 0) return;
    // Minimum 15 seconds, up to 60 seconds (1 minute)
    final int extraSeconds = source == 'quran'
        ? (itemsCount * 4)
        : (itemsCount ~/ 3);
    final int durationSeconds = (15 + extraSeconds).clamp(15, 60);

    _pendingEnergySession = SpiritualEnergySession(
      previousProgress: previousProgress.clamp(0.0, 1.0),
      targetProgress: targetProgress.clamp(0.0, 1.0),
      durationSeconds: durationSeconds,
      source: source,
      itemsCount: itemsCount,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  AppState(this.prefs) {
    _init();
  }

  static String getDefaultLanguageCode() {
    try {
      final sysLang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      const supported = ['id', 'ms', 'af', 'sw', 'ar', 'en'];
      if (supported.contains(sysLang)) {
        return sysLang;
      }
    } catch (_) {}
    return 'en'; // Default to English for any language outside id, ms, af, sw, ar, en
  }

  String _languageCode = getDefaultLanguageCode();
  bool _hasSelectedLanguage = false;
  bool _hasCompletedOnboarding = false;
  int _points = 0;
  Set<String> _blockedApps = {};
  static Set<String> _customProductiveApps = {};
  Set<String> get customProductiveApps => _customProductiveApps;
  static Set<String> _userNonProductiveApps = {};
  Set<String> get userNonProductiveApps => _userNonProductiveApps;
  int _highestSurahIndex = 0;
  int _highestAyahIndex = -1; // -1 means no progress yet
  int _khatmCount = 0;
  List<Map<String, dynamic>> _readingHistory = [];
  Map<String, int> _unlockedExpirations = {};
  String? _lastAttemptedBlockedPackage;
  String? _lastAttemptedGhadhulBasharPackage;
  bool _isAccessibilityEnabled = false;
  bool _isDefaultLauncher = false;
  bool _hasSeenAccessibilitySetup = false;
  bool _hasRequestedNotificationPermission = false;
  bool _hasAcknowledgedAutostart = false;
  String _manufacturer = '';
  String _deviceModel = '';
  bool _ignorePermissionGuard = false;
  final AppBlockService _appBlockService = AppBlockService();
  Timer? _statusTimer;
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Gamification & Progression Fields
  String _userName = '';
  Set<int> _completedSurahsThisCycle = {};
  int _dailyDzikirRounds = 0;
  int _dailyDzikirPoints = 0;
  int _dailyDzikirCount = 0;
  String _dailyDzikirDate = '';
  int _totalDzikirCount = 0;

  String get userName => _userName;
  Set<int> get completedSurahsThisCycle => _completedSurahsThisCycle;
  int get dailyDzikirRounds => _dailyDzikirRounds;
  int get dailyDzikirPoints => _dailyDzikirPoints;
  int get dailyDzikirCount {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_dailyDzikirDate != today) return 0;
    return _dailyDzikirCount;
  }
  int get totalDzikirCount => _totalDzikirCount;
  bool isSurahCompletedInThisCycle(int surahNumber) =>
      _completedSurahsThisCycle.contains(surahNumber);

  String _lastReadAyat = '';
  String _lastReadSurah = '';
  int _lastReadAyahNumber = 0;
  List<dynamic> _quranData = [];
  bool _isDataLoaded = false;
  bool _isInitialized = false;

  // Persistent Quran Daily Reading Streak
  int _quranDailyStreak = 0;
  int _maxQuranDailyStreak = 0;
  String _lastQuranReadDate = '';

  // Persistent Dzikir Daily Streak
  int _dzikirDailyStreak = 0;
  int _maxDzikirDailyStreak = 0;
  String _lastDzikirDate = '';

  // Persistent Daily Focus / Screen Time Discipline Streak (<= 50 pts/day)
  int _disciplineDailyStreak = 0;
  int _maxDisciplineDailyStreak = 0;
  String _lastDisciplineDate = '';
  int _dailyPointsSpent = 0;
  String _dailyPointsSpentDate = '';

  // Persistent Streak Notification Settings
  bool _isStreakReminderEnabled = true;
  int _streakReminderHour = 20;
  int _streakReminderMinute = 0;

  // Persistent Claimed Achievement Badges
  Set<String> _claimedBadgeIds = {};

  // Persistent Daily Verse & Hadith
  String _dailySurahName = '';
  int _dailyAyahNumber = 0;
  String _dailyAyahTextEn = '';
  String _dailyAyahTextId = '';
  String _dailyVerseDate = '';

  List<dynamic> _hadithData = [];
  Map<String, dynamic>? _dailyHadith;
  String _dailyHadithDate = '';
  Set<int> _readHadithIds = {};
  List<dynamic> _cachedShuffledHadithData = [];
  String _cachedHadithShuffleDate = '';

  bool get isReady => _isDataLoaded && _isInitialized;

  @visibleForTesting
  void setReadyForTesting() {
    _isDataLoaded = true;
    _isInitialized = true;
    notifyListeners();
  }

  Set<int> get readHadithIds => _readHadithIds;
  bool isHadithRead(int id) => _readHadithIds.contains(id);
  int get totalHadithsCount => _hadithData.length;
  int get completedHadithsCount => _readHadithIds.length;


  String get languageCode => _languageCode;
  bool get isIndonesian => isIndonesianUser(_languageCode);
  String get supportUrl => getSupportUrl(_languageCode);
  String get supportButtonText => getSupportButtonText(_languageCode);
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get points => _points;
  Set<String> get blockedApps => _blockedApps;
  String get lastReadAyat => _lastReadAyat;
  String get lastReadSurah => _lastReadSurah;
  int get lastReadAyahNumber => _lastReadAyahNumber;
  int get quranDailyStreak {
    if (_lastQuranReadDate.isEmpty) return 0;
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    if (_lastQuranReadDate == today) return _quranDailyStreak;
    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    if (_lastQuranReadDate == yesterday) return _quranDailyStreak;
    return 0;
  }
  int get rawQuranDailyStreak => _quranDailyStreak;
  int get maxQuranDailyStreak => _maxQuranDailyStreak;
  String get lastQuranReadDate => _lastQuranReadDate;

  int get dzikirDailyStreak {
    if (_lastDzikirDate.isEmpty) return 0;
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    if (_lastDzikirDate == today) return _dzikirDailyStreak;
    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    if (_lastDzikirDate == yesterday) return _dzikirDailyStreak;
    return 0;
  }
  int get rawDzikirDailyStreak => _dzikirDailyStreak;
  int get maxDzikirDailyStreak => _maxDzikirDailyStreak;
  String get lastDzikirDate => _lastDzikirDate;

  int get disciplineDailyStreak {
    _checkDailyDiscipline();
    return _disciplineDailyStreak;
  }
  int get rawDisciplineDailyStreak => _disciplineDailyStreak;
  int get maxDisciplineDailyStreak {
    _checkDailyDiscipline();
    return _maxDisciplineDailyStreak;
  }
  int get dailyPointsSpent {
    _checkDailyDiscipline();
    return _dailyPointsSpent;
  }

  bool get hasReadQuranToday {
    if (_lastQuranReadDate.isEmpty) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _lastQuranReadDate == today;
  }

  bool get hasDzikirToday {
    if (_lastDzikirDate.isEmpty) return false;
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _lastDzikirDate == today;
  }

  bool get isStreakReminderEnabled => _isStreakReminderEnabled;
  int get streakReminderHour => _streakReminderHour;
  int get streakReminderMinute => _streakReminderMinute;

  Future<void> setStreakReminderEnabled(bool enabled) async {
    _isStreakReminderEnabled = enabled;
    await prefs.setBool('isStreakReminderEnabled', enabled);
    notifyListeners();
    unawaited(StreakNotificationService.checkAndSyncReminder(this));
  }

  Future<void> setStreakReminderTime(int hour, int minute) async {
    _streakReminderHour = hour;
    _streakReminderMinute = minute;
    await prefs.setInt('streakReminderHour', hour);
    await prefs.setInt('streakReminderMinute', minute);
    notifyListeners();
    unawaited(StreakNotificationService.checkAndSyncReminder(this));
  }

  Set<String> get claimedBadgeIds => _claimedBadgeIds;
  bool isBadgeClaimed(String badgeId) => _claimedBadgeIds.contains(badgeId);
  List<dynamic> get quranData => _quranData;
  bool get isDataLoaded => _isDataLoaded;
  List<dynamic> get hadithData {
    if (_hadithData.isEmpty) return const [];
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_cachedShuffledHadithData.isNotEmpty && _cachedHadithShuffleDate == today) {
      return _cachedShuffledHadithData;
    }
    final seed = today.hashCode;
    final list = List<dynamic>.from(_hadithData);
    list.shuffle(Random(seed));
    _cachedShuffledHadithData = list;
    _cachedHadithShuffleDate = today;
    return _cachedShuffledHadithData;
  }
  int get khatmCount => _khatmCount;
  double get maqamBoostMultiplier => QuranProgressHelper.getMaqamBoostMultiplier(_khatmCount);
  int get maqamBoostPercent => QuranProgressHelper.getMaqamBoostPercent(_khatmCount);
  int get maqamLevel => QuranProgressHelper.getMaqamLevel(_khatmCount);
  List<Map<String, dynamic>> get readingHistory => _readingHistory;
  String? get lastAttemptedBlockedPackage => _lastAttemptedBlockedPackage;
  String? get lastAttemptedGhadhulBasharPackage => _lastAttemptedGhadhulBasharPackage;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isDefaultLauncher => _isDefaultLauncher;
  bool get hasSeenAccessibilitySetup => _hasSeenAccessibilitySetup;
  bool get hasRequestedNotificationPermission => _hasRequestedNotificationPermission;
  bool get hasAcknowledgedAutostart => _hasAcknowledgedAutostart;
  String get manufacturer => _manufacturer;
  String get deviceModel => _deviceModel;
  bool get ignorePermissionGuard => _ignorePermissionGuard;
  AppBlockService get appBlockService => _appBlockService;

  // Daily Verse Getters
  String get dailySurahName => _dailySurahName;
  int get dailyAyahNumber => _dailyAyahNumber;
  String get dailyAyahTextEn => _dailyAyahTextEn;
  String get dailyAyahTextId => _dailyAyahTextId;
  String get dailyVerseDate => _dailyVerseDate;

  // Daily Hadith Getters & Helpers
  Map<String, dynamic>? get dailyHadith => _dailyHadith;
  String get dailyHadithArabic => _dailyHadith?['arabic'] as String? ?? '';
  String get dailyHadithDate => _dailyHadithDate;

  String getDailyHadithText(String lang) {
    if (_dailyHadith == null) {
      return Translations.get(lang, 'daily_inspiration_default');
    }
    final translations = _dailyHadith!['translations'] as Map<String, dynamic>?;
    if (translations == null) return _dailyHadith!['arabic'] as String? ?? '';
    return translations[lang] as String? ??
        translations['en'] as String? ??
        translations['id'] as String? ??
        _dailyHadith!['arabic'] as String? ??
        '';
  }

  String getDailyHadithNarrator(String lang) {
    if (_dailyHadith == null) return '';
    final narrators = _dailyHadith!['narrators'] as Map<String, dynamic>?;
    if (narrators == null) return '';
    return narrators[lang] as String? ??
        narrators['en'] as String? ??
        narrators['id'] as String? ??
        '';
  }

  void _init() async {
    try {
    _languageCode = prefs.getString('languageCode') ?? getDefaultLanguageCode();
    _hasSelectedLanguage = prefs.getBool('hasSelectedLanguage') ?? false;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _points = prefs.getInt('points') ?? 0;
    if (_points < 0) {
      _points = 0;
      await prefs.setInt('points', 0);
    }
    final savedUserNonProductive = prefs.getStringList('userNonProductiveApps') ?? [];
    _userNonProductiveApps = savedUserNonProductive.map((e) => e.trim().toLowerCase()).toSet();
    final savedCustom = prefs.getStringList('customProductiveApps') ?? [];
    _customProductiveApps = savedCustom.map((e) => e.trim().toLowerCase()).toSet();
    final savedBlocked = prefs.getStringList('blockedApps') ?? [];
    _blockedApps = savedBlocked
        .where((pkg) => !isProductiveApp(pkg, ''))
        .toSet();
    if (_blockedApps.length != savedBlocked.length) {
      prefs.setStringList('blockedApps', _blockedApps.toList());
    }
    _lastReadAyat = prefs.getString('lastReadAyat') ?? '';
    _lastReadSurah = prefs.getString('lastReadSurah') ?? '';
    _lastReadAyahNumber = prefs.getInt('lastReadAyahNumber') ?? 0;
    _hasSeenAccessibilitySetup = prefs.getBool('hasSeenAccessibilitySetup') ?? false;
    _hasRequestedNotificationPermission = prefs.getBool('hasRequestedNotificationPermission') ?? false;
    _hasAcknowledgedAutostart = prefs.getBool('hasAcknowledgedAutostart') ?? false;
    
    _highestSurahIndex = prefs.getInt('highestSurahIndex') ?? 0;
    _highestAyahIndex = prefs.getInt('highestAyahIndex') ?? -1;
    _khatmCount = prefs.getInt('khatmCount') ?? 0;

    _quranDailyStreak = prefs.getInt('quranDailyStreak') ?? 0;
    _maxQuranDailyStreak = prefs.getInt('maxQuranDailyStreak') ?? _quranDailyStreak;
    _lastQuranReadDate = prefs.getString('lastQuranReadDate') ?? '';

    _dzikirDailyStreak = prefs.getInt('dzikirDailyStreak') ?? 0;
    _maxDzikirDailyStreak = prefs.getInt('maxDzikirDailyStreak') ?? _dzikirDailyStreak;
    _lastDzikirDate = prefs.getString('lastDzikirDate') ?? '';

    _isStreakReminderEnabled = prefs.getBool('isStreakReminderEnabled') ?? true;
    _streakReminderHour = prefs.getInt('streakReminderHour') ?? 20;
    _streakReminderMinute = prefs.getInt('streakReminderMinute') ?? 0;

    _disciplineDailyStreak = prefs.getInt('disciplineDailyStreak') ?? 0;
    _maxDisciplineDailyStreak = prefs.getInt('maxDisciplineDailyStreak') ?? _disciplineDailyStreak;
    _lastDisciplineDate = prefs.getString('lastDisciplineDate') ?? '';
    _dailyPointsSpent = prefs.getInt('dailyPointsSpent') ?? 0;
    _dailyPointsSpentDate = prefs.getString('dailyPointsSpentDate') ?? '';
    _checkDailyDiscipline();

    final savedClaimedBadges = prefs.getStringList('claimedBadgeIds') ?? [];
    _claimedBadgeIds = savedClaimedBadges.toSet();

    _userName = prefs.getString('userName') ?? '';
    final savedCompletedSurahs = prefs.getStringList('completedSurahsThisCycle') ?? [];
    _completedSurahsThisCycle = savedCompletedSurahs.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();

    final today = DateTime.now().toIso8601String().split('T')[0];
    _dailyDzikirDate = prefs.getString('dailyDzikirDate') ?? '';
    if (_dailyDzikirDate != today) {
      _dailyDzikirRounds = 0;
      _dailyDzikirPoints = 0;
      _dailyDzikirCount = 0;
      _dailyDzikirDate = today;
      prefs.setInt('dailyDzikirRounds', 0);
      prefs.setInt('dailyDzikirPoints', 0);
      prefs.setInt('dailyDzikirCount', 0);
      prefs.setString('dailyDzikirDate', today);
    } else {
      _dailyDzikirRounds = prefs.getInt('dailyDzikirRounds') ?? 0;
      _dailyDzikirPoints = prefs.getInt('dailyDzikirPoints') ?? 0;
      _dailyDzikirCount = prefs.getInt('dailyDzikirCount') ?? 0;
    }

    final lastHadithDate = prefs.getString('lastHadithDate') ?? '';
    if (lastHadithDate != today) {
      _readHadithIds = {};
      prefs.setStringList('readHadithIds', []);
      prefs.setString('lastHadithDate', today);
    } else {
      final readHadithList = prefs.getStringList('readHadithIds') ?? [];
      _readHadithIds = readHadithList.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();
    }

    final historyJson = prefs.getString('readingHistory') ?? '[]';
    try {
      final decoded = json.decode(historyJson) as List;
      _readingHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _readingHistory = [];
    }

    _totalDzikirCount = prefs.getInt('totalDzikirCount') ?? 0;
    if (_totalDzikirCount == 0 && _readingHistory.isNotEmpty) {
      for (final item in _readingHistory) {
        final title = item['title']?.toString() ?? '';
        if (title.contains('Dzikir:')) {
          final count = item['versesCount'] as int? ?? item['count'] as int? ?? 0;
          _totalDzikirCount += count;
        }
      }
      if (_totalDzikirCount > 0) {
        prefs.setInt('totalDzikirCount', _totalDzikirCount);
      }
    }
    
    final unlockedJson = prefs.getString('unlockedExpirations') ?? '{}';
    try {
      final decoded = json.decode(unlockedJson) as Map<String, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      _unlockedExpirations = {};
      bool pruned = false;
      decoded.forEach((key, value) {
        final exp = value as int;
        if (exp > now) {
          _unlockedExpirations[key] = exp;
        } else {
          pruned = true;
        }
      });
      if (pruned) {
        await prefs.setString('unlockedExpirations', json.encode(_unlockedExpirations));
      }
    } catch (e) {
      _unlockedExpirations = {};
    }

    // Initialize App Block Service immediately so no platform signals are dropped
    _appBlockService.init(
      onAppBlocked: (pkg) {
        final cleanPkg = pkg.trim().toLowerCase();
        if (cleanPkg.isNotEmpty) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Guard: if package is currently unlocked, ignore block event!
          final expiry = _unlockedExpirations[cleanPkg];
          if (expiry != null && now < expiry) {
            return;
          }
          // Guard: if recently dismissed within 3 seconds
          if (cleanPkg == _lastBlockedAppDismissedPackage && (now - _lastBlockedAppDismissedTime) < 3000) {
            return;
          }
          // Time-based guard: allow re-trigger for same package if >1.5s has passed
          // (previously exact-match guard blocked re-triggers from external launches)
          if (_lastAttemptedBlockedPackage == cleanPkg && (now - _lastBlockedEventTime) < 1500) return;
          _lastBlockedEventTime = now;

          _lastAttemptedBlockedPackage = cleanPkg;
          _lastAttemptedProhibitedPackage = null;
          _lastAttemptedGhadhulBasharPackage = null;
          notifyListeners();
        }
      },
      onGhadhulBasharTriggered: (pkg) {
        final cleanPkg = pkg.trim().toLowerCase();
        if (cleanPkg.isNotEmpty) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Guard: if recently dismissed or allowed within 4 seconds, ignore duplicate trigger
          if (cleanPkg == _lastGhadhulBasharDismissedPackage && (now - _lastGhadhulBasharDismissedTime) < 4000) {
            return;
          }
          // Time-based guard: allow re-trigger for same package if >1.5s has passed
          if (_lastAttemptedGhadhulBasharPackage == cleanPkg && (now - _lastGhadhulEventTime) < 1500) return;
          _lastGhadhulEventTime = now;

          _lastAttemptedGhadhulBasharPackage = cleanPkg;
          _lastAttemptedBlockedPackage = null;
          _lastAttemptedProhibitedPackage = null;
          notifyListeners();
        }
      },
      onProhibitedAppTriggered: (pkg) {
        final cleanPkg = pkg.trim().toLowerCase();
        if (cleanPkg.isNotEmpty) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (cleanPkg == _lastProhibitedTriggeredPackage && (now - _lastProhibitedTriggeredTime) < 2000) {
            return;
          }
          // Time-based guard: allow re-trigger for same package if >1.5s has passed
          if (_lastAttemptedProhibitedPackage == cleanPkg && (now - _lastProhibitedEventTime) < 1500) return;
          _lastProhibitedEventTime = now;

          _lastProhibitedTriggeredPackage = cleanPkg;
          _lastProhibitedTriggeredTime = now;
          _lastAttemptedProhibitedPackage = cleanPkg;
          _lastAttemptedBlockedPackage = null;
          _lastAttemptedGhadhulBasharPackage = null;
          notifyListeners();
        }
      },
    );
    _appBlockService.setBlockedApps(_blockedApps.toList());
    syncGhadhulBasharPackages();
    syncProhibitedPackages();

    const appsChannel = MethodChannel('com.muslimlauncher/apps');
    appsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onAppListChanged') {
        AppListScreen.invalidateFull();
        final rawApps = await appsChannel.invokeMethod('getApps');
        AppListScreen.preload(forceRefresh: true);
        syncAppsWithCategories(rawApps);
      } else if (call.method == 'onHomePressed') {
        final now = DateTime.now().millisecondsSinceEpoch;
        final isRecentlyTriggered = (now - _lastBlockedEventTime < 2500) ||
            (now - _lastGhadhulEventTime < 2500) ||
            (now - _lastProhibitedEventTime < 2500);
        if (hasActiveOverlay && !isRecentlyTriggered) {
          clearAllOverlays();
        } else if (!hasActiveOverlay) {
          goHome();
        }
      }
    });

    // Check if launch was triggered by cold-boot block intent
    try {
      const blockChannel = MethodChannel('com.muslimlauncher/block');
      final initialData = await blockChannel.invokeMethod('getPendingInitialBlock');
      if (initialData is Map) {
        final pendingProhibited = initialData['prohibited'] as String?;
        final pendingBlocked = initialData['blocked'] as String?;
        final pendingGhadhul = initialData['ghadhul'] as String?;
        if (pendingProhibited != null && pendingProhibited.isNotEmpty) {
          _lastAttemptedProhibitedPackage = pendingProhibited.toLowerCase();
          _lastAttemptedBlockedPackage = null;
          _lastAttemptedGhadhulBasharPackage = null;
        } else if (pendingBlocked != null && pendingBlocked.isNotEmpty) {
          final cleanBlocked = pendingBlocked.toLowerCase();
          final now = DateTime.now().millisecondsSinceEpoch;
          final expiry = _unlockedExpirations[cleanBlocked];
          if (expiry == null || now >= expiry) {
            _lastAttemptedBlockedPackage = cleanBlocked;
            _lastAttemptedProhibitedPackage = null;
            _lastAttemptedGhadhulBasharPackage = null;
          }
        } else if (pendingGhadhul != null && pendingGhadhul.isNotEmpty) {
          _lastAttemptedGhadhulBasharPackage = pendingGhadhul.toLowerCase();
          _lastAttemptedProhibitedPackage = null;
          _lastAttemptedBlockedPackage = null;
        }
      }
    } catch (_) {}

    // Await crucial initialization
    await Future.wait([
      loadQuranData(),
      loadHadithData(),
      _fetchDeviceInfo(),
      AppListScreen.initFromDisk(prefs),
    ]);

    _initDailyVerse();
    _initDailyHadith();

    // Start background app & icon preloading immediately
    AppListScreen.preload(
      onRawAppsFetched: (raw) => syncAppsWithCategories(raw),
    );

    try {
      _isAccessibilityEnabled = await _appBlockService.isAccessibilityEnabled();
      final defRes = await appsChannel.invokeMethod('isDefaultLauncher');
      _isDefaultLauncher = defRes is bool ? defRes : false;
    } catch (_) {}

    _isInitialized = true;
    _startStatusTimer();
    
    notifyListeners();
    } catch (e) {
      debugPrint("AppState init error: $e");
      // Ensure app can still show UI even if init partially fails
      _isInitialized = true;
      _isDataLoaded = _quranData.isNotEmpty;
      notifyListeners();
    }
  }

  /// Re-checks for any pending block/prohibited/ghadhul events from native.
  /// Called on app resume to catch events that were dropped while Flutter was in background.
  /// This is the last safety net: even if MethodChannel, handleIntent, and debounce all fail,
  /// this will pick up the pending event.
  Future<void> checkPendingNativeBlocks() async {
    try {
      const blockChannel = MethodChannel('com.muslimlauncher/block');
      final data = await blockChannel.invokeMethod('getPendingInitialBlock');
      if (data is Map) {
        final pendingProhibited = data['prohibited'] as String?;
        final pendingBlocked = data['blocked'] as String?;
        final pendingGhadhul = data['ghadhul'] as String?;
        bool changed = false;
        if (pendingProhibited != null && pendingProhibited.isNotEmpty) {
          _lastAttemptedProhibitedPackage = pendingProhibited.toLowerCase();
          _lastAttemptedBlockedPackage = null;
          _lastAttemptedGhadhulBasharPackage = null;
          changed = true;
        } else if (pendingBlocked != null && pendingBlocked.isNotEmpty) {
          final cleanBlocked = pendingBlocked.toLowerCase();
          final now = DateTime.now().millisecondsSinceEpoch;
          final expiry = _unlockedExpirations[cleanBlocked];
          if (expiry == null || now >= expiry) {
            _lastAttemptedBlockedPackage = cleanBlocked;
            _lastAttemptedProhibitedPackage = null;
            _lastAttemptedGhadhulBasharPackage = null;
            changed = true;
          }
        } else if (pendingGhadhul != null && pendingGhadhul.isNotEmpty) {
          _lastAttemptedGhadhulBasharPackage = pendingGhadhul.toLowerCase();
          _lastAttemptedProhibitedPackage = null;
          _lastAttemptedBlockedPackage = null;
          changed = true;
        }
        if (changed) notifyListeners();
      }
    } catch (_) {}
  }

  void refreshStatus() async {
    bool changed = false;

    // 1. Accessibility Check
    try {
      final accEnabled = await _appBlockService.isAccessibilityEnabled();
      if (accEnabled != _isAccessibilityEnabled) {
        _isAccessibilityEnabled = accEnabled;
        changed = true;
      }
    } catch (e) {
      debugPrint("Accessibility check error: $e");
    }

    // 2. Default Launcher Check
    try {
      const appsChannel = MethodChannel('com.muslimlauncher/apps');
      final bool defEnabled =
          await appsChannel.invokeMethod('isDefaultLauncher');
      if (defEnabled != _isDefaultLauncher) {
        _isDefaultLauncher = defEnabled;
        changed = true;
      }
    } catch (_) {}

    if (changed) notifyListeners();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    if (_unlockedExpirations.isEmpty) {
      _statusTimer = null;
      return;
    }
    // Adaptive timer: tick every 1 second when near expiry (<2 min), else every 5 seconds
    final now = DateTime.now().millisecondsSinceEpoch;
    int nearestExpiryMs = 999999999;
    for (final expiry in _unlockedExpirations.values) {
      final remaining = expiry - now;
      if (remaining > 0 && remaining < nearestExpiryMs) {
        nearestExpiryMs = remaining;
      }
    }
    final interval = nearestExpiryMs < 120000 ? 1 : 5; // 1s if <2min, else 5s
    _statusTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      _cleanupExpiredUnlocks();
      // Re-evaluate interval on next tick
      if (_unlockedExpirations.isNotEmpty) {
        final nowInner = DateTime.now().millisecondsSinceEpoch;
        bool anyNearExpiry = false;
        for (final exp in _unlockedExpirations.values) {
          if ((exp - nowInner) < 120000 && (exp - nowInner) > 0) {
            anyNearExpiry = true;
            break;
          }
        }
        // Switch interval if needed
        if (anyNearExpiry && interval != 1) {
          _startStatusTimer(); // Restart with 1s interval
        } else if (!anyNearExpiry && interval != 5) {
          _startStatusTimer(); // Restart with 5s interval
        }
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _fetchDeviceInfo() async {
    const appsChannel = MethodChannel('com.muslimlauncher/apps');
    try {
      final res = await appsChannel.invokeMethod('getDeviceInfo');
      if (res is Map) {
        _manufacturer = (res['manufacturer']?.toString() ?? '').toLowerCase();
        _deviceModel = (res['model']?.toString() ?? '').toLowerCase();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch device info: $e");
    }
  }

  void _cleanupExpiredUnlocks() {
    if (_unlockedExpirations.isEmpty) {
      _statusTimer?.cancel();
      _statusTimer = null;
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    bool changed = false;
    _unlockedExpirations.removeWhere((pkg, expiry) {
      if (now >= expiry) {
        changed = true;
        return true;
      }
      return false;
    });
    
    if (changed) {
      prefs.setString('unlockedExpirations', json.encode(_unlockedExpirations));
      // Re-sync blocked apps to native so expired unlocks are enforced immediately
      _appBlockService.setBlockedApps(_blockedApps.toList());
      notifyListeners();
    }
    if (_unlockedExpirations.isEmpty) {
      _statusTimer?.cancel();
      _statusTimer = null;
    }
  }

  Future<void> loadQuranData() async {
    if (_isDataLoaded) return;
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/quran.json',
      );
      _quranData = await compute(_decodeJson, jsonString);
      _isDataLoaded = true;
      notifyListeners();
    } catch (e) {
      // Error loading central Quran data
    }
  }

  void _initDailyVerse() {
    _dailySurahName = prefs.getString('dailySurahName') ?? '';
    _dailyAyahNumber = prefs.getInt('dailyAyahNumber') ?? 0;
    _dailyAyahTextEn = prefs.getString('dailyAyahTextEn') ?? '';
    _dailyAyahTextId = prefs.getString('dailyAyahTextId') ?? '';
    _dailyVerseDate = prefs.getString('dailyVerseDate') ?? '';

    _checkDailyVerse();
  }

  void _checkDailyVerse() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_dailyVerseDate != today || _dailySurahName.isEmpty) {
      _updateDailyVerse(today);
    }
  }

  Future<void> _updateDailyVerse(String date) async {
    if (_quranData.isEmpty) return;

    try {
    // Use date hashCode for consistent random per day (won't change on restart)
    final seed = date.hashCode;
    final int surahIdx = (seed % _quranData.length).abs();
    final surah = _quranData[surahIdx];
    final ayahs = surah['ayahs'] as List;
    final int ayahIdx = ((seed ~/ _quranData.length) % ayahs.length).abs();
    final ayah = ayahs[ayahIdx];

    _dailySurahName = surah['surah_name'] as String;
    _dailyAyahNumber = ayah['ayah_number'] as int;
    _dailyAyahTextEn = ayah['translation_en'] as String? ?? '';
    _dailyAyahTextId = ayah['translation_id'] as String? ?? '';
    _dailyVerseDate = date;

    await prefs.setString('dailySurahName', _dailySurahName);
    await prefs.setInt('dailyAyahNumber', _dailyAyahNumber);
    await prefs.setString('dailyAyahTextEn', _dailyAyahTextEn);
    await prefs.setString('dailyAyahTextId', _dailyAyahTextId);
    await prefs.setString('dailyVerseDate', _dailyVerseDate);

    notifyListeners();
    } catch (e) {
      debugPrint("Failed to update daily verse: $e");
    }
  }

  Future<void> loadHadithData() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/hadiths.json',
      );
      _hadithData = await compute(_decodeJson, jsonString);
      _checkDailyHadith();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load hadith data: $e");
    }
  }

  void _initDailyHadith() {
    _dailyHadithDate = prefs.getString('dailyHadithDate') ?? '';
    final cachedHadithJson = prefs.getString('dailyHadithJson') ?? '';
    if (cachedHadithJson.isNotEmpty) {
      try {
        _dailyHadith = json.decode(cachedHadithJson) as Map<String, dynamic>;
      } catch (_) {}
    }
    _checkDailyHadith();
  }

  void _checkDailyHadith() {
    if (_hadithData.isEmpty) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_dailyHadithDate != today || _dailyHadith == null) {
      _updateDailyHadith(today);
    }
  }

  Future<void> _updateDailyHadith(String date) async {
    if (_hadithData.isEmpty) return;
    try {
      final seed = date.hashCode;
      final int hadithIdx = (seed % _hadithData.length).abs();
      _dailyHadith = _hadithData[hadithIdx] as Map<String, dynamic>;
      _dailyHadithDate = date;

      await prefs.setString('dailyHadithDate', date);
      await prefs.setString('dailyHadithJson', json.encode(_dailyHadith));
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to update daily hadith: $e");
    }
  }

  static List<dynamic> _decodeJson(String source) {
    return json.decode(source) as List<dynamic>;
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    _hasSelectedLanguage = true;
    await prefs.setString('languageCode', code);
    await prefs.setBool('hasSelectedLanguage', true);
    await syncGhadhulBasharPackages();
    await syncProhibitedPackages();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    _hasSelectedLanguage = true; // Safety check
    await prefs.setBool('hasCompletedOnboarding', true);
    await prefs.setBool('hasSelectedLanguage', true); // Consistent state
    notifyListeners();
  }

  Future<void> addPoints(int amount) async {
    _points += amount;
    await prefs.setInt('points', _points);
    notifyListeners();
  }

  Future<void> setHasAcknowledgedAutostart(bool value) async {
    _hasAcknowledgedAutostart = value;
    await prefs.setBool('hasAcknowledgedAutostart', value);
    notifyListeners();
  }

  Future<bool> deductPoints(int amount) async {
    if (amount <= 0) return true;
    if (_points >= amount) {
      _points -= amount;
      if (_points < 0) _points = 0;
      await prefs.setInt('points', _points);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> toggleAppBlockedStatus(String packageName, {int? category, String? appName}) async {
    final pkg = packageName.toLowerCase().trim();
    if (isProductiveApp(pkg, appName ?? '', category ?? -1)) {
      return; // Do not allow blocking productive apps
    }
    // Strict Mode: Only allow blocking, not unblocking manually
    _customProductiveApps.remove(pkg);
    await prefs.setStringList('customProductiveApps', _customProductiveApps.toList());
    if (!_blockedApps.contains(pkg)) {
      _blockedApps.add(pkg);
      await prefs.setStringList('blockedApps', _blockedApps.toList());
      // Sync with Native Service
      await _appBlockService.setBlockedApps(_blockedApps.toList());
      notifyListeners();
    }
  }

  static bool isSystemEssentialApp(String packageName) {
    final pkg = packageName.toLowerCase().trim();
    if (pkg.isEmpty) return true;
    const essentialPackages = [
      'com.android.settings',
      'com.android.vending',
      'com.google.android.dialer',
      'com.android.dialer',
      'com.samsung.android.dialer',
      'com.google.android.packageinstaller',
      'com.android.packageinstaller',
      'com.google.android.permissioncontroller',
    ];
    if (essentialPackages.contains(pkg)) return true;
    if (pkg.contains('com.muslimlauncher') || pkg.contains('muslim_launcher')) return true;
    return false;
  }

  Future<void> markAppAsPermanentlyNonProductive(
    String packageName, {
    String? appName,
    int? category,
  }) async {
    final pkg = packageName.toLowerCase().trim();
    if (pkg.isEmpty || isSystemEssentialApp(pkg)) return;

    _userNonProductiveApps.add(pkg);
    _customProductiveApps.remove(pkg);
    _blockedApps.add(pkg);

    await prefs.setStringList('userNonProductiveApps', _userNonProductiveApps.toList());
    await prefs.setStringList('customProductiveApps', _customProductiveApps.toList());
    await prefs.setStringList('blockedApps', _blockedApps.toList());
    await _appBlockService.setBlockedApps(_blockedApps.toList());

    notifyListeners();
  }

  Future<void> markAppAsProductive(String packageName, {String? appName, int? category}) async {
    final pkg = packageName.toLowerCase().trim();
    final cat = category ?? getAppCategorySync(pkg);
    if (isStrictlyNonProductive(pkg, appName ?? '', cat)) {
      return; // Strictly non-productive apps and games can never be marked as productive
    }
    _customProductiveApps.add(pkg);
    _blockedApps.remove(pkg);
    await prefs.setStringList('customProductiveApps', _customProductiveApps.toList());
    await prefs.setStringList('blockedApps', _blockedApps.toList());
    await _appBlockService.setBlockedApps(_blockedApps.toList());
    notifyListeners();
  }

  bool _isOpeningApp = false;

  Future<void> openApp(String packageName, {bool bypassGuards = false}) async {
    if (_isOpeningApp) return;
    _isOpeningApp = true;
    try {
      final pkg = packageName.toLowerCase().trim();
      if (!bypassGuards) {
        if (isAppProhibited(pkg, getAppNameSync(pkg))) {
          setProhibitedPackage(pkg);
          return;
        }
        if (isAppBlocked(pkg)) {
          setBlockedPackage(pkg);
          return;
        }
        if (AppState.shouldShowGhadhulBasharReminder(pkg, '', _languageCode)) {
          setGhadhulBasharPackage(pkg);
          return;
        }
      }
      const appsChannel = MethodChannel('com.muslimlauncher/apps');
      try {
        await appsChannel.invokeMethod('openApp', {'packageName': pkg});
      } catch (e) {
        debugPrint("Failed to open app $pkg: $e");
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 600), () {
        _isOpeningApp = false;
      });
    }
  }

  static String cleanPackageName(String packageName) {
    if (packageName.isEmpty) return '';
    final parts = packageName.split('.');
    String candidate = parts.last;
    if ((candidate == 'android' || candidate == 'app') && parts.length > 1) {
      candidate = parts[parts.length - 2];
    }
    if (candidate.isNotEmpty) {
      return candidate[0].toUpperCase() + candidate.substring(1);
    }
    return packageName;
  }

  String getAppNameSync(String packageName) {
    final pkg = packageName.trim().toLowerCase();
    final cached = AppListScreen.cachedApps;
    if (cached != null) {
      for (final app in cached) {
        if (app.packageName.toLowerCase() == pkg) {
          final name = app.appName.trim();
          if (name.isNotEmpty) return name;
        }
      }
    }
    return cleanPackageName(packageName);
  }

  int getAppCategorySync(String packageName) {
    return getAppCategoryStatic(packageName);
  }

  static int getAppCategoryStatic(String packageName) {
    final pkg = packageName.trim().toLowerCase();
    final cached = AppListScreen.cachedApps;
    if (cached != null) {
      for (final app in cached) {
        if (app.packageName.toLowerCase() == pkg) {
          return app.category;
        }
      }
    }
    return -1;
  }

  static const Set<String> _whitelist = {
    'com.whatsapp', 'com.whatsapp.w4b', 'com.android.chrome', 
    'com.google.android.gm', 'com.android.settings', 'com.android.vending',
    'com.google.android.apps.messaging', 'com.android.mms', 'com.samsung.android.messaging',
    'com.google.android.contacts', 'com.android.contacts'
  };

  static bool isWhitelisted(String packageName) {
    return isProductiveApp(packageName, '');
  }

  /// Determines if an app is a music or audio application (both online streaming and offline players).
  /// Music apps are considered productive / permitted and must never be auto-blocked.
  static bool isMusicOrAudioApp(String packageName, String appName, [int category = -1]) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // Explicit adult apps must NEVER be considered productive under any circumstances
    if (isExplicitAdultApp(pkg, name)) {
      return false;
    }

    // 1. Definite Exclusions: Games and social video platforms
    if (category == 0) return false; // Android CATEGORY_GAME
    if (pkg.contains('musically') || pkg.contains('tiktok') || name.contains('tiktok')) {
      return false; // TikTok / Musical.ly
    }
    if (pkg == 'com.google.android.youtube' || name == 'youtube') {
      return false; // Regular YouTube (video), YouTube Music is handled specifically below
    }

    // 2. Android OS Category Audio (CATEGORY_AUDIO = 1)
    if (category == 1) return true;

    // 3. Known online streaming services (keywords in package or app name)
    const onlineMusicKeywords = [
      'spotify',
      'soundcloud',
      'deezer',
      'tidal',
      'joox',
      'resso',
      'pandora',
      'shazam',
      'bandcamp',
      'audiomack',
      'qobuz',
      'napster',
      'anghami',
      'gaana',
      'saavn',
      'wynk',
      'trebel',
      'idagio',
      'kkbox',
      'tunein',
      'iheartradio',
      'netease.cloudmusic',
      'kugou',
      'kuwo',
      'boomplay',
      'podbean',
      'castbox',
    ];
    for (final k in onlineMusicKeywords) {
      if (pkg.contains(k) || name.contains(k)) return true;
    }

    // Specific check for YouTube Music & Apple Music
    if (pkg.contains('youtube.music') ||
        name.contains('youtube music') ||
        name.contains('yt music')) {
      return true;
    }
    if (pkg.contains('apple.android.music') || name.contains('apple music')) {
      return true;
    }
    if (pkg == 'com.amazon.mp3' || (pkg.contains('amazon') && name.contains('music'))) {
      return true;
    }

    // 4. Known offline music player packages (OEM and popular 3rd party players)
    const offlineMusicPackages = [
      'com.sec.android.app.music', // Samsung Music
      'com.miui.player', // Xiaomi Mi Music
      'com.sonyericsson.music', // Sony Music / Walkman
      'com.huawei.music', // Huawei Music
      'com.android.mediacenter', // Huawei MediaCenter
      'com.android.bbkmusic', // Vivo i Music
      'com.vivo.music', // Vivo Music
      'com.oppo.music', // Oppo Music
      'com.heytap.music', // Heytap / Realme / Oppo
      'com.oneplus.music', // OnePlus Music
      'com.lge.music', // LG Music
      'com.motorola.mototheme.music', // Moto Music
      'com.lenovo.music', // Lenovo Music
      'com.android.music', // AOSP Music
      'com.google.android.music', // Google Play Music
      'in.krosbits.musicolet', // Musicolet
      'com.maxmpz.audioplayer', // Poweramp
      'com.aimp.player', // AIMP
      'com.piyush.oto', // Oto Music
      'code.name.monkey.retromusic', // Retro Music Player
      'com.rhmsoft.pulsar', // Pulsar
      'com.rhmsoft.pulsar.pro',
      'com.rhmsoft.omnia', // Omnia
      'com.foobar2000.foobar2000', // Foobar2000
      'ru.stellio.player', // Stellio
      'com.kodarkooperativet.blackplayerfree', // BlackPlayer
      'com.kodarkooperativet.blackplayerex',
      'media.audioplayer.musicplayer', // Muzio Player
      'com.ringdroid.player', // Lark Player
      'com.larkplayer',
      'com.ventismedia.android.mediamonkey',
      'gonemad.gmmp',
      'jrtstudio.AnotherMusicPlayer',
      'com.simplecityapps.shuttle',
      'org.kreed.vanilla',
      'com.awedea.nyx',
      'project.pimusicplayer',
    ];
    for (final p in offlineMusicPackages) {
      if (pkg == p || pkg.contains(p)) return true;
    }

    // 5. Offline & generic music player keywords in app name
    const musicPlayerNameKeywords = [
      'music player',
      'pemutar musik',
      'pemutar lagu',
      'pemutar audio',
      'audio player',
      'mp3 player',
      'pemutar mp3',
      'offline music',
      'musik offline',
      'lagu offline',
      'music offline',
      'poweramp',
      'musicolet',
      'retromusic',
      'pulsar',
      'blackplayer',
      'stellio',
      'omnia',
      'foobar',
      'aimp',
    ];
    for (final k in musicPlayerNameKeywords) {
      if (name.contains(k) || pkg.contains(k.replaceAll(' ', ''))) return true;
    }

    // 6. Generic package patterns for music/audio
    if (pkg.contains('.music') ||
        pkg.contains('music.') ||
        pkg.contains('.audioplayer') ||
        pkg.contains('audio.player') ||
        pkg.contains('.musicplayer') ||
        pkg.contains('music.player') ||
        pkg.contains('mp3player') ||
        pkg.contains('.mp3') ||
        pkg.contains('mp3.')) {
      return true;
    }

    // 7. General music/audio terms in app name (guarded against games)
    if (name.contains('music') || name.contains('musik') || name.contains('audio')) {
      if (!name.contains('game') &&
          !name.contains('tile') &&
          !name.contains('piano') &&
          !pkg.contains('game')) {
        return true;
      }
    }

    return false;
  }

  /// Checks if an app is a pure VPN/Proxy utility (e.g. Turbo VPN, 1.1.1.1, Psiphon, WireGuard, OpenVPN, NordVPN, etc.)
  /// Pure VPN applications must NEVER be prohibited/blocked permanently, but are protected with Ghadhul Bashar reminders.
  static bool isPureVpnApp(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // Known bypass browsers that have built-in VPNs (these are browsers, NOT pure VPN apps)
    if (pkg.contains('opera') ||
        name.contains('opera') ||
        pkg.contains('alohamobile') ||
        name.contains('aloha') ||
        pkg.contains('com.upx.browser') ||
        name.contains('upx') ||
        pkg.contains('puffin') ||
        name.contains('puffin') ||
        pkg.contains('torproject') ||
        pkg.contains('torbrowser') ||
        name.contains('tor browser') ||
        pkg.contains('epicbrowser') ||
        name.contains('epic browser') ||
        pkg.contains('tenta.android') ||
        name.contains('tenta browser') ||
        pkg.contains('cake.browser') ||
        name.contains('cake browser') ||
        pkg.contains('blueproxy') ||
        name.contains('blue proxy') ||
        pkg.contains('bf.browser') ||
        name.contains('bf browser') ||
        pkg.contains('xnx.browser') ||
        name.contains('xnx browser')) {
      return false;
    }

    // Any app containing "browser" or "peramban" is a browser, not a pure VPN app
    final hasBrowserKeyword = pkg.contains('browser') ||
        name.contains('browser') ||
        name.contains('peramban');
    if (hasBrowserKeyword) {
      return false;
    }

    // Must be a VPN or proxy utility
    return isVpnApp(pkg, name);
  }

  /// Checks if an app is a web browser (e.g. Chrome, Firefox, Samsung Internet, Edge, Opera, etc.)
  static bool isBrowserApp(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    const browserPackages = [
      'com.android.chrome',
      'org.mozilla.firefox',
      'com.sec.android.app.sbrowser',
      'com.microsoft.emmx',
      'com.brave.browser',
      'com.opera.browser',
      'com.opera.mini.native',
      'com.duckduckgo.mobile.android',
      'com.vivaldi.browser',
      'com.ucmobile.intl',
      'com.uc.browser.en',
      'com.kiwibrowser.browser',
      'com.cloudmosa.puffinfree',
      'org.torproject.torbrowser',
      'com.heytap.browser',
      'com.mi.globalbrowser',
    ];
    if (browserPackages.contains(pkg)) return true;
    if (pkg.contains('.browser') || pkg.contains('browser.') || pkg.endsWith('browser')) return true;
    if (name.contains('browser') || name.contains('peramban')) return true;
    return false;
  }

  /// Checks if an app is a VPN or Proxy application
  static bool isVpnApp(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.contains('vpn') ||
        name.contains('vpn') ||
        pkg.contains('proxy') ||
        name.contains('proxy') ||
        pkg.contains('wireguard') ||
        name.contains('wireguard') ||
        pkg.contains('openvpn') ||
        name.contains('openvpn') ||
        pkg.contains('shadowsocks') ||
        name.contains('shadowsocks') ||
        pkg.contains('v2ray') ||
        name.contains('v2ray') ||
        pkg.contains('kr328.clash') ||
        pkg.contains('clashforandroid') ||
        pkg.contains('clash.meta') ||
        name == 'clash' ||
        name == 'clash for android' ||
        name == 'clash meta' ||
        pkg.contains('psiphon') ||
        name.contains('psiphon') ||
        pkg.contains('cloudflare') ||
        name.contains('1.1.1.1') ||
        pkg.contains('tunnelbear') ||
        name.contains('tunnelbear') ||
        pkg.contains('windscribe') ||
        name.contains('windscribe')) {
      return true;
    }
    const vpnPackages = [
      'com.cloudflare.onedotonedotonedotone',
      'com.wireguard.android',
      'de.blinkt.openvpn',
      'net.openvpn.openvpn',
      'com.psiphon3.subscription',
      'com.psiphon3',
      'ca.psiphon',
      'com.nordvpn.android',
      'com.expressvpn.vpn',
      'free.vpn.unblock.proxy.turbovpn',
      'ch.protonvpn.android',
      'com.surfshark.vpnclient.android',
      'com.jrzheng.supervpnfree',
      'org.hola',
    ];
    for (final p in vpnPackages) {
      if (pkg == p || pkg.contains(p)) return true;
    }
    return false;
  }

  /// Checks if device's language or locale setting corresponds to a region that blocks adult content
  /// specifically comparing app language and phone language/country for Indonesia, Malaysia, and Arab countries.
  static bool isRestrictedAdultContentRegion(String languageCode) {
    try {
      final appLang = languageCode.toLowerCase().trim();

      // Bahasa aplikasi yang terdeteksi
      const indonesianLangs = ['id', 'in'];
      const malaysianLangs = ['ms', 'zlm'];
      const arabicLangs = ['ar'];

      if (indonesianLangs.contains(appLang) ||
          malaysianLangs.contains(appLang) ||
          arabicLangs.contains(appLang)) {
        return true;
      }

      // Bahasa & Negara Sistem HP
      final sysLocale = ui.PlatformDispatcher.instance.locale;
      final sysLang = sysLocale.languageCode.toLowerCase();
      final sysCountry = (sysLocale.countryCode ?? '').toUpperCase();

      const arabCountries = [
        'SA', 'AE', 'QA', 'KW', 'OM', 'BH', 'EG', 'IQ', 'JO', 'LB', 'LY', 'MA', 'SD', 'SY', 'TN', 'YE', 'DZ'
      ];
      const otherRestrictedCountries = ['TR', 'PK', 'BD'];

      if (indonesianLangs.contains(sysLang) || sysCountry == 'ID') {
        return true;
      }
      if (malaysianLangs.contains(sysLang) || sysCountry == 'MY') {
        return true;
      }
      if (arabicLangs.contains(sysLang) || arabCountries.contains(sysCountry)) {
        return true;
      }
      if (otherRestrictedCountries.contains(sysCountry)) {
        return true;
      }

      // Periksa seluruh preferensi bahasa pengguna di perangkat
      for (final locale in ui.PlatformDispatcher.instance.locales) {
        final lang = locale.languageCode.toLowerCase();
        final country = (locale.countryCode ?? '').toUpperCase();

        if (indonesianLangs.contains(lang) || country == 'ID') return true;
        if (malaysianLangs.contains(lang) || country == 'MY') return true;
        if (arabicLangs.contains(lang) || arabCountries.contains(country)) return true;
        if (otherRestrictedCountries.contains(country)) return true;
      }
    } catch (_) {}
    return false;
  }

  /// Checks if the user is likely from Indonesia by comparing:
  /// 1. The selected app language ('id' or 'in')
  /// 2. The device system language ('id' or 'in')
  /// 3. The device system country code ('ID', e.g. en_ID)
  /// 4. Any locales in the device's preferred locale list
  static bool isIndonesianUser([String? appLanguageCode]) {
    try {
      final appLang = (appLanguageCode ?? '').toLowerCase().trim();
      if (appLang == 'id' || appLang == 'in') {
        return true;
      }

      final sysLocale = ui.PlatformDispatcher.instance.locale;
      final sysLang = sysLocale.languageCode.toLowerCase();
      final sysCountry = (sysLocale.countryCode ?? '').toUpperCase();

      if (sysLang == 'id' || sysLang == 'in' || sysCountry == 'ID') {
        return true;
      }

      for (final locale in ui.PlatformDispatcher.instance.locales) {
        final lang = locale.languageCode.toLowerCase();
        final country = (locale.countryCode ?? '').toUpperCase();
        if (lang == 'id' || lang == 'in' || country == 'ID') {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Returns the support / donation URL (Trakteer for Indonesian users, Ko-fi for others)
  static String getSupportUrl([String? appLanguageCode]) {
    return isIndonesianUser(appLanguageCode)
        ? 'https://trakteer.id/andri_setiawan108/tip'
        : 'https://ko-fi.com/andrisetiawan84153';
  }

  /// Returns the button label for supporting the developer based on language and detected platform
  static String getSupportButtonText(String lang) {
    final isIndo = isIndonesianUser(lang);
    if (isIndo) {
      return lang == 'id'
          ? 'Dukung / Usulkan Fitur via Trakteer'
          : 'Support / Request Features via Trakteer';
    }
    return Translations.get(lang, 'support_dev_btn');
  }

  /// Checks if an app is a bypass/anti-censorship browser frequently abused to circumvent adult content blocks
  /// (e.g. Yandex, Aloha Browser, UPX, Puffin, Tor Browser, Blue Proxy, etc.)
  static bool isProhibitedBypassBrowser(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // Pure VPN apps must NEVER be blocked permanently.
    // They are utility tools protected by the Ghadhul Bashar reminder in restricted regions.
    if (isPureVpnApp(pkg, name)) {
      return false;
    }

    // 1. Yandex (search plugin & browser)
    if (pkg.contains('yandex') || name.contains('yandex')) {
      return true;
    }

    // 2. Aloha Browser (built-in VPN)
    if (pkg.contains('alohamobile') || name.contains('aloha')) {
      return true;
    }

    // 3. UPX Proxy Browser
    if (pkg.contains('com.upx.browser') || name.contains('upx')) {
      return true;
    }

    // 4. Puffin Cloud Browser (Cloud rendering bypass)
    if (pkg.contains('puffin') || name.contains('puffin')) {
      return true;
    }

    // 5. Tor Browser (Onion routing)
    if (pkg.contains('torproject') ||
        pkg.contains('torbrowser') ||
        name.contains('tor browser') ||
        name == 'tor') {
      return true;
    }

    // 6. Opera Browser Family (built-in free VPN & data saving proxy)
    if (pkg.contains('opera') || name.contains('opera')) {
      return true;
    }

    // 7. UC Browser Family (built-in cloud acceleration proxy & bypass)
    if (pkg.contains('ucmobile') ||
        pkg.contains('uc.browser') ||
        pkg.contains('ucturbo') ||
        name.contains('uc browser') ||
        name.contains('uc mini') ||
        name.contains('uc turbo') ||
        name == 'uc') {
      return true;
    }

    // 8. Dedicated Privacy / VPN Browsers (Epic, Avast, AVG, Tenta, Cake, Hola Browser, InBrowser)
    if (pkg.contains('epicbrowser') ||
        name.contains('epic browser') ||
        pkg.contains('avast.android.secure.browser') ||
        pkg.contains('avg.android.secure.browser') ||
        pkg.contains('tenta.android') ||
        name.contains('tenta browser') ||
        pkg.contains('cake.browser') ||
        name.contains('cake browser') ||
        pkg.contains('hola.browser') ||
        name.contains('hola browser') ||
        pkg.contains('nuplayer.inbrowser') ||
        name.contains('inbrowser')) {
      return true;
    }

    // 9. Video Downloader / Bypass / Cloud Proxy Browsers (Phoenix, CM Browser, Baidu, Cốc Cốc, Maxthon, Dolphin, Bro Browser, Croxy)
    if (pkg.contains('transsion.phoenix') ||
        name.contains('phoenix browser') ||
        pkg.contains('ksmobile.cb') ||
        pkg.contains('cmcm.browser') ||
        name.contains('cm browser') ||
        pkg.contains('baidu.browser') ||
        name.contains('baidu browser') ||
        pkg.contains('coccoc') ||
        name.contains('coc coc') ||
        name.contains('cốc cốc') ||
        pkg.contains('maxthon') ||
        pkg.contains('mx.browser') ||
        name.contains('maxthon') ||
        pkg.contains('dolphin.browser') ||
        pkg.contains('mobi.mfront.android.browser') ||
        name.contains('dolphin browser') ||
        pkg.contains('brobrowser') ||
        pkg.contains('bro.browser') ||
        name.contains('bro browser') ||
        pkg.contains('croxy') ||
        name.contains('croxy')) {
      return true;
    }

    // 10. Blue Proxy / Anti-blokir / Bokeh / Proxy Browsers
    if (pkg.contains('blueproxy') ||
        name.contains('blue proxy') ||
        pkg.contains('antiblokir') ||
        name.contains('anti blokir') ||
        name.contains('anti-blokir') ||
        pkg.contains('buka.blokir') ||
        name.contains('buka blokir') ||
        pkg.contains('vpn.proxy.browser') ||
        pkg.contains('unblock.proxy.browser') ||
        name.contains('proxy browser') ||
        pkg.contains('bf.browser') ||
        name.contains('bf browser') ||
        pkg.contains('xnx.browser') ||
        name.contains('xnx browser') ||
        pkg.contains('bokeh') ||
        name.contains('bokeh')) {
      return true;
    }

    // 11. General heuristic: Any app identifying as a browser that also features VPN, Proxy, Unblock, Incognito/Secret/Stealth/Bypass capabilities
    final hasBrowserKeyword = pkg.contains('browser') ||
        name.contains('browser') ||
        name.contains('peramban');
    final hasVpnOrProxyKeyword = pkg.contains('vpn') ||
        name.contains('vpn') ||
        pkg.contains('proxy') ||
        name.contains('proxy') ||
        pkg.contains('unblock') ||
        name.contains('unblock') ||
        pkg.contains('bypass') ||
        name.contains('bypass') ||
        pkg.contains('tunnel') ||
        name.contains('tunnel') ||
        pkg.contains('incognito') ||
        name.contains('incognito') ||
        pkg.contains('secret') ||
        name.contains('secret browser') ||
        pkg.contains('stealth') ||
        name.contains('stealth browser') ||
        pkg.contains('hideme') ||
        name.contains('hideme');
    if (hasBrowserKeyword && hasVpnOrProxyKeyword) {
      return true;
    }

    return false;
  }

  /// Checks if an app is a dedicated explicit adult content application (e.g. Pornhub, Nekopoi, Simontox, XVideos, etc.)
  /// These apps are strictly prohibited under Islamic law and must NEVER be opened under any circumstances across all regions.
  static bool isExplicitAdultApp(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // 1. Nekopoi & Adult Anime / Hentai / Doujin (very common in Indonesia & SE Asia)
    if (pkg.contains('nekopoi') ||
        name.contains('nekopoi') ||
        pkg.contains('poi.care') ||
        pkg.contains('hanime') ||
        name.contains('hanime') ||
        pkg.contains('doujindesu') ||
        name.contains('doujindesu') ||
        pkg.contains('mangasusu') ||
        name.contains('mangasusu') ||
        pkg.contains('hentaihaven') ||
        name.contains('hentaihaven') ||
        pkg.contains('hentaistream') ||
        name.contains('hentaistream') ||
        pkg.contains('hentai') ||
        name.contains('hentai') ||
        pkg.contains('kucingpoi') ||
        name.contains('kucingpoi')) {
      return true;
    }

    // 2. Major Global Adult Tubes & Video Platforms (Pornhub, XVideos, XHamster, etc.)
    if (pkg.contains('pornhub') ||
        name.contains('pornhub') ||
        pkg.contains('xvideos') ||
        name.contains('xvideos') ||
        pkg.contains('xhamster') ||
        name.contains('xhamster') ||
        pkg.contains('redtube') ||
        name.contains('redtube') ||
        pkg.contains('youporn') ||
        name.contains('youporn') ||
        pkg.contains('spankbang') ||
        name.contains('spankbang') ||
        pkg.contains('brazzers') ||
        name.contains('brazzers') ||
        pkg.contains('xnxx') ||
        name.contains('xnxx') ||
        pkg.contains('eporner') ||
        name.contains('eporner') ||
        pkg.contains('tnaflix') ||
        name.contains('tnaflix') ||
        pkg.contains('thumbzilla') ||
        name.contains('thumbzilla') ||
        pkg.contains('beeg') ||
        name == 'beeg') {
      return true;
    }

    // 3. Regional / Indonesian Adult Video APKs (Simontox, SiMontok, Maxtube, Overhot, etc.)
    if (pkg.contains('simontox') ||
        name.contains('simontox') ||
        pkg.contains('simontok') ||
        name.contains('simontok') ||
        pkg.contains('simont9k') ||
        name.contains('simont9k') ||
        pkg.contains('maxtube') ||
        name.contains('maxtube') ||
        pkg.contains('overhot') ||
        name.contains('overhot')) {
      return true;
    }

    // 4. Adult Cam, Streaming & Paywall Platforms (Stripchat, Chaturbate, BongaCams, OnlyFans)
    if (pkg.contains('stripchat') ||
        name.contains('stripchat') ||
        pkg.contains('chaturbate') ||
        name.contains('chaturbate') ||
        pkg.contains('bongacams') ||
        name.contains('bongacams') ||
        pkg.contains('cam4') ||
        name.contains('cam4') ||
        pkg.contains('livejasmin') ||
        name.contains('livejasmin') ||
        pkg.contains('onlyfans') ||
        name.contains('onlyfans') ||
        pkg.contains('fancentro') ||
        name.contains('fancentro')) {
      return true;
    }

    // 5. Adult Solicitation & Prostitution Platforms (MiChat)
    if (pkg.contains('michat') || name.contains('michat')) {
      return true;
    }

    // 6. Adult Leaked Content & Storage Hubs (TeraBox)
    if (pkg.contains('terabox') ||
        name.contains('terabox') ||
        pkg.contains('dubox') ||
        name.contains('dubox')) {
      return true;
    }

    // 6. Explicit adult keywords (Indonesian and global)
    if (pkg.contains('bokep') ||
        name.contains('bokep') ||
        pkg.contains('.porn') ||
        pkg.contains('porn.') ||
        name.contains('porno') ||
        name.contains('video dewasa') ||
        name.contains('film dewasa') ||
        pkg.contains('javhd') ||
        name.contains('javhd')) {
      return true;
    }

    return false;
  }

  /// Checks if an app is a gambling, casino, slot, betting, or lottery app.
  /// In Islamic teachings, all forms of gambling (maysir) and betting are strictly haram (QS. Al-Ma'idah: 90).
  /// These apps are permanently prohibited and cannot be unlocked with points.
  static bool isGamblingApp(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // Guard: System essential apps are not gambling
    if (isSystemEssentialApp(pkg)) return false;

    // Exclusions for legitimate non-gambling apps (e.g., Domino's Pizza, sloth animal apps)
    if (pkg.contains('dominos') ||
        name.contains("domino's") ||
        name.contains('dominos pizza') ||
        name.contains('pizza')) {
      return false;
    }
    if (pkg.contains('sloth') || name.contains('sloth')) {
      return false;
    }

    // 1. Well-known Indonesian & Global Gambling Packages
    const knownGamblingPackages = [
      // Higgs & Domino Island gambling ecosystems
      'com.neptune.domino',
      'com.higgs.dominoisland',
      'com.higgs.domino',
      'com.topfun.domino',
      'com.topfun.domino.id',
      'com.royal.domino',
      'com.boyaa.domino',
      'com.boyaa.dominoindonesia',
      'com.h5.domino',
      'com.onegame.domino',
      'com.cynking.domino',
      // Slot & Casino Giants
      'com.playtika.slotomania',
      'com.playtika.caesarscasino',
      'com.playtika.wsop',
      'com.zynga.livepoker',
      'com.zynga.poker',
      'com.zynga.hititrich',
      'com.productmadness.cashmancasino',
      'com.productmadness.lightninglink',
      'com.scotty.jackpotparty',
      'com.huuuge.casino.slots',
      'com.murka.infinityslots',
      'com.murka.scatter_slots',
      'com.bally.quickhit',
      'com.gsn.grandcasino',
      'com.bagelcode.vegas.magic.slots',
      // Bookmakers & Online Sports Betting
      'com.bet365',
      'com.bet365.affiliates',
      'com.one_x_bet',
      'org.xbet',
      'com.parimatch',
      'com.betway.sports',
      'com.dafabet',
      'com.sbobet',
      'com.w88',
      'com.fun88',
      'com.m88',
      'com.stake',
      'com.betfair',
      'com.bwin',
      'com.draftkings.sportsbook',
      'com.fanduel.sportsbook',
    ];

    for (final known in knownGamblingPackages) {
      if (pkg == known || pkg.startsWith('$known.') || pkg.contains(known)) {
        return true;
      }
    }

    // 2. High-Confidence Gambling & Casino Keywords in Package Name or App Title
    const gamblingKeywords = [
      // Slot, Casino & Jackpot
      'slot',
      'slots',
      'casino',
      'jackpot',
      'pragmatic',
      'roulette',
      'baccarat',
      'blackjack',
      'fafafa',
      'maxwin',
      'scatter',
      'zeus slot',
      'olympus slot',
      'mahjong ways',
      'sweet bonanza',
      'gates of olympus',
      'spadegaming',
      'habanero',
      'joker123',
      // Poker & Betting
      'poker',
      'texas holdem',
      'idnpoker',
      'ceme keliling',
      'capsa susun',
      'judi',
      'judol',
      'taruhan',
      'taruhan bola',
      'sbobet',
      'bet365',
      '1xbet',
      'parimatch',
      'sportsbook',
      'bookmaker',
      'betting',
      // Indonesian Domino gambling variants
      'higgs domino',
      'domino island',
      'domino qiuqiu',
      'domino 99',
      'domino gaple',
      'qiuqiu',
      'kiukiu',
      'gaple online',
      'domino bet',
      // Togel & Lottery
      'togel',
      'totogel',
      'toto macau',
      'togel online',
      'lottery',
      'lotto',
      // Cockfight / Sabung ayam
      'sabung ayam',
      'sv388',
      's128',
    ];

    for (final kw in gamblingKeywords) {
      if (kw.contains(' ')) {
        if (name.contains(kw) || pkg.contains(kw.replaceAll(' ', ''))) return true;
      } else {
        if (name.contains(kw) || pkg.contains(kw)) return true;
      }
    }

    // 3. Package name segment checks (e.g. .slot., .casino., .poker., .betting.)
    if (pkg.contains('.slot') ||
        pkg.contains('.slots') ||
        pkg.contains('.casino') ||
        pkg.contains('.poker') ||
        pkg.contains('.bet.') ||
        pkg.contains('.betting') ||
        pkg.contains('.gamble') ||
        pkg.contains('.gambling') ||
        pkg.contains('.judol') ||
        pkg.contains('.togel')) {
      return true;
    }

    return false;
  }

  /// Checks if an app is permanently prohibited from being opened.
  /// 1. Dedicated explicit adult content apps (Pornhub, Nekopoi, Simontox, XVideos, etc.) are strictly prohibited across ALL countries.
  /// 2. Gambling, slot, and betting apps are strictly prohibited across ALL countries (QS. Al-Ma'idah: 90).
  /// 3. Bypass/anti-censorship browsers are prohibited in restricted adult content / VPN regions (Indonesia, Malaysia, Arab countries, etc.).
  bool isAppProhibited(String packageName, [String appName = '']) {
    if (isExplicitAdultApp(packageName, appName)) {
      return true;
    }
    if (isGamblingApp(packageName, appName)) {
      return true;
    }
    return isProhibitedBypassBrowser(packageName, appName) &&
        isRestrictedAdultContentRegion(_languageCode);
  }

  static bool isProhibitedAppStatic(
    String packageName, [
    String appName = '',
    String languageCode = 'id',
  ]) {
    if (isExplicitAdultApp(packageName, appName)) {
      return true;
    }
    if (isGamblingApp(packageName, appName)) {
      return true;
    }
    return isProhibitedBypassBrowser(packageName, appName) &&
        isRestrictedAdultContentRegion(languageCode);
  }

  /// Checks if an app is one of the major social or messaging platforms with high adult content / indecency risk:
  /// Facebook, Twitter/X, Instagram, TikTok, Telegram, and Telegram X (all countries).
  static bool isHighRiskSocialMediaApp(String packageName, [String appName = '']) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // 1. Facebook (Katana, Lite, Web wrapper)
    if (pkg.contains('com.facebook.katana') ||
        pkg.contains('com.facebook.lite') ||
        (name.contains('facebook') && !name.contains('messenger') && !name.contains('meta'))) {
      return true;
    }

    // 2. Twitter / X
    if (pkg.contains('twitter') ||
        name.contains('twitter') ||
        pkg == 'com.twitter.android' ||
        pkg == 'com.twitter.android.lite' ||
        pkg.startsWith('com.twitter.') ||
        pkg.startsWith('com.x.') ||
        name == 'x' ||
        name == 'x lite' ||
        name.contains('x (twitter)') ||
        (name == 'x' && (pkg.contains('twitter') || pkg.contains('x')))) {
      return true;
    }

    // 3. Instagram & Threads
    if (pkg.contains('instagram') ||
        name.contains('instagram') ||
        pkg.contains('barcelona') ||
        name.contains('threads')) {
      return true;
    }

    // 4. TikTok
    if (pkg.contains('musically') ||
        pkg.contains('tiktok') ||
        name.contains('tiktok') ||
        pkg.contains('trill')) {
      return true;
    }

    // 5. Telegram & Telegram X
    if (pkg.contains('telegram') ||
        pkg.contains('org.thunderdog.challegram') ||
        name.contains('telegram')) {
      return true;
    }

    return false;
  }

  /// Determines if an app should trigger the Ghadhul Bashar Quran reminder before opening
  static bool shouldShowGhadhulBasharReminder(
    String packageName, [
    String appName = '',
    String languageCode = 'en',
  ]) {
    if (isBrowserApp(packageName, appName)) {
      return true; // All browsers (all countries)
    }
    if (isHighRiskSocialMediaApp(packageName, appName)) {
      return true; // Facebook, Twitter/X, Instagram, TikTok, Telegram/Telegram X (all countries)
    }
    if (isVpnApp(packageName, appName) && isRestrictedAdultContentRegion(languageCode)) {
      return true; // VPNs in countries that block adult content
    }
    return false;
  }

  /// Checks if an app is a document scanner, QR/barcode reader, or OCR utility tool.
  /// Scanner apps are essential productive utilities and must NEVER be blocked.
  static bool isScannerApp(String packageName, String appName) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty && name.isEmpty) return false;

    // 1. Known Scanner, OCR & QR/Barcode Packages
    const scannerPackages = [
      'com.xiaomi.scanner', // Xiaomi / MIUI / HyperOS built-in Pemindai
      'com.intsig.camscanner', // CamScanner
      'com.intsig.camscannerhd',
      'com.intsig.lic.camscanner',
      'com.adobe.scan.android', // Adobe Scan
      'com.microsoft.office.officelens', // Microsoft Lens
      'com.gamma.scan', // QR & Barcode Scanner (Gamma Play)
      'com.google.ar.lens', // Google Lens
      'com.google.android.apps.camscanner',
      'com.google.android.apps.scanner',
      'pdf.tap.scanner', // TapScanner
      'com.cv.docscanner', // Document Scanner
      'com.coolmobilesolution.fastscannerfree', // Fast Scanner
      'com.appxy.tinyscan', // Tiny Scanner
      'com.indymobileapp.document.scanner', // Clear Scan
      'com.thegrizzlylabs.geniusscan.free', // Genius Scan
      'com.thegrizzlylabs.geniusscan',
      'com.oken.camscanner', // OKEN Scanner
      'com.google.zxing.client.android', // Barcode Scanner (ZXing)
      'com.teacapps.barcodescanner', // QR & Barcode Reader
      'com.simplemobiletools.scanner', // Simple Scanner
      'com.samsung.android.scan3d', // Samsung 3D Scanner
      'com.samsung.android.app.smartscan', // Samsung Smart Scan
      'com.huawei.scanner', // Huawei Scanner
      'com.coloros.ocrscanner', // Oppo / Realme Scanner
      'com.oppo.scanner',
      'com.vivo.scanner', // Vivo Scanner
      'com.transsion.scanner', // Transsion / Infinix / Tecno
    ];

    for (final sp in scannerPackages) {
      if (pkg == sp || pkg.contains(sp)) return true;
    }

    // 2. Package identifiers
    if (pkg.contains('.scanner') ||
        pkg.contains('scanner.') ||
        pkg.endsWith('.scanner') ||
        pkg.contains('pemindai') ||
        pkg.contains('camscanner') ||
        pkg.contains('docscan') ||
        pkg.contains('smartscan') ||
        pkg.contains('barcodescan') ||
        pkg.contains('barcode.scanner') ||
        pkg.contains('qrscan') ||
        pkg.contains('qr.reader') ||
        pkg.contains('qrreader') ||
        pkg.contains('qrcodereader') ||
        pkg.contains('officelens')) {
      return true;
    }

    // 3. App Name Keywords (Indonesian & English)
    const scannerNameKeywords = [
      'scanner',
      'pemindai',
      'camscanner',
      'pindai',
      'doc scan',
      'document scan',
      'tap scanner',
      'tiny scan',
      'fast scan',
      'clear scan',
      'genius scan',
      'qr scanner',
      'qr & barcode',
      'qr and barcode',
      'qr code',
      'kode qr',
      'barcode scanner',
      'barcode reader',
      'google lens',
      'ocr scanner',
      'text scanner',
      'pemindai teks',
      'pemindai dokumen',
      'pemindai qr',
      'pemindai barcode',
      'pemindai cepat',
      'smart scan',
      'adobe scan',
    ];

    for (final sk in scannerNameKeywords) {
      if (name.contains(sk)) return true;
    }

    return false;
  }

  /// Checks if an app is a productive, essential, utility, communication, educational, or religious app.
  /// Productive apps must NEVER be blocked by the launcher.
  static bool isProductiveApp(String packageName, String appName, [int category = -1]) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // Explicit adult apps and gambling apps are strictly excluded from being productive
    if (isExplicitAdultApp(pkg, name) || isGamblingApp(pkg, name)) {
      return false;
    }

    // Apps permanently marked as non-productive by the user can NEVER be productive
    if (_userNonProductiveApps.contains(pkg)) {
      return false;
    }

    // Scanner, Pemindai, OCR, QR & Barcode utilities (essential productive tools)
    if (isScannerApp(pkg, name)) {
      return true;
    }

    // Strictly non-productive apps (social media like Twitter/X, Instagram, TikTok, Reddit, Pinterest, games, dating, streaming)
    // can NEVER be considered productive, even if Android OS assigns them category News (5), Image (3), or Productivity (7).
    if (isStrictlyNonProductive(pkg, name, category)) {
      return false;
    }

    // User-whitelisted productive apps (strictly non-productive apps and games can never be whitelisted)
    if (_customProductiveApps.contains(pkg)) {
      return true;
    }

    // 1. Android OS Productive Categories:
    // CATEGORY_PRODUCTIVITY = 7 (Productivity / Office / Tools)
    // CATEGORY_MAPS = 6 (Navigation / Maps)
    // CATEGORY_NEWS = 5 (News / Informational)
    // CATEGORY_IMAGE = 3 (Photography / Gallery)
    // CATEGORY_AUDIO = 1 (Audio / Music)
    if (category == 7 || category == 6 || category == 5 || category == 3 || category == 1) {
      // Safety check: ensure game or TikTok hasn't somehow spoofed category
      if (!pkg.contains('musically') && !pkg.contains('tiktok') && !name.contains('tiktok')) {
        return true;
      }
    }

    // 2. Music & Audio apps (both online streaming and offline players)
    if (isMusicOrAudioApp(pkg, name, category)) {
      return true;
    }

    // 3. VPN & Proxy apps (treated as utility tools, with Ghadhul Bashar reminder)
    if (isVpnApp(pkg, name)) {
      return true;
    }

    // 4. Web Browsers (treated as essential research/search tools, with Ghadhul Bashar reminder)
    if (isBrowserApp(pkg, name)) {
      // Prohibited bypass browsers are not immune as productive apps
      if (isProhibitedBypassBrowser(pkg, name)) {
        return false;
      }
      return true;
    }

    // 4. Known Essential Whitelist Packages
    if (_whitelist.contains(pkg)) return true;

    // 4. Communication & Messaging (Work, Family & Productivity)
    const communicationPackages = [
      'com.whatsapp',
      'com.whatsapp.w4b',
      'org.telegram.messenger',
      'org.telegram.messenger.web',
      'org.thunderdog.challegram',
      'us.zoom.videomeetings',
      'com.google.android.apps.tachyon', // Google Meet (Duo)
      'com.google.android.apps.meetings', // Google Meet
      'com.microsoft.teams',
      'com.slack',
      'com.skype.raider',
      'org.thoughtcrime.securesms', // Signal
      'com.google.android.gm', // Gmail
      'com.microsoft.office.outlook',
      'com.samsung.android.email.provider',
      'com.yahoo.mobile.client.android.mail',
      'ch.protonmail.android',
    ];
    for (final p in communicationPackages) {
      if (pkg == p || pkg.startsWith('$p.')) return true;
    }

    // 5. Phone, Dialer, SMS, Contacts, Clock, Calendar, Calculator, Camera, Gallery, Files
    const oemSystemPackages = [
      'com.google.android.dialer',
      'com.android.dialer',
      'com.samsung.android.dialer',
      'com.google.android.contacts',
      'com.android.contacts',
      'com.samsung.android.app.contacts',
      'com.google.android.apps.messaging',
      'com.android.mms',
      'com.samsung.android.messaging',
      'com.google.android.deskclock',
      'com.sec.android.app.clockpackage',
      'com.android.deskclock',
      'com.google.android.calculator',
      'com.sec.android.app.popupcalculator',
      'com.android.calculator2',
      'com.google.android.calendar',
      'com.android.calendar',
      'com.samsung.android.calendar',
      'com.google.android.googlecamera',
      'com.sec.android.app.camera',
      'com.android.camera',
      'com.android.camera2',
      'com.google.android.apps.photos',
      'com.sec.android.gallery3d',
      'com.android.gallery3d',
      'com.google.android.apps.nbu.files',
      'com.sec.android.app.myfiles',
      'com.android.documentsui',
      'com.google.android.soundrecorder',
      'com.sec.android.app.voicenote',
      'com.android.settings',
      'com.android.vending',
      'com.xiaomi.scanner',
      'com.google.ar.lens',
    ];
    for (final p in oemSystemPackages) {
      if (pkg == p || pkg.contains(p)) return true;
    }

    // Exclude social video/reel editors from being treated as system camera/photo tools
    if (pkg.contains('instashot') ||
        pkg.contains('lemon.lvoverseas') ||
        pkg.contains('kinemaster') ||
        pkg.contains('shotcut')) {
      return false;
    }

    const systemToolKeywords = [
      'dialer',
      'telepon',
      'phone',
      'contacts',
      'kontak',
      'calculator',
      'kalkulator',
      'deskclock',
      'clockpackage',
      'clock',
      'alarm',
      'calendar',
      'kalender',
      'camera',
      'kamera',
      'gallery',
      'galeri',
      'photos',
      'documentsui',
      'myfiles',
      'filemanager',
      'soundrecorder',
      'voicenote',
      'settings',
      'pengaturan',
    ];
    for (final k in systemToolKeywords) {
      if (pkg.contains('.$k.') ||
          pkg.endsWith('.$k') ||
          pkg.startsWith('$k.') ||
          name == k ||
          name == 'google $k' ||
          name == 'samsung $k') {
        return true;
      }
    }

    // 6. Web Browsers
    const browserPackages = [
      'com.android.chrome',
      'org.mozilla.firefox',
      'com.sec.android.app.sbrowser',
      'com.microsoft.emmx',
      'com.brave.browser',
      'com.opera.browser',
      'com.opera.mini.native',
      'com.duckduckgo.mobile.android',
      'com.vivaldi.browser',
    ];
    for (final b in browserPackages) {
      if (pkg == b || pkg.contains(b)) return true;
    }
    if (name.contains('browser') || name.contains('peramban')) return true;

    // 7. Office, Docs, Notes & Education
    const officePackages = [
      'com.google.android.apps.docs',
      'com.google.android.apps.docs.editors.docs',
      'com.google.android.apps.docs.editors.sheets',
      'com.google.android.apps.docs.editors.slides',
      'com.google.android.keep',
      'com.microsoft.office.officehubrow',
      'com.microsoft.office.word',
      'com.microsoft.office.excel',
      'com.microsoft.office.powerpoint',
      'com.microsoft.office.onenote',
      'com.microsoft.skydrive',
      'cn.wps.moffice_eng',
      'so.notion.app',
      'com.evernote',
      'com.samsung.android.app.notes',
      'md.obsidian',
      'com.intsig.camscanner',
      'com.adobe.scan.android',
      'com.microsoft.office.officelens',
      'com.gamma.scan',
      'com.adobe.reader',
      'com.dropbox.android',
      'com.google.android.apps.classroom',
      'com.duolingo',
    ];
    for (final o in officePackages) {
      if (pkg == o || pkg.contains(o)) return true;
    }

    // 8. Developer, Coding & App Testing Tools
    const developerPackages = [
      'com.testerscommunity',
      'com.google.android.apps.playconsole',
      'com.github.android',
      'com.termux',
    ];
    for (final dp in developerPackages) {
      if (pkg == dp || pkg.contains(dp)) return true;
    }
    if (pkg.contains('testerscommunity') || name.contains('testers community')) {
      return true;
    }

    // 8. Navigation & Maps
    const navigationPackages = [
      'com.google.android.apps.maps',
      'com.waze',
      'com.here.app.maps',
    ];
    for (final nav in navigationPackages) {
      if (pkg == nav || pkg.contains(nav)) return true;
    }
    if (name == 'maps' || name == 'peta' || name.contains('navigation') || name.contains('navigasi')) {
      return true;
    }

    // 9. Banking, E-Wallets & Financial Services
    const bankingPackages = [
      'com.bca',
      'com.bca.mybca',
      'id.co.bankmandiri.livin',
      'id.co.bri.brimo',
      'id.co.bni.newmobilebanking',
      'id.co.bankbsi.mobilebanking',
      'id.dana',
      'ovo.id',
      'com.gopay.consumer',
      'com.telkom.mwallet',
      'com.bankjago',
      'com.btpn.dc',
      'com.seabank.id',
      'id.blubybcadigital',
      'com.shopee.id',
      'com.tokopedia.tkpd',
      'com.bukalapak.android',
      'com.lazada.android',
    ];
    for (final bp in bankingPackages) {
      if (pkg == bp || pkg.contains(bp)) return true;
    }

    // 10. Transportation & Daily Logistics
    const transportPackages = [
      'com.gojek.app',
      'com.grabtaxi.passenger',
      'com.taxsee.taxsee',
      'sinet.startup.indriver',
      'com.keretaapikita',
      'com.mypertamina.id',
    ];
    for (final tp in transportPackages) {
      if (pkg == tp || pkg.contains(tp)) return true;
    }

    // 11. Public Services & Healthcare
    const publicServicePackages = [
      'com.bpjstku',
      'app.bpjs.mobile',
      'com.pln.mobile',
      'dto.kemkes.satusehat',
    ];
    for (final psp in publicServicePackages) {
      if (pkg == psp || pkg.contains(psp)) return true;
    }

    // 12. Islamic & Religious Applications
    const islamicKeywords = [
      'quran',
      'qur\'an',
      'sholat',
      'salat',
      'prayer',
      'adzan',
      'azan',
      'hadits',
      'hadith',
      'dzikir',
      'tasbih',
      'muslim',
      'islam',
      'kemenag',
      'nu online',
      'muhammadiyah',
      'surah',
      'ayat',
      'tajwid',
      'kiblat',
      'qibla',
      'jadwal sholat',
      'tafsir',
      'fiqih',
      'doa',
    ];
    for (final ik in islamicKeywords) {
      if (name.contains(ik) || pkg.contains(ik.replaceAll(' ', ''))) {
        return true;
      }
    }

    return false;
  }

  /// Strictly non-productive apps that can NEVER be marked as productive
  /// (mindless social media scrolling, addictive short videos, dating, games, gambling, adult content, binge streaming).
  static bool isStrictlyNonProductive(String packageName, String appName, [int category = -1]) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // Explicit adult apps and gambling apps are strictly prohibited
    if (isExplicitAdultApp(pkg, name) ||
        isGamblingApp(pkg, name) ||
        isProhibitedBypassBrowser(pkg, name)) {
      return true;
    }

    // Apps permanently marked as non-productive by the user are strictly non-productive
    if (_userNonProductiveApps.contains(pkg)) {
      return true;
    }

    // Scanner, Pemindai, QR, and Document Scanning tools are productive utilities and strictly immune from non-productive classification
    if (isScannerApp(pkg, name)) {
      return false;
    }

    // 1. Android OS Category Game (CATEGORY_GAME = 0) - strictly non-productive without exception
    final int resolvedCat = category != -1 ? category : getAppCategoryStatic(pkg);
    if (resolvedCat == 0) return true;

    // 2. Social Media & Short Video Platforms (Mindless Scrolling)
    // TikTok & Musical.ly
    if (pkg.contains('musically') || pkg.contains('tiktok') || name.contains('tiktok')) {
      return true;
    }
    // Instagram & Threads
    if (pkg.contains('instagram') || name.contains('instagram') || pkg.contains('barcelona') || name.contains('threads')) {
      return true;
    }
    // Facebook
    if (pkg.contains('com.facebook.katana') || pkg.contains('com.facebook.lite') || name == 'facebook') {
      return true;
    }
    // Twitter / X (Elon Musk's X platform)
    if (pkg.contains('twitter') ||
        pkg == 'com.twitter.android' ||
        pkg == 'com.twitter.android.lite' ||
        pkg.startsWith('com.twitter.') ||
        pkg.startsWith('com.x.') ||
        pkg.contains('x.corp') ||
        name == 'x' ||
        name == 'twitter' ||
        name == 'x lite' ||
        name.contains('twitter') ||
        name.contains('x (twitter)') ||
        name.contains('twitter / x') ||
        (name == 'x' && (pkg.contains('twitter') || pkg.contains('x')))) {
      return true;
    }
    // Snapchat
    if (pkg.contains('snapchat') || name.contains('snapchat')) {
      return true;
    }
    // Pinterest
    if (pkg.contains('pinterest') || name.contains('pinterest')) {
      return true;
    }
    // Reddit
    if (pkg.contains('reddit') || name.contains('reddit')) {
      return true;
    }
    // Lifestyle, Microblogging & Meme Scrolling
    const lifestyleKeywords = [
      'lemon8',
      'xiaohongshu',
      'xingin.xhs',
      'tumblr',
      'sina.weibo',
      'weibo',
      'bluesky',
      '9gag',
      'ifunny',
      'bereal',
      'imgur',
      'deviantart',
      'vsco',
      'mastodon',
      'kaskus',
    ];
    for (final lk in lifestyleKeywords) {
      if (pkg.contains(lk) || name.contains(lk)) return true;
    }
    // Short Video & Live Streaming Platforms (SnackVideo, Likee, Bigo, Kwai, Tango, etc.)
    const shortVideoAndLiveKeywords = [
      'snackvideo',
      'kwaiviral',
      'kwai.video',
      'kwai',
      'video.like',
      'likee',
      'bigo.live',
      'bigo live',
      'triller',
      'helo.android',
      'chingari',
      'sharechat.moj',
      'sgiggle.production', // Tango
      'tango',
      'asiainno.uplive', // Uplive
      'uplive',
      'vshow.enjoy', // Poppo Live
      'poppo live',
      'poppo',
      'ushowmedia.nonolive', // Nonolive
      'mico',
      'yy.hiyo', // Hago
      'hago',
      'twelve.yellow', // Yubo
      'yubo',
      'sugar.live', // SugarLive
      'sugarlive',
      'mango.live', // Mango Live
      'mangolive',
      'dreamlive',
      'gogolive',
      'cmcm.live', // LiveMe
      'media17', // 17LIVE
      '17live',
      'movefastcompany.hakuna', // Hakuna
      'hakuna',
      'spoonme', // Spoon
      'kumumedia', // Kumu
    ];
    for (final sk in shortVideoAndLiveKeywords) {
      if (pkg.contains(sk) || name.contains(sk)) return true;
    }
    // Moj (Short video platform) - specific to avoid colliding with 'emoji'
    if (pkg.contains('in.mohalla.video.moj') ||
        pkg.contains('sharechat.moj') ||
        name == 'moj' ||
        name.startsWith('moj ') ||
        name.endsWith(' moj')) {
      return true;
    }

    // Voice Party, Virtual Rooms & Social Metaverse (Yalla, YoYo, WePlay, Lita, Zepeto, etc.)
    const voicePartyKeywords = [
      'yallagroup',
      'yalla',
      'yoyo.voice',
      'weplay',
      'litagaming.lita',
      'lita',
      'social.toptop',
      'toptop',
      'ola.party',
      'soulapp',
      'zepeto',
      'imvu',
      'clubhouse',
    ];
    for (final vk in voicePartyKeywords) {
      if (pkg.contains(vk) || name.contains(vk)) return true;
    }

    // Random & Anonymous Video/Text Chat (Azar, OmeTV, Litmatch, Chamet, Camfrog, NGL, etc.)
    const anonymousChatKeywords = [
      'hyperconnect.azar',
      'azar',
      'video.chat.ometv',
      'ometv',
      'litatom.litmatch',
      'litmatch',
      'hkfuliao.chamet',
      'chamet',
      'videochat.livu',
      'livu',
      'livechat.tumile',
      'tumile',
      'chatous',
      'camfrog',
      'cool.monkey',
      'bermuda.video',
      'corp.holla',
      'nglreactnative',
      'tellonym',
      'askfm',
      'tellm.android', // Jodel
      'jodel',
      'sh.whisper',
      'whisper',
    ];
    for (final ak in anonymousChatKeywords) {
      if (pkg.contains(ak) || name.contains(ak)) return true;
    }
    // NGL (Anonymous Instagram Q&A) - specific to avoid colliding with 'english'
    if (pkg.contains('nglreactnative') ||
        name == 'ngl' ||
        name.startsWith('ngl ') ||
        name.endsWith(' ngl')) {
      return true;
    }

    // Dating & Hookup Apps (Tinder, Bumble, Tantan, Badoo, Omi, Happn, Boo, etc.)
    const datingAppKeywords = [
      'tinder',
      'bumble',
      'tantan',
      'badoo',
      'okcupid',
      'co.hinge',
      'hinge',
      'match.android',
      'coffeemeetsbagel',
      'happn',
      'dating.boo',
      'boo.enterprises',
      'pureapp',
      'feeld',
      'lovoo',
      'skout',
      'mamba',
      'waplog',
      'taimi',
      'paktor',
      'grindrapp',
      'grindr',
      'blued',
      'hornet',
      'scruffapp',
      'scruff',
      'unearby.sayhi',
      'sayhi',
      'taggedapp',
      'tagged',
      'jaumo',
    ];
    for (final dk in datingAppKeywords) {
      if (pkg.contains(dk) || name.contains(dk)) return true;
    }
    // Omi (Dating app) - specific to avoid colliding with Xiaomi packages (com.xiaomi.*) or 'ekonomi'
    if (pkg.contains('omichat') ||
        (pkg.contains('haoda.wuta') && !pkg.contains('xiaomi')) ||
        name == 'omi' ||
        name.startsWith('omi ') ||
        name.endsWith(' omi')) {
      return true;
    }

    // 3. Video Streaming & Entertainment Binge-Watching Platforms
    if (pkg == 'com.google.android.youtube' || pkg == 'com.google.android.youtube.tv' || name == 'youtube') {
      return true;
    }
    const streamingVideoPackages = [
      'com.netflix.mediaclient',
      'in.startv.hotstar', // Disney+ Hotstar
      'com.disney.disneyplus',
      'tv.twitch.android.app',
      'com.amazon.avod.thirdpartyclient', // Prime Video
      'com.hulu.plus',
      'com.wbd.stream', // Max
      'com.hbo.hbonow',
      'com.vidio.android', // Vidio
      'com.vuclip.viu', // Viu
      'com.tencent.qqlivei18n', // WeTV
      'com.qiyi.video', // iQIYI
      'com.bstar.intl', // Bstation
      'tv.danmaku.bili',
      'org.vimeo.android',
      'com.dailymotion.videoplayer',
    ];
    for (final sv in streamingVideoPackages) {
      if (pkg == sv || pkg.contains(sv)) return true;
    }
    // Short Drama & Video Binge keywords
    const entertainmentKeywords = [
      'netflix',
      'hotstar',
      'disney+',
      'twitch',
      'vidio',
      'wetv',
      'iqiyi',
      'bstation',
      'bilibili',
      'dramabox',
      'shortmax',
      'reelshort',
      'loklok',
    ];
    for (final ek in entertainmentKeywords) {
      if (name.contains(ek) || pkg.contains(ek)) return true;
    }

    // Android Category Video (CATEGORY_VIDEO = 2)
    if (category == 2) return true;

    // 4. Popular Games (even if category is not reported as 0)
    const popularGameKeywords = [
      'mobile.legend',
      'freefire',
      'pubg',
      'genshin',
      'roblox',
      'subwaysurf',
      'candycrush',
      'clashofclans',
      'clashroyale',
      'brawlstars',
      'fallbuddies', // Stumble Guys
      'neptune.domino', // Higgs Domino
      'fifamobile',
      'pesam', // eFootball
      'minecraft',
      '8ballpool',
      'callofduty',
      'honorofkings',
      'amongus',
      'ludoking',
      'higgs',
      'supercell',
      'gameloft',
      'miniclip',
      'ea.gp',
      'konami',
      'riotgames',
      'rockstargames',
      'rockstar',
      'gtasa',
      'gta',
      'grand theft auto',
      'grandtheftauto',
      'vice city',
      'vicecity',
      'bully',
      'learn2fly',
      'learn 2 fly',
    ];
    for (final gk in popularGameKeywords) {
      if (pkg.contains(gk) || name.contains(gk)) return true;
    }

    // Gambling, Casino & Slot apps (strictly prohibited via isGamblingApp)
    if (isGamblingApp(pkg, name)) {
      return true;
    }

    // General game identifiers in package or name
    if (pkg.contains('.game.') ||
        pkg.contains('.games.') ||
        pkg.contains('rockstargames') ||
        pkg.startsWith('com.game') ||
        pkg.endsWith('.game') ||
        name.contains('game') ||
        name.contains('arcade') ||
        name.contains('puzzle') ||
        name.contains('racing') ||
        name.contains('simulation') ||
        name.contains('rpg') ||
        name.contains('bully') ||
        name.contains('gta') ||
        name.contains('learn 2 fly')) {
      return true;
    }

    // 5. Time-Wasting Web Novels & Comics
    const novelKeywords = [
      'wattpad',
      'linewebtoon',
      'webtoon',
      'mangatoon',
      'noveltoon',
      'fizzonovel',
      'fizzo novel',
      'dreame',
      'goodnovel',
    ];
    for (final nk in novelKeywords) {
      if (name.contains(nk) || pkg.contains(nk.replaceAll(' ', ''))) return true;
    }

    // 6. Video Editors for Social Content
    const videoEditorPackages = [
      'com.lemon.lvoverseas', // CapCut
      'com.camerasideas.instashot', // InShot
      'com.nexstreaming.app.kinemasterfree', // KineMaster
      'shotcut',
    ];
    for (final ve in videoEditorPackages) {
      if (pkg.contains(ve) || name.contains(ve)) return true;
    }

    return false;
  }

  /// Checks if an app is non-productive (games, social media, short-video scrolling, video streaming entertainment, gambling, web novels).
  /// Non-productive apps must be locked by the launcher.
  static bool isNonProductiveApp(String packageName, String appName, [int category = -1]) {
    final pkg = packageName.toLowerCase().trim();
    final name = appName.toLowerCase().trim();

    if (pkg.isEmpty) return false;

    // 1. PRODUCTIVE APPS ARE STRICTLY IMMUNE
    if (isProductiveApp(pkg, name, category)) {
      return false;
    }

    // 2. Apps strictly classified as non-productive (cannot be overridden)
    if (isStrictlyNonProductive(pkg, name, category)) {
      return true;
    }

    // 3. Android Category Social (CATEGORY_SOCIAL = 4)
    if (category == 4) return true;

    return false;
  }

  /// Automatically blocks non-productive apps and strictly protects productive apps
  Future<void> syncAppsWithCategories(List<dynamic> apps) async {
    bool changed = false;
    for (var app in apps) {
      if (app == null) continue;
      final pkg = (app['packageName'] as String? ?? '').toLowerCase().trim();
      final name = (app['appName'] as String? ?? '').toLowerCase().trim();
      final cat = app['category'] as int? ?? -1;

      if (pkg.isEmpty) continue;

      // 1. If productive, ensure it is NEVER blocked
      if (isProductiveApp(pkg, name, cat)) {
        if (_blockedApps.contains(pkg)) {
          _blockedApps.remove(pkg);
          changed = true;
        }
        continue;
      }

      // 2. If genuinely non-productive, ensure it IS blocked
      if (isNonProductiveApp(pkg, name, cat)) {
        if (!_blockedApps.contains(pkg)) {
          _blockedApps.add(pkg);
          changed = true;
        }
      }
    }

    if (changed) {
      await prefs.setStringList('blockedApps', _blockedApps.toList());
      await _appBlockService.setBlockedApps(_blockedApps.toList());
      notifyListeners();
    }
    await syncGhadhulBasharPackages(apps);
    await syncProhibitedPackages(apps);
  }

  String? _lastAttemptedProhibitedPackage;
  String? get lastAttemptedProhibitedPackage => _lastAttemptedProhibitedPackage;

  // Debounce & Guard timestamps to prevent double-triggers and race conditions
  int _lastGhadhulBasharDismissedTime = 0;
  String? _lastGhadhulBasharDismissedPackage;

  int _lastBlockedAppDismissedTime = 0;
  String? _lastBlockedAppDismissedPackage;

  int _lastProhibitedTriggeredTime = 0;
  String? _lastProhibitedTriggeredPackage;

  // Time-based guard timestamps for re-trigger prevention in callbacks
  int _lastBlockedEventTime = 0;
  int _lastGhadhulEventTime = 0;
  int _lastProhibitedEventTime = 0;

  void setProhibitedPackage(String pkg) {
    final cleanPkg = pkg.trim().toLowerCase();
    if (cleanPkg.isNotEmpty) {
      _lastAttemptedProhibitedPackage = cleanPkg;
      _lastAttemptedBlockedPackage = null;
      _lastAttemptedGhadhulBasharPackage = null;
      notifyListeners();
    }
  }

  bool get hasActiveOverlay =>
      (_lastAttemptedProhibitedPackage?.isNotEmpty ?? false) ||
      (_lastAttemptedBlockedPackage?.isNotEmpty ?? false) ||
      (_lastAttemptedGhadhulBasharPackage?.isNotEmpty ?? false);

  void clearAllOverlays() {
    bool changed = false;
    if (_lastAttemptedProhibitedPackage != null) {
      _lastAttemptedProhibitedPackage = null;
      changed = true;
    }
    if (_lastAttemptedBlockedPackage != null) {
      _lastBlockedAppDismissedPackage = _lastAttemptedBlockedPackage;
      _lastBlockedAppDismissedTime = DateTime.now().millisecondsSinceEpoch;
      _lastAttemptedBlockedPackage = null;
      changed = true;
    }
    if (_lastAttemptedGhadhulBasharPackage != null) {
      _lastGhadhulBasharDismissedPackage = _lastAttemptedGhadhulBasharPackage;
      _lastGhadhulBasharDismissedTime = DateTime.now().millisecondsSinceEpoch;
      _lastAttemptedGhadhulBasharPackage = null;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void goHome() {
    clearAllOverlays();
    if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
      navigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
  }

  void clearProhibitedPackage() {
    _lastAttemptedProhibitedPackage = null;
    notifyListeners();
  }

  void setBlockedPackage(String pkg) {
    final cleanPkg = pkg.trim().toLowerCase();
    if (cleanPkg.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiry = _unlockedExpirations[cleanPkg];
      if (expiry != null && now < expiry) {
        return;
      }
      _lastAttemptedBlockedPackage = cleanPkg;
      _lastAttemptedProhibitedPackage = null;
      _lastAttemptedGhadhulBasharPackage = null;
      notifyListeners();
    }
  }

  void clearBlockedApp() {
    if (_lastAttemptedBlockedPackage != null) {
      _lastBlockedAppDismissedPackage = _lastAttemptedBlockedPackage;
      _lastBlockedAppDismissedTime = DateTime.now().millisecondsSinceEpoch;
    }
    _lastAttemptedBlockedPackage = null;
    notifyListeners();
  }

  void clearGhadhulBashar() {
    if (_lastAttemptedGhadhulBasharPackage != null) {
      _lastGhadhulBasharDismissedPackage = _lastAttemptedGhadhulBasharPackage;
      _lastGhadhulBasharDismissedTime = DateTime.now().millisecondsSinceEpoch;
    }
    _lastAttemptedGhadhulBasharPackage = null;
    notifyListeners();
  }

  void setGhadhulBasharPackage(String pkg) {
    final cleanPkg = pkg.trim().toLowerCase();
    if (cleanPkg.isNotEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (cleanPkg == _lastGhadhulBasharDismissedPackage && (now - _lastGhadhulBasharDismissedTime) < 4000) {
        return;
      }
      _lastAttemptedGhadhulBasharPackage = cleanPkg;
      _lastAttemptedBlockedPackage = null;
      _lastAttemptedProhibitedPackage = null;
      notifyListeners();
    }
  }

  Future<void> confirmGhadhulBashar(String packageName) async {
    final pkg = packageName.toLowerCase();
    _lastGhadhulBasharDismissedPackage = pkg;
    _lastGhadhulBasharDismissedTime = DateTime.now().millisecondsSinceEpoch;
    try {
      await _appBlockService.allowGhadhulBasharSession(pkg);
    } catch (_) {}
    clearGhadhulBashar();
    await openApp(pkg, bypassGuards: true);
  }

  Future<void> resetGhadhulBasharSession(String packageName) async {
    final pkg = packageName.toLowerCase();
    try {
      await _appBlockService.resetGhadhulBasharSession(pkg);
    } catch (_) {}
  }

  Future<void> syncGhadhulBasharPackages([List<dynamic>? rawApps]) async {
    try {
      final targets = <String>{};
      final appsToScan = rawApps ?? [];

      for (var app in appsToScan) {
        if (app == null) continue;
        final pkg = (app['packageName'] as String? ?? '').toLowerCase().trim();
        final name = (app['appName'] as String? ?? '').toLowerCase().trim();
        if (pkg.isNotEmpty && shouldShowGhadhulBasharReminder(pkg, name, _languageCode)) {
          targets.add(pkg);
        }
      }

      // Always include well-known browsers
      const commonBrowsers = [
        'com.android.chrome',
        'org.mozilla.firefox',
        'com.sec.android.app.sbrowser',
        'com.microsoft.emmx',
        'com.brave.browser',
        'com.opera.browser',
        'com.opera.mini.native',
        'com.duckduckgo.mobile.android',
        'com.vivaldi.browser',
        'com.ucmobile.intl',
        'com.uc.browser.en',
        'com.kiwibrowser.browser',
        'com.cloudmosa.puffinfree',
        'org.torproject.torbrowser',
        'com.heytap.browser',
        'com.mi.globalbrowser',
      ];
      targets.addAll(commonBrowsers);

      // Always include Facebook, Twitter/X, Instagram, TikTok, and Telegram (all countries)
      const commonSocialMedia = [
        // Facebook
        'com.facebook.katana',
        'com.facebook.lite',
        // Twitter / X
        'com.twitter.android',
        'com.twitter.android.lite',
        // Instagram
        'com.instagram.android',
        'com.instagram.lite',
        'com.instagram.threadsapp',
        // TikTok
        'com.zhiliaoapp.musically',
        'com.zhiliaoapp.musically.go',
        'com.ss.android.ugc.trill',
        // Telegram & Telegram X
        'org.telegram.messenger',
        'org.telegram.messenger.web',
        'org.thunderdog.challegram',
        'org.telegram.plus',
      ];
      targets.addAll(commonSocialMedia);

      // If adult content restricted region, also include well-known VPNs
      if (isRestrictedAdultContentRegion(_languageCode)) {
        const commonVpns = [
          'com.cloudflare.onedotonedotonedotone',
          'com.wireguard.android',
          'de.blinkt.openvpn',
          'net.openvpn.openvpn',
          'com.psiphon3.subscription',
          'com.psiphon3',
          'org.hola',
          'com.nordvpn.android',
          'com.expressvpn.vpn',
          'free.vpn.unblock.proxy.turbovpn',
          'ch.protonvpn.android',
          'com.surfshark.vpnclient.android',
          'com.jrzheng.supervpnfree',
          'com.fast.free.unblock.thunder.vpn',
          'com.windscribe.vpn',
        ];
        targets.addAll(commonVpns);
      }

      await _appBlockService.setGhadhulBasharPackages(targets.toList());
    } catch (_) {}
  }

  Future<void> syncProhibitedPackages([List<dynamic>? rawApps]) async {
    try {
      final targets = <String>{};
      final isRestricted = isRestrictedAdultContentRegion(_languageCode);

      final appsToScan = rawApps ?? [];
      for (var app in appsToScan) {
        if (app == null) continue;
        final pkg = (app['packageName'] as String? ?? '').toLowerCase().trim();
        final name = (app['appName'] as String? ?? '').toLowerCase().trim();
        if (pkg.isNotEmpty) {
          // Explicit adult apps and gambling apps are ALWAYS prohibited across all regions
          if (isExplicitAdultApp(pkg, name)) {
            targets.add(pkg);
          } else if (isGamblingApp(pkg, name)) {
            targets.add(pkg);
          } else if (isRestricted && isProhibitedBypassBrowser(pkg, name)) {
            targets.add(pkg);
          }
        }
      }

      // Always include well-known explicit adult apps in native system block list
      const commonAdultApps = [
        'com.pornhub.android',
        'com.pornhub',
        'com.mph.pornhub',
        'app.pornhub',
        'com.nekopoi.care',
        'com.nekopoi',
        'app.nekopoi',
        'com.poi.care',
        'com.simontox.app',
        'com.simontox',
        'com.simontok.app',
        'com.simontok',
        'com.simont9k',
        'com.xvideos.app',
        'com.xvideos',
        'com.xhamster.app',
        'com.xhamster',
        'com.redtube',
        'com.youporn',
        'com.spankbang',
        'com.brazzers',
        'com.hanime',
        'tv.hanime',
        'com.doujindesu',
        'com.mangasusu',
        'com.stripchat',
        'com.chaturbate',
        'com.bongacams',
        'com.onlyfans',
        'com.maxtube',
        'com.overhot',
        'com.michat',
        'com.michat.lite',
      ];
      targets.addAll(commonAdultApps);

      // Common gambling and betting packages
      const commonGamblingApps = [
        'com.neptune.domino',
        'com.higgs.dominoisland',
        'com.higgs.domino',
        'com.topfun.domino',
        'com.topfun.domino.id',
        'com.royal.domino',
        'com.boyaa.domino',
        'com.h5.domino',
        'com.onegame.domino',
        'com.playtika.slotomania',
        'com.zynga.livepoker',
        'com.zynga.poker',
        'com.bet365',
        'com.parimatch',
        'org.xbet',
        'com.dafabet',
        'com.sbobet',
      ];
      targets.addAll(commonGamblingApps);

      if (isRestricted) {
        const commonProhibited = [
          'ru.yandex.searchplugin',
          'com.yandex.browser',
          'com.yandex.browser.alpha',
          'com.yandex.browser.beta',
          'com.alohamobile.browser',
          'com.alohamobile.browser.lite',
          'com.upx.browser',
          'com.cloudmosa.puffinfree',
          'com.cloudmosa.puffin',
          'org.torproject.torbrowser',
          'org.torproject.android',
          'org.torproject.torbrowser_alpha',
          'com.app.blueproxy',
          'com.sec.vpn.proxy.browser',
          // Opera browser family (built-in VPN)
          'com.opera.browser',
          'com.opera.mini.native',
          'com.opera.touch',
          'com.opera.gx',
          'com.opera.browser.beta',
          // UC browser family (cloud proxy / bypass)
          'com.UCMobile.intl',
          'com.uc.browser.en',
          'com.uc.browser.hd',
          'com.UCMobile',
          'com.ucturbo',
          // Dedicated privacy / VPN browsers
          'net.epicbrowser.epic',
          'com.avast.android.secure.browser',
          'com.avg.android.secure.browser',
          'com.tenta.android',
          'com.cake.browser',
          'org.hola.browser',
          'org.nuplayer.inbrowser',
          // Video downloader / bypass / cloud proxy browsers
          'com.transsion.phoenix',
          'com.ksmobile.cb',
          'com.cmcm.browser',
          'com.baidu.browser.inter',
          'com.coccoc.trinhduyet',
          'com.mx.browser',
          'com.dolphin.browser.express.web',
          'mobi.mfront.android.browser',
          'com.brobrowser',
          'com.croxyproxy',
          // Anti-blokir & bokeh browsers
          'com.bf.browser',
          'com.bf.browser.antiblokir',
          'com.xnx.browser',
          'com.xnx.browser.antiblokir',
          'com.browser.antiblokir.tercepat',
        ];
        targets.addAll(commonProhibited);
      }

      await _appBlockService.setProhibitedPackages(targets.toList());
    } catch (_) {}
  }

  /// Unlocks a blocked non-productive app using user points in a strictly atomic transaction.
  /// Prevents any bypass or free unlock if points < cost.
  Future<bool> unlockAppWithPoints(
    String packageName, {
    int cost = 50,
    int durationMinutes = 60,
  }) async {
    final pkg = packageName.toLowerCase().trim();
    if (pkg.isEmpty) return false;

    // 1. Strict validation: Points MUST be at least the cost
    if (_points < cost || cost <= 0) {
      debugPrint("Security guard rejected unlock: User has $_points points, required $cost points for $pkg");
      return false;
    }

    // 2. Deduct points first
    _points -= cost;
    if (_points < 0) _points = 0;
    await prefs.setInt('points', _points);

    // 3. Register native and local unlock
    final success = await allowAppTemporarily(pkg, durationMinutes: durationMinutes);
    if (!success) {
      // Rollback points if native registration failed
      _points += cost;
      await prefs.setInt('points', _points);
      notifyListeners();
      return false;
    }

    await _recordPointsSpentForDiscipline(cost);

    notifyListeners();
    return true;
  }

  Future<bool> allowAppTemporarily(String packageName, {int durationMinutes = 60}) async {
    final pkg = packageName.toLowerCase();
    final expiry = DateTime.now().millisecondsSinceEpoch + (durationMinutes * 60 * 1000);
    
    _unlockedExpirations[pkg] = expiry;
    bool success = true;
    
    try {
      await _appBlockService.allowAppTemporarily(pkg, durationMinutes: durationMinutes);
      await prefs.setString('unlockedExpirations', json.encode(_unlockedExpirations));
      _startStatusTimer();
    } catch (e) {
      _unlockedExpirations.remove(pkg); // Rollback locally if native fails
      success = false;
    }
    
    notifyListeners();
    return success;
  }

  bool isAppUnlocked(String packageName) {
    final pkg = packageName.toLowerCase().trim();
    final expiry = _unlockedExpirations[pkg];
    return expiry != null && DateTime.now().millisecondsSinceEpoch < expiry;
  }

  int getUnlockRemainingMinutes(String packageName) {
    final pkg = packageName.toLowerCase().trim();
    final expiry = _unlockedExpirations[pkg];
    if (expiry == null) return 0;
    
    final diff = expiry - DateTime.now().millisecondsSinceEpoch;
    if (diff <= 0) return 0;
    
    return (diff / (60 * 1000)).ceil();
  }

  Future<void> setHasSeenAccessibilitySetup(bool value) async {
    _hasSeenAccessibilitySetup = value;
    await prefs.setBool('hasSeenAccessibilitySetup', value);
    notifyListeners();
  }

  Future<void> setHasRequestedNotificationPermission(bool value) async {
    _hasRequestedNotificationPermission = value;
    await prefs.setBool('hasRequestedNotificationPermission', value);
    notifyListeners();
  }

  void setIgnorePermissionGuard(bool value) {
    _ignorePermissionGuard = value;
    notifyListeners();
  }

  Future<void> setLastReadAyat(String ayat) async {
    _lastReadAyat = ayat;
    await prefs.setString('lastReadAyat', ayat);
    notifyListeners();
  }

  int get currentSurahIndex => _highestSurahIndex;
  int get currentAyahIndex => _highestAyahIndex;

  Future<void> saveProgress(
    int surahIndex,
    int ayahIndex,
    String surahName,
    int ayahNumber,
    int pointsEarned,
  ) async {
    // Determine if this is the EXACT next sequential step (+1 ayah)
    bool isNextStep = false;
    
    // Check if same surah and next ayah
    if (surahIndex == _highestSurahIndex && ayahIndex == _highestAyahIndex + 1) {
      isNextStep = true;
    } 
    // Check if next surah and first ayah, but only if current surah is finished
    else if (surahIndex == _highestSurahIndex + 1 && ayahIndex == 0) {
      if (_highestSurahIndex < _quranData.length) {
        final currentSurah = _quranData[_highestSurahIndex];
        final totalAyahs = currentSurah['total_ayah'] as int;
        if (_highestAyahIndex == totalAyahs - 1) {
          isNextStep = true;
        }
      }
    }

    if (isNextStep) {
      _highestSurahIndex = surahIndex;
      _highestAyahIndex = ayahIndex;
      await prefs.setInt('highestSurahIndex', surahIndex);
      await prefs.setInt('highestAyahIndex', ayahIndex);
      
      // Update last read only on sequential progress
      _lastReadSurah = surahName;
      _lastReadAyahNumber = ayahNumber;
      await prefs.setString('lastReadSurah', surahName);
      await prefs.setInt('lastReadAyahNumber', ayahNumber);
      await prefs.setInt('currentSurahIndex', surahIndex);
      await prefs.setInt('currentAyahIndex', ayahIndex);

      // CHECK FOR KHATM (FULL COMPLETION)
      // Delegated to completeSurahMilestone when Surah 114 is completed
      // to ensure unified +500 grand bonus, khatmCount increment, and cycle reset.
    }

    // Always add to history regardless of sequential progress
    _addToHistory(surahName, ayahNumber, pointsEarned);
    await _recordQuranDailyRead();
    
    notifyListeners();
  }

  Future<void> _recordQuranDailyRead() async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    
    if (_lastQuranReadDate == today) {
      return; // Already recorded today
    }

    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    if (_lastQuranReadDate == yesterday) {
      _quranDailyStreak += 1;
    } else {
      _quranDailyStreak = 1;
    }

    _lastQuranReadDate = today;
    if (_quranDailyStreak > _maxQuranDailyStreak) {
      _maxQuranDailyStreak = _quranDailyStreak;
      await prefs.setInt('maxQuranDailyStreak', _maxQuranDailyStreak);
    }

    await prefs.setInt('quranDailyStreak', _quranDailyStreak);
    await prefs.setString('lastQuranReadDate', today);
    unawaited(StreakNotificationService.checkAndSyncReminder(this));
  }

  @visibleForTesting
  Future<void> setQuranStreakForTesting(int streak, {int? maxStreak, String? lastDate}) async {
    _quranDailyStreak = streak;
    _maxQuranDailyStreak = maxStreak ?? streak;
    _lastQuranReadDate = lastDate ?? DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('quranDailyStreak', _quranDailyStreak);
    await prefs.setInt('maxQuranDailyStreak', _maxQuranDailyStreak);
    await prefs.setString('lastQuranReadDate', _lastQuranReadDate);
    notifyListeners();
  }

  Future<void> _recordDzikirDailyRead() async {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];
    
    if (_lastDzikirDate == today) {
      return; // Already recorded today
    }

    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    if (_lastDzikirDate == yesterday) {
      _dzikirDailyStreak += 1;
    } else {
      _dzikirDailyStreak = 1;
    }

    _lastDzikirDate = today;
    if (_dzikirDailyStreak > _maxDzikirDailyStreak) {
      _maxDzikirDailyStreak = _dzikirDailyStreak;
      await prefs.setInt('maxDzikirDailyStreak', _maxDzikirDailyStreak);
    }

    await prefs.setInt('dzikirDailyStreak', _dzikirDailyStreak);
    await prefs.setString('lastDzikirDate', today);
    unawaited(StreakNotificationService.checkAndSyncReminder(this));
  }

  @visibleForTesting
  Future<void> setDzikirStreakForTesting(int streak, {int? maxStreak, String? lastDate, int? dailyCount}) async {
    _dzikirDailyStreak = streak;
    _maxDzikirDailyStreak = maxStreak ?? streak;
    _lastDzikirDate = lastDate ?? DateTime.now().toIso8601String().split('T')[0];
    if (dailyCount != null) {
      _dailyDzikirCount = dailyCount;
      await prefs.setInt('dailyDzikirCount', _dailyDzikirCount);
    } else if (lastDate != null && lastDate != DateTime.now().toIso8601String().split('T')[0]) {
      _dailyDzikirCount = 0;
      _dailyDzikirRounds = 0;
      await prefs.setInt('dailyDzikirCount', 0);
      await prefs.setInt('dailyDzikirRounds', 0);
    }
    await prefs.setInt('dzikirDailyStreak', _dzikirDailyStreak);
    await prefs.setInt('maxDzikirDailyStreak', _maxDzikirDailyStreak);
    await prefs.setString('lastDzikirDate', _lastDzikirDate);
    notifyListeners();
  }

  void _checkDailyDiscipline() {
    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    // First time initializing: start day 1 of discipline
    if (_lastDisciplineDate.isEmpty) {
      _lastDisciplineDate = today;
      _dailyPointsSpent = 0;
      _dailyPointsSpentDate = today;
      _disciplineDailyStreak = 1;
      _maxDisciplineDailyStreak = 1;
      prefs.setInt('disciplineDailyStreak', _disciplineDailyStreak);
      prefs.setInt('maxDisciplineDailyStreak', _maxDisciplineDailyStreak);
      prefs.setString('lastDisciplineDate', _lastDisciplineDate);
      prefs.setInt('dailyPointsSpent', _dailyPointsSpent);
      prefs.setString('dailyPointsSpentDate', _dailyPointsSpentDate);
      return;
    }

    // Still same day:
    if (_dailyPointsSpentDate == today) {
      if (_dailyPointsSpent > 50 && _disciplineDailyStreak > 0) {
        _disciplineDailyStreak = 0;
        prefs.setInt('disciplineDailyStreak', 0);
      }
      return;
    }

    // New day has arrived:
    final yesterday = now.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];

    if (_dailyPointsSpentDate == yesterday) {
      // Yesterday finished! Check if yesterday was successful (<= 50 points spent)
      if (_dailyPointsSpent <= 50) {
        if (_disciplineDailyStreak == 0) {
          _disciplineDailyStreak = 1;
        } else {
          _disciplineDailyStreak += 1;
        }
      } else {
        _disciplineDailyStreak = 1;
      }
    } else {
      // More than 1 day passed without launcher active
      _disciplineDailyStreak = 1;
    }

    _lastDisciplineDate = today;
    _dailyPointsSpent = 0;
    _dailyPointsSpentDate = today;

    if (_disciplineDailyStreak > _maxDisciplineDailyStreak) {
      _maxDisciplineDailyStreak = _disciplineDailyStreak;
      prefs.setInt('maxDisciplineDailyStreak', _maxDisciplineDailyStreak);
    }

    prefs.setInt('disciplineDailyStreak', _disciplineDailyStreak);
    prefs.setString('lastDisciplineDate', _lastDisciplineDate);
    prefs.setInt('dailyPointsSpent', _dailyPointsSpent);
    prefs.setString('dailyPointsSpentDate', _dailyPointsSpentDate);
  }

  Future<void> _recordPointsSpentForDiscipline(int cost) async {
    _checkDailyDiscipline();
    _dailyPointsSpent += cost;
    await prefs.setInt('dailyPointsSpent', _dailyPointsSpent);

    if (_dailyPointsSpent > 50) {
      _disciplineDailyStreak = 0;
      await prefs.setInt('disciplineDailyStreak', 0);
    }
  }

  @visibleForTesting
  Future<void> setDisciplineStreakForTesting(int streak, {int? maxStreak, String? lastDate, int? dailyPointsSpent}) async {
    _disciplineDailyStreak = streak;
    _maxDisciplineDailyStreak = maxStreak ?? streak;
    final date = lastDate ?? DateTime.now().toIso8601String().split('T')[0];
    _lastDisciplineDate = date;
    _dailyPointsSpentDate = date;
    if (dailyPointsSpent != null) {
      _dailyPointsSpent = dailyPointsSpent;
      await prefs.setInt('dailyPointsSpent', _dailyPointsSpent);
    }
    await prefs.setInt('disciplineDailyStreak', _disciplineDailyStreak);
    await prefs.setInt('maxDisciplineDailyStreak', _maxDisciplineDailyStreak);
    await prefs.setString('lastDisciplineDate', _lastDisciplineDate);
    await prefs.setString('dailyPointsSpentDate', _dailyPointsSpentDate);
    notifyListeners();
  }

  Future<bool> claimBadgeReward(String badgeId, int pointsReward, String badgeTitle) async {
    if (_claimedBadgeIds.contains(badgeId) || pointsReward <= 0) return false;
    _claimedBadgeIds.add(badgeId);
    await prefs.setStringList('claimedBadgeIds', _claimedBadgeIds.toList());
    _points += pointsReward;
    await prefs.setInt('points', _points);
    _addToHistory("🏆 Lencana: $badgeTitle", 1, pointsReward);
    notifyListeners();
    return true;
  }

  Future<int> claimAllBadgeRewards(List<Map<String, dynamic>> claimableBadges) async {
    if (claimableBadges.isEmpty) return 0;
    int totalClaimed = 0;
    for (final item in claimableBadges) {
      final badgeId = item['id'] as String;
      final points = item['points'] as int;
      final title = item['title'] as String;
      if (!_claimedBadgeIds.contains(badgeId) && points > 0) {
        _claimedBadgeIds.add(badgeId);
        totalClaimed += points;
        _addToHistory("🏆 Lencana: $title", 1, points);
      }
    }
    if (totalClaimed > 0) {
      await prefs.setStringList('claimedBadgeIds', _claimedBadgeIds.toList());
      _points += totalClaimed;
      await prefs.setInt('points', _points);
      notifyListeners();
    }
    return totalClaimed;
  }

  @visibleForTesting
  Future<void> setClaimedBadgesForTesting(Set<String> badgeIds) async {
    _claimedBadgeIds = Set.from(badgeIds);
    await prefs.setStringList('claimedBadgeIds', _claimedBadgeIds.toList());
    notifyListeners();
  }

  bool canEarnPoints(int surahIndex, int ayahIndex) {
    // Points are earned ONLY if it's the exact next step
    if (surahIndex == _highestSurahIndex && ayahIndex == _highestAyahIndex + 1) {
      return true;
    }
    
    if (surahIndex == _highestSurahIndex + 1 && ayahIndex == 0) {
      if (_highestSurahIndex < _quranData.length) {
        final currentSurah = _quranData[_highestSurahIndex];
        final totalAyahs = currentSurah['total_ayah'] as int;
        return _highestAyahIndex == totalAyahs - 1;
      }
    }
    
    return false;
  }

  // Helper getters to help UI determine if an ayah/surah is "beyond" current progress
  int get highestSurahIndex => _highestSurahIndex;
  int get highestAyahIndex => _highestAyahIndex;

  bool isSurahUnlocked(int index) {
    if (index <= _highestSurahIndex) return true;
    if (index == _highestSurahIndex + 1) {
      // Unlocked if previous surah is finished
      if (_highestSurahIndex < _quranData.length) {
        final prevSurah = _quranData[_highestSurahIndex];
        final totalAyahs = prevSurah['total_ayah'] as int;
        return _highestAyahIndex == totalAyahs - 1;
      }
    }
    return false;
  }

  bool isSurahFinished(int index) {
    if (index < _highestSurahIndex) return true;
    if (index == _highestSurahIndex) {
      if (index >= 0 && index < _quranData.length) {
        final surah = _quranData[index];
        final totalAyahs = surah['total_ayah'] as int;
        return _highestAyahIndex == totalAyahs - 1;
      }
    }
    return false;
  }

  bool isNextAyah(int surahIndex, int ayahIndex) {
    // Exact same logic as point earning
    if (surahIndex == _highestSurahIndex && ayahIndex == _highestAyahIndex + 1) {
      return true;
    }
    if (surahIndex == _highestSurahIndex + 1 && ayahIndex == 0) {
      if (_highestSurahIndex < _quranData.length) {
        final currentSurah = _quranData[_highestSurahIndex];
        final totalAyahs = currentSurah['total_ayah'] as int;
        return _highestAyahIndex == totalAyahs - 1;
      }
    }
    return false;
  }

  bool isAyahReached(int surahIdx, int ayahIdx) {
    if (surahIdx < _highestSurahIndex) return true;
    if (surahIdx == _highestSurahIndex) return ayahIdx <= _highestAyahIndex;
    return false;
  }

  void _addToHistory(String surahName, int ayahNumber, int pointsEarned) {
    final entry = {
      'surah': surahName,
      'ayah': ayahNumber,
      'points': pointsEarned,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _readingHistory.insert(0, entry); // Newest first
    if (_readingHistory.length > 50) _readingHistory.removeLast(); // Keep last 50
    
    prefs.setString('readingHistory', json.encode(_readingHistory));
  }

  Future<void> saveHadithProgress(int hadithId, String hadithTitle, int pointsEarned) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastHadithDate = prefs.getString('lastHadithDate') ?? '';
    if (lastHadithDate != today) {
      _readHadithIds.clear();
      await prefs.setString('lastHadithDate', today);
    }

    final isFirstTime = !_readHadithIds.contains(hadithId);
    _readHadithIds.add(hadithId);
    await prefs.setStringList('readHadithIds', _readHadithIds.map((e) => e.toString()).toList());
    await prefs.setString('lastHadithDate', today);

    if (isFirstTime && pointsEarned > 0) {
      _points += pointsEarned;
      await prefs.setInt('points', _points);
    }

    _addToHistory(hadithTitle, hadithId, isFirstTime ? pointsEarned : 0);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    await prefs.setString('userName', _userName);
    notifyListeners();
  }

  /// Completes a Surah milestone according to tiered effort reward economy (docs/milestone_share_card_plan.md Section 3.3).
  /// Tier 1: 1-25 ayat (+10 pts)
  /// Tier 2: 26-75 ayat (+25 pts)
  /// Tier 3: 76-150 ayat (+50 pts)
  /// Tier 4: >150 ayat (+100 pts)
  /// Special Friday Al-Kahfi (Surah 18): (+50 pts)
  /// Grand Milestone Khatam 30 Juz: (+500 pts and resets cycle)
  Future<Map<String, dynamic>> completeSurahMilestone({
    required int surahNumber,
    required String surahName,
    required int totalAyahs,
    int readingDurationSeconds = 0,
  }) async {
    final bool isAlreadyCompleted = _completedSurahsThisCycle.contains(surahNumber);
    if (isAlreadyCompleted) {
      return {
        'isNewMilestone': false,
        'isKhatam': false,
        'bonusPoints': 0,
        'tier': 0,
      };
    }

    int tier = 1;
    int baseBonusPoints = 10;
    if (totalAyahs <= 25) {
      tier = 1;
      baseBonusPoints = 10;
    } else if (totalAyahs <= 75) {
      tier = 2;
      baseBonusPoints = 25;
    } else if (totalAyahs <= 150) {
      tier = 3;
      baseBonusPoints = 50;
    } else {
      tier = 4;
      baseBonusPoints = 100;
    }

    // Special Friday Al-Kahf check (Surah 18)
    final now = DateTime.now();
    if (surahNumber == 18 && now.weekday == DateTime.friday) {
      baseBonusPoints += 50;
    }

    // Apply Maqam Point Boost Multiplier (strictly whole integer, rounded)
    final double multiplier = maqamBoostMultiplier;
    final int bonusPoints = (baseBonusPoints * multiplier).round();

    _completedSurahsThisCycle.add(surahNumber);
    await prefs.setStringList(
      'completedSurahsThisCycle',
      _completedSurahsThisCycle.map((e) => e.toString()).toList(),
    );

    _points += bonusPoints;
    await prefs.setInt('points', _points);

    bool isKhatam = false;
    if (_completedSurahsThisCycle.length >= 114 || surahNumber == 114) {
      isKhatam = true;
      _khatmCount++;
      await prefs.setInt('khatmCount', _khatmCount);
      AnalyticsService.logQuranKhatm(khatmCount: _khatmCount);

      // Grand bonus +500 base points for Khatam 30 Juz scaled by Maqam Boost
      // (Strictly whole integer: T1: 500, T2: 625, T3: 750, T4: 875, T5: 1000)
      final int grandKhatamPoints = (500 * multiplier).round();
      _points += grandKhatamPoints;
      await prefs.setInt('points', _points);

      // Reset completed surahs for the new khatam cycle
      _completedSurahsThisCycle.clear();
      await prefs.setStringList('completedSurahsThisCycle', []);
      _highestSurahIndex = 0;
      _highestAyahIndex = -1;
      await prefs.setInt('highestSurahIndex', 0);
      await prefs.setInt('highestAyahIndex', -1);

      _addToHistory("👑 KHATAM 30 JUZ AL-QUR'AN", 30, grandKhatamPoints);
    }

    _addToHistory("🏆 Selesai Surah $surahName", totalAyahs, bonusPoints);
    notifyListeners();

    return {
      'isNewMilestone': true,
      'isKhatam': isKhatam,
      'bonusPoints': bonusPoints,
      'baseBonusPoints': baseBonusPoints,
      'boostMultiplier': multiplier,
      'boostPercent': maqamBoostPercent,
      'tier': tier,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'totalAyahs': totalAyahs,
    };
  }

  /// Saves Dzikir progress with scientific 3-round daily cap (99 butir = 19 points max).
  /// Round 1 (33x): +3 pts
  /// Round 2 (66x): +3 pts
  /// Round 3 (99x): +13 pts (3 + 10 bonus)
  /// Round > 3: 0 pts (still records count & history, no app unlock spamming)
  Future<Map<String, dynamic>> saveDzikirProgress(
    String dzikirTitle,
    int count,
    int rawPoints,
  ) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_dailyDzikirDate != today) {
      _dailyDzikirRounds = 0;
      _dailyDzikirPoints = 0;
      _dailyDzikirCount = 0;
      _dailyDzikirDate = today;
    }

    _dailyDzikirRounds++;
    _dailyDzikirCount += count;
    await prefs.setInt('dailyDzikirCount', _dailyDzikirCount);

    int baseAllocatedPoints = 0;
    if (_dailyDzikirRounds == 1) {
      baseAllocatedPoints = 3;
    } else if (_dailyDzikirRounds == 2) {
      baseAllocatedPoints = 3;
    } else if (_dailyDzikirRounds == 3) {
      baseAllocatedPoints = 13;
    } else {
      baseAllocatedPoints = 0;
    }

    // Apply Maqam Point Boost Multiplier (strictly whole integer, rounded)
    final int allocatedPoints = (baseAllocatedPoints * maqamBoostMultiplier).round();

    if (allocatedPoints > 0) {
      _points += allocatedPoints;
      _dailyDzikirPoints += allocatedPoints;
      await prefs.setInt('points', _points);
      await prefs.setInt('dailyDzikirPoints', _dailyDzikirPoints);
    }
    await prefs.setInt('dailyDzikirRounds', _dailyDzikirRounds);
    await prefs.setString('dailyDzikirDate', _dailyDzikirDate);

    _totalDzikirCount += count;
    await prefs.setInt('totalDzikirCount', _totalDzikirCount);

    _addToHistory("Dzikir: $dzikirTitle (${count}x)", count, allocatedPoints);

    // Minimum 1 round (33x) to record/maintain daily dzikir streak
    if (_dailyDzikirCount >= 33) {
      await _recordDzikirDailyRead();
    }
    notifyListeners();

    return {
      'round': _dailyDzikirRounds,
      'pointsEarned': allocatedPoints,
      'isDailyCapReached': _dailyDzikirRounds >= 3,
    };
  }

  Future<void> addDzikirCount(int count) async {
    if (count <= 0) return;
    _totalDzikirCount += count;
    await prefs.setInt('totalDzikirCount', _totalDzikirCount);

    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_dailyDzikirDate != today) {
      _dailyDzikirRounds = 0;
      _dailyDzikirPoints = 0;
      _dailyDzikirCount = 0;
      _dailyDzikirDate = today;
    }
    _dailyDzikirCount += count;
    await prefs.setInt('dailyDzikirCount', _dailyDzikirCount);
    await prefs.setInt('dailyDzikirRounds', _dailyDzikirRounds);
    await prefs.setInt('dailyDzikirPoints', _dailyDzikirPoints);
    await prefs.setString('dailyDzikirDate', _dailyDzikirDate);

    // Minimum 1 round (33x) to record/maintain daily dzikir streak
    if (_dailyDzikirCount >= 33) {
      await _recordDzikirDailyRead();
    }
    notifyListeners();
  }

  bool isAppBlocked(String packageName) {
    final pkg = packageName.toLowerCase().trim();
    if (isProductiveApp(pkg, '')) return false;
    if (!_blockedApps.contains(pkg)) return false;
    
    // Check if temporarily allowed
    final expiry = _unlockedExpirations[pkg];
    if (expiry != null && DateTime.now().millisecondsSinceEpoch < expiry) {
      return false;
    }
    
    return true;
  }
}
