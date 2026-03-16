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
  int _points = 999999; // Load default high points for Dev
  List<String> _blockedApps = [];
  int _highestSurahIndex = 0;
  int _highestAyahIndex = -1; // -1 means no progress yet
  int _khatmCount = 0;
  List<Map<String, dynamic>> _readingHistory = [];
  String? _lastAttemptedBlockedPackage;
  bool _isAccessibilityEnabled = false;
  bool _hasSeenAccessibilitySetup = false;
  final AppBlockService _appBlockService = AppBlockService();
  Timer? _statusTimer;
  
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String _lastReadAyat = '';
  String _lastReadSurah = '';
  int _lastReadAyahNumber = 0;
  List<dynamic> _quranData = [];
  bool _isDataLoaded = false;


  String get languageCode => _languageCode;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get points => _points;
  List<String> get blockedApps => _blockedApps;
  String get lastReadAyat => _lastReadAyat;
  String get lastReadSurah => _lastReadSurah;
  int get lastReadAyahNumber => _lastReadAyahNumber;
  List<dynamic> get quranData => _quranData;
  bool get isDataLoaded => _isDataLoaded;
  int get khatmCount => _khatmCount;
  List<Map<String, dynamic>> get readingHistory => _readingHistory;
  String? get lastAttemptedBlockedPackage => _lastAttemptedBlockedPackage;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get hasSeenAccessibilitySetup => _hasSeenAccessibilitySetup;
  AppBlockService get appBlockService => _appBlockService;

  void _init() {
    _languageCode = prefs.getString('languageCode') ?? 'id';
    _hasSelectedLanguage = prefs.getBool('hasSelectedLanguage') ?? false;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _points = prefs.getInt('points') ?? 999999;
    _blockedApps = (prefs.getStringList('blockedApps') ?? []).toList();
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

    loadQuranData();
    
    // Initialize App Block Service
    _appBlockService.init(onAppBlocked: (pkg) {
      if (pkg.trim().isNotEmpty) {
        _lastAttemptedBlockedPackage = pkg.toLowerCase();
        notifyListeners();
      }
    });
    _appBlockService.setBlockedApps(_blockedApps);
    
    _startStatusTimer();
    
    notifyListeners();
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final enabled = await _appBlockService.isAccessibilityEnabled();
      if (enabled != _isAccessibilityEnabled) {
        _isAccessibilityEnabled = enabled;
        notifyListeners();
      }
    });
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
      await prefs.setStringList('blockedApps', _blockedApps);
      // Sync with Native Service
      await _appBlockService.setBlockedApps(_blockedApps);
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

  /// Automatically blocks apps based on categories
  Future<void> syncAppsWithCategories(List<dynamic> apps) async {
    bool changed = false;
    
    // Comprehensive non-productive keywords for package names
    final nonProductiveKeywords = [
      'game', 'social', 'video', 'player', 'tiktok', 'instagram', 'facebook', 
      'twitter', 'netflix', 'disney', 'mobile.legend', 'freefire', 'pubg', 'genshin',
      'youtube', 'vimeo', 'hulu', 'twitch', 'discord', 'telegram', 'snapchat', 
      'reddit', 'pinterest', 'linkedin', 'arcade', 'puzzle', 'racing', 'simulation',
      'entertainment', 'shotcut', 'capcut', 'snackvideo', 'kwaiviral', 'wattpad'
    ];

    debugPrint('Syncing categories for ${apps.length} apps...');

    for (var app in apps) {
      if (app == null) continue;
      final pkg = (app['packageName'] as String? ?? '').toLowerCase();
      final name = (app['appName'] as String? ?? '').toLowerCase();
      final cat = app['category'] as int? ?? -1;
      
      if (pkg.isEmpty) continue;

      // 1. Check by Official Category
      // Category 0: Game, 1: Audio, 2: Video, 4: Social
      bool isNonProductive = (cat == 0 || cat == 1 || cat == 2 || cat == 4);
      
      // 2. Check by Package Name or App Name Keywords
      if (!isNonProductive) {
        for (var keyword in nonProductiveKeywords) {
          if (pkg.contains(keyword) || name.contains(keyword)) {
            isNonProductive = true;
            break;
          }
        }
      }

      // 3. Exception Whitelist - CRITICAL: Never block launcher or core tools
      if (pkg == 'com.whatsapp' || pkg == 'com.whatsapp.w4b' || 
          pkg == 'com.android.chrome' || pkg == 'com.google.android.gm' ||
          pkg.contains('com.muslimlauncher') || 
          pkg.contains('com.android.settings') ||
          pkg.contains('com.android.vending')) { // Keep Play Store open for updates/installs
        isNonProductive = false;
      }

      if (isNonProductive) {
        if (!_blockedApps.contains(pkg)) {
          _blockedApps.add(pkg);
          changed = true;
          debugPrint('AUTO-BLOCKED: $name ($pkg) | Category: $cat');
        }
      }
    }

    if (changed) {
      await prefs.setStringList('blockedApps', _blockedApps);
      await _appBlockService.setBlockedApps(_blockedApps);
      notifyListeners();
      debugPrint('Sync complete. Total blocked apps: ${_blockedApps.length}');
    }
  }

  void clearBlockedApp() {
    _lastAttemptedBlockedPackage = null;
    notifyListeners();
  }

  Future<void> setHasSeenAccessibilitySetup(bool value) async {
    _hasSeenAccessibilitySetup = value;
    await prefs.setBool('hasSeenAccessibilitySetup', value);
    notifyListeners();
  }

  Future<void> setLastReadAyat(String ayat) async {
    _lastReadAyat = ayat;
    await prefs.setString('lastReadAyat', ayat);
    notifyListeners();
  }

  int get currentSurahIndex => prefs.getInt('currentSurahIndex') ?? 0;
  int get currentAyahIndex => prefs.getInt('currentAyahIndex') ?? 0;

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
    return _blockedApps.contains(packageName);
  }
}

