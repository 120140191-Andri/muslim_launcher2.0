import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_block_service.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;

  AppState(this.prefs) {
    _init();
  }

  String _languageCode = 'id';
  bool _hasSelectedLanguage = false;
  bool _hasCompletedOnboarding = false;
  int _points = 0;
  Set<String> _blockedApps = {};
  int _highestSurahIndex = 0;
  int _highestAyahIndex = -1; // -1 means no progress yet
  int _khatmCount = 0;
  List<Map<String, dynamic>> _readingHistory = [];
  Map<String, int> _unlockedExpirations = {};
  String? _lastAttemptedBlockedPackage;
  bool _isAccessibilityEnabled = false;
  bool _isDefaultLauncher = false;
  bool _hasSeenAccessibilitySetup = false;
  String _manufacturer = '';
  String _deviceModel = '';
  bool _ignorePermissionGuard = false;
  final AppBlockService _appBlockService = AppBlockService();
  Timer? _statusTimer;
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _lastReadAyat = '';
  String _lastReadSurah = '';
  int _lastReadAyahNumber = 0;
  List<dynamic> _quranData = [];
  bool _isDataLoaded = false;
  bool _isInitialized = false;

  // Persistent Daily Verse
  String _dailySurahName = '';
  int _dailyAyahNumber = 0;
  String _dailyAyahTextEn = '';
  String _dailyAyahTextId = '';
  String _dailyVerseDate = '';

  bool get isReady => _isDataLoaded && _isInitialized;


  String get languageCode => _languageCode;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get points => _points;
  Set<String> get blockedApps => _blockedApps;
  String get lastReadAyat => _lastReadAyat;
  String get lastReadSurah => _lastReadSurah;
  int get lastReadAyahNumber => _lastReadAyahNumber;
  List<dynamic> get quranData => _quranData;
  bool get isDataLoaded => _isDataLoaded;
  int get khatmCount => _khatmCount;
  List<Map<String, dynamic>> get readingHistory => _readingHistory;
  String? get lastAttemptedBlockedPackage => _lastAttemptedBlockedPackage;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isDefaultLauncher => _isDefaultLauncher;
  bool get hasSeenAccessibilitySetup => _hasSeenAccessibilitySetup;
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

  void _init() async {
    _languageCode = prefs.getString('languageCode') ?? 'id';
    _hasSelectedLanguage = prefs.getBool('hasSelectedLanguage') ?? false;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _points = prefs.getInt('points') ?? 0;
    _blockedApps = (prefs.getStringList('blockedApps') ?? []).toSet();
    _lastReadAyat = prefs.getString('lastReadAyat') ?? '';
    _lastReadSurah = prefs.getString('lastReadSurah') ?? '';
    _lastReadAyahNumber = prefs.getInt('lastReadAyahNumber') ?? 0;
    _hasSeenAccessibilitySetup = prefs.getBool('hasSeenAccessibilitySetup') ?? false;
    
    _highestSurahIndex = prefs.getInt('highestSurahIndex') ?? 0;
    _highestAyahIndex = prefs.getInt('highestAyahIndex') ?? -1;
    _khatmCount = prefs.getInt('khatmCount') ?? 0;
    
    final historyJson = prefs.getString('readingHistory') ?? '[]';
    try {
      final decoded = json.decode(historyJson) as List;
      _readingHistory = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      _readingHistory = [];
    }
    
    final unlockedJson = prefs.getString('unlockedExpirations') ?? '{}';
    try {
      final decoded = json.decode(unlockedJson) as Map<String, dynamic>;
      _unlockedExpirations = decoded.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      _unlockedExpirations = {};
    }

    // Await crucial initialization
    await Future.wait([
      loadQuranData(),
      _fetchDeviceInfo(),
    ]);

    _initDailyVerse();
    
    // Initialize App Block Service
    _appBlockService.init(onAppBlocked: (pkg) {
      if (pkg.trim().isNotEmpty) {
        _lastAttemptedBlockedPackage = pkg.toLowerCase();
        notifyListeners();
      }
    });
    _appBlockService.setBlockedApps(_blockedApps.toList());
    
    // Initial status check before showing UI
    try {
      _isAccessibilityEnabled = await _appBlockService.isAccessibilityEnabled();
      const appsChannel = MethodChannel('com.muslimlauncher/apps');
      _isDefaultLauncher = await appsChannel.invokeMethod('isDefaultLauncher');
    } catch (_) {}

    _isInitialized = true;
    _startStatusTimer();
    
    notifyListeners();
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
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      refreshStatus();

      // 3. Cleanup & Unlock Expiry
      _cleanupExpiredUnlocks();
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
      final Map<dynamic, dynamic>? info = await appsChannel.invokeMethod('getDeviceInfo');
      if (info != null) {
        _manufacturer = (info['manufacturer'] as String? ?? '').toLowerCase();
        _deviceModel = (info['model'] as String? ?? '').toLowerCase();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch device info: $e");
    }
  }

  void _cleanupExpiredUnlocks() {
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
      notifyListeners();
    } else if (_unlockedExpirations.isNotEmpty) {
      // Still have active timers, keep UI updated for the countdown
      notifyListeners();
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

  void _updateDailyVerse(String date) async {
    if (_quranData.isEmpty) return;

    final random = DateTime.now().millisecondsSinceEpoch;
    final int surahIdx = (random % _quranData.length).abs();
    final surah = _quranData[surahIdx];
    final ayahs = surah['ayahs'] as List;
    final int ayahIdx = (random % ayahs.length).abs();
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
  }

  static List<dynamic> _decodeJson(String source) {
    return json.decode(source) as List<dynamic>;
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    _hasSelectedLanguage = true;
    await prefs.setString('languageCode', code);
    await prefs.setBool('hasSelectedLanguage', true);
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

  Future<void> deductPoints(int amount) async {
    if (_points >= amount) {
      _points -= amount;
      await prefs.setInt('points', _points);
      notifyListeners();
    }
  }

  Future<void> toggleAppBlockedStatus(String packageName, {int? category}) async {
    final pkg = packageName.toLowerCase();
    // Strict Mode: Only allow blocking, not unblocking manually
    if (!_blockedApps.contains(pkg)) {
      _blockedApps.add(pkg);
      await prefs.setStringList('blockedApps', _blockedApps.toList());
      // Sync with Native Service
      await _appBlockService.setBlockedApps(_blockedApps.toList());
      notifyListeners();
    }
  }

  Future<void> openApp(String packageName) async {
    final pkg = packageName.toLowerCase();
    const appsChannel = MethodChannel('com.muslimlauncher/apps');
    try {
      await appsChannel.invokeMethod('openApp', {'packageName': pkg});
    } catch (e) {
      debugPrint("Failed to open app $pkg: $e");
    }
  }

  // Pre-defined sets for better performance during sync
  static const Set<String> _nonProductiveKeywords = {
    'game', 'social', 'video', 'player', 'tiktok', 'instagram', 'facebook', 
    'twitter', 'netflix', 'disney', 'mobile.legend', 'freefire', 'pubg', 'genshin',
    'youtube', 'vimeo', 'hulu', 'twitch', 'discord', 'telegram', 'snapchat', 
    'reddit', 'pinterest', 'linkedin', 'arcade', 'puzzle', 'racing', 'simulation',
    'entertainment', 'shotcut', 'capcut', 'snackvideo', 'kwaiviral', 'wattpad'
  };

  static const Set<String> _whitelist = {
    'com.whatsapp', 'com.whatsapp.w4b', 'com.android.chrome', 
    'com.google.android.gm', 'com.android.settings', 'com.android.vending',
    'com.google.android.apps.messaging', 'com.android.mms', 'com.samsung.android.messaging',
    'com.google.android.contacts', 'com.android.contacts'
  };

  /// Automatically blocks apps based on categories
  Future<void> syncAppsWithCategories(List<dynamic> apps) async {

    bool changed = false;
    for (var app in apps) {
      if (app == null) continue;
      final pkg = (app['packageName'] as String? ?? '').toLowerCase();
      final name = (app['appName'] as String? ?? '').toLowerCase();
      final cat = app['category'] as int? ?? -1;
      
      if (pkg.isEmpty || _whitelist.any((w) => pkg.contains(w) || pkg == w)) {
        // Ensure whitelisted apps are NOT blocked
        if (_blockedApps.contains(pkg)) {
          _blockedApps.remove(pkg);
          changed = true;
        }
        continue;
      }

      // Check category: 0: Game, 1: Audio, 2: Video, 4: Social
      bool isNonProductive = (cat == 0 || cat == 1 || cat == 2 || cat == 4);
      
      if (!isNonProductive) {
        isNonProductive = _nonProductiveKeywords.any((k) => pkg.contains(k) || name.contains(k));
      }

      if (isNonProductive && !_blockedApps.contains(pkg)) {
        _blockedApps.add(pkg);
        changed = true;
      }
    }

    if (changed) {
      await prefs.setStringList('blockedApps', _blockedApps.toList());
      await _appBlockService.setBlockedApps(_blockedApps.toList());
      notifyListeners();
    }
  }

  void clearBlockedApp() {
    _lastAttemptedBlockedPackage = null;
    notifyListeners();
  }

  Future<bool> allowAppTemporarily(String packageName, {int durationMinutes = 60}) async {
    final pkg = packageName.toLowerCase();
    final expiry = DateTime.now().millisecondsSinceEpoch + (durationMinutes * 60 * 1000);
    
    _unlockedExpirations[pkg] = expiry;
    bool success = true;
    
    try {
      await _appBlockService.allowAppTemporarily(pkg, durationMinutes: durationMinutes);
      await prefs.setString('unlockedExpirations', json.encode(_unlockedExpirations));
    } catch (e) {
      _unlockedExpirations.remove(pkg); // Rollback locally if native fails
      success = false;
    }
    
    notifyListeners();
    return success;
  }

  int getUnlockRemainingMinutes(String packageName) {
    final pkg = packageName.toLowerCase();
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
      // Surah 114 (index 113) is An-Nas
      if (surahIndex == 113) {
        final lastSurah = _quranData[113];
        final totalAyahs = lastSurah['total_ayah'] as int;
        if (ayahIndex == totalAyahs - 1) {
          // KHATM ACHIEVED!
          _khatmCount++;
          await prefs.setInt('khatmCount', _khatmCount);
          
          // Reset progress for new cycle
          _highestSurahIndex = 0;
          _highestAyahIndex = -1;
          await prefs.setInt('highestSurahIndex', 0);
          await prefs.setInt('highestAyahIndex', -1);
        }
      }
    }

    // Always add to history regardless of sequential progress
    _addToHistory(surahName, ayahNumber, pointsEarned);
    
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

  bool isAppBlocked(String packageName) {
    if (!_blockedApps.contains(packageName)) return false;
    
    // Check if temporarily allowed
    final expiry = _unlockedExpirations[packageName.toLowerCase()];
    if (expiry != null && DateTime.now().millisecondsSinceEpoch < expiry) {
      return false;
    }
    
    return true;
  }
}
