import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;

  AppState(this.prefs) {
    _init();
  }

  String _languageCode = 'id';
  bool _hasSelectedLanguage = false;
  bool _hasCompletedOnboarding = false;
  int _points = 0;
  List<String> _blockedApps = [];
  int _highestSurahIndex = 0;
  int _highestAyahIndex = -1; // -1 means no progress yet
  int _khatmCount = 0;
  List<Map<String, dynamic>> _readingHistory = [];

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

  void _init() {
    _languageCode = prefs.getString('languageCode') ?? 'id';
    _hasSelectedLanguage = prefs.getBool('hasSelectedLanguage') ?? false;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _points = prefs.getInt('points') ?? 0;
    _blockedApps = (prefs.getStringList('blockedApps') ?? []).toList();
    _lastReadAyat = prefs.getString('lastReadAyat') ?? '';
    _lastReadSurah = prefs.getString('lastReadSurah') ?? '';
    _lastReadAyahNumber = prefs.getInt('lastReadAyahNumber') ?? 0;
    
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
    notifyListeners();
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

  Future<void> toggleAppBlockedStatus(String packageName) async {
    if (_blockedApps.contains(packageName)) {
      _blockedApps.remove(packageName);
    } else {
      _blockedApps.add(packageName);
    }
    await prefs.setStringList('blockedApps', _blockedApps);
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
    _addToHistory(surahName, ayahNumber);
    
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

  void _addToHistory(String surahName, int ayahNumber) {
    final entry = {
      'surah': surahName,
      'ayah': ayahNumber,
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

