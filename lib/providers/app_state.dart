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

  void _init() {
    _languageCode = prefs.getString('languageCode') ?? 'id';
    _hasSelectedLanguage = prefs.getBool('hasSelectedLanguage') ?? false;
    _hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;
    _points = prefs.getInt('points') ?? 0;
    _blockedApps = prefs.getStringList('blockedApps') ?? [];
    _lastReadAyat = prefs.getString('lastReadAyat') ?? '';
    _lastReadSurah = prefs.getString('lastReadSurah') ?? '';
    _lastReadAyahNumber = prefs.getInt('lastReadAyahNumber') ?? 0;

    // Trigger heavy loading in background
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
      debugPrint("Error loading central Quran data: $e");
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
    await prefs.setInt('currentSurahIndex', surahIndex);
    await prefs.setInt('currentAyahIndex', ayahIndex);

    _lastReadSurah = surahName;
    _lastReadAyahNumber = ayahNumber;
    await prefs.setString('lastReadSurah', surahName);
    await prefs.setInt('lastReadAyahNumber', ayahNumber);

    notifyListeners();
  }

  bool isAppBlocked(String packageName) {
    return _blockedApps.contains(packageName);
  }
}
