import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../providers/app_state.dart';
import 'quran_tajweed_text.dart';
import 'surah_list_screen.dart';
import '../../utils/page_transitions.dart';
import '../../services/eye_tracker_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/translations.dart';
import '../../utils/quran_progress_helper.dart';
import '../../utils/sunnah_mission_helper.dart';

enum EyeReadingPhase { arabic, translation }

class SurahDetailScreen extends StatefulWidget {
  final Map<String, dynamic> surah;
  final int? initialAyahIndex;

  const SurahDetailScreen({
    super.key,
    required this.surah,
    this.initialAyahIndex,
  });

  static String getEyeTrackingText(
    String lang, {
    required bool isFocused,
    EyeReadingPhase phase = EyeReadingPhase.arabic,
    int dotCount = 1,
  }) =>
      _SurahDetailScreenState.getEyeTrackingText(
        lang,
        isFocused: isFocused,
        phase: phase,
        dotCount: dotCount,
      );

  static double calculateAccurateArabicSeconds(String arabic) =>
      _SurahDetailScreenState.calculateAccurateArabicSeconds(arabic);

  static double calculateAccurateTranslationSeconds(String? translation) =>
      _SurahDetailScreenState.calculateAccurateTranslationSeconds(translation);

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen>
    with WidgetsBindingObserver {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int? _recordingAyahIdx;
  String _recognizedText = "";
  String _cumulativeRecognizedText = "";
  String _currentSessionText = "";
  String _targetArabicText = "";
  DateTime? _readingStartTime;
  int _lastMatchedWordCount = 0;
  Timer? _inactivityTimer;
  bool _isMicReady = false;
  final ValueNotifier<int> _currentVisibleAyah = ValueNotifier<int>(1);
  final ValueNotifier<int?> _stickyAyahIndex = ValueNotifier<int?>(null);
  bool _suppressLongAyahVoiceWarningForSurah = false;

  // Eye Focus Mode
  final EyeTrackerService _eyeTrackerService = EyeTrackerService();
  int? _eyeReadingAyahIdx;
  double _eyeReadingProgress = 0.0;
  bool _isEyeFocused = false;
  EyeReadingPhase _eyeReadingPhase = EyeReadingPhase.arabic;
  int _eyeDotCount = 1;
  int _eyeDotTicks = 0;
  double _targetArabicSeconds = 0.0;
  double _targetTranslationSeconds = 0.0;
  double _elapsedFocusedSeconds = 0.0;
  bool _hasTriggeredPhaseTransitionHaptic = false;
  Timer? _eyeTimer;
  Timer? _vibrationTimer;
  StreamSubscription? _eyeFocusSubscription;
  bool _isInitializing = false;
  bool _isDisposed = false;

  // Spiritual Energy Session Tracking
  late AppState _appState;
  double? _sessionStartProgress;
  int _sessionAyahsCount = 0;

  bool _isLongAyah(String arabic) {
    final clean = arabic.replaceAll(RegExp(r'\[[a-zA-Z0-9:]*\[|\]'), '');
    final words = clean
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return words >= 18 || clean.trim().length >= 130;
  }

  int _getWordCount(String arabic) {
    final clean = arabic.replaceAll(RegExp(r'\[[a-zA-Z0-9:]*\[|\]'), '');
    return clean.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void _onAyahMicPressed(int index, String arabic) async {
    if (_recordingAyahIdx == index) {
      _stopListening();
      return;
    }

    final lang = Provider.of<AppState>(context, listen: false).languageCode;
    if (_isLongAyah(arabic) && !_suppressLongAyahVoiceWarningForSurah) {
      _showLongAyahVoiceSuggestionModal(
        context: context,
        ayahIndex: index,
        arabic: arabic,
        lang: lang,
      );
      return;
    }

    _startListeningForAyah(index, arabic);
  }

  void _startListeningForAyah(int index, String arabic) {
    _stopListening(); // Make sure previous is stopped properly

    _lastMatchedWordCount = 0;
    setState(() {
      _isInitializing = true;
      _isMicReady = false;
      _recordingAyahIdx = index;
      _recognizedText = "";
      _cumulativeRecognizedText = "";
      _currentSessionText = "";
      _targetArabicText = arabic;
    });

    _startListeningSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = Provider.of<AppState>(context, listen: false);
    _sessionStartProgress ??= QuranProgressHelper.getCombinedSpiritualProgress(
      khatmCount: _appState.khatmCount,
      currentSurahIndex: _appState.currentSurahIndex,
      currentAyahNumber: _appState.lastReadAyahNumber,
      quranData: _appState.quranData,
      totalDzikirCount: _appState.totalDzikirCount,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);

    // Auto-scroll to initial ayah if provided
    if (widget.initialAyahIndex != null) {
      final totalAyahs = (widget.surah['ayahs'] as List?)?.length ?? 0;
      final safeIndex = totalAyahs > 0
          ? math.max(0, math.min(widget.initialAyahIndex!, totalAyahs - 1))
          : 0;
      _currentVisibleAyah.value = safeIndex + 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _itemScrollController.isAttached) {
          _itemScrollController.jumpTo(index: safeIndex);
        }
      });
    }
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onError: (val) {
          if (mounted) {
            if (_recordingAyahIdx != null && !_isDisposed) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _recordingAyahIdx != null && !_isDisposed) {
                  _startListeningSession();
                }
              });
            } else {
              setState(() {
                _recordingAyahIdx = null;
                _isMicReady = false;
              });
            }
          }
        },
        onStatus: (val) {
          if (val == 'listening') {
            if (mounted && _recordingAyahIdx != null && !_isDisposed) {
              HapticFeedback.selectionClick();
              setState(() {
                _isMicReady = true;
                _isInitializing = false;
              });
              _readingStartTime ??= DateTime.now();
              _resetInactivityTimer();
            }
          } else if (val == 'done' || val == 'notListening') {
            if (mounted && _recordingAyahIdx != null && !_isDisposed) {
              setState(() => _isMicReady = false);
              _cumulativeRecognizedText =
                  "$_cumulativeRecognizedText $_currentSessionText".trim();
              _currentSessionText = "";
              _recognizedText = _cumulativeRecognizedText;

              // Check if reading is complete before restarting session
              if (_checkMatch(
                _recognizedText,
                _targetArabicText,
                isFinalEvaluation: true,
              )) {
                _onSuccess(_recordingAyahIdx!, _targetArabicText);
                _stopListening();
                return;
              }

              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _recordingAyahIdx != null && !_isDisposed) {
                  _startListeningSession();
                }
              });
            }
          }
        },
      );
      if (!mounted) return;
    } catch (e) {
      debugPrint("Speech init error: $e");
    }
  }

  void _startListeningSession() async {
    try {
      if (!_speech.isAvailable) {
        final available = await _speech.initialize();
        if (!available) {
          if (mounted) {
            setState(() {
              _isInitializing = false;
              _isMicReady = false;
            });
          }
          return;
        }
      }

      if (mounted && !_isDisposed && _recordingAyahIdx != null) {
        await _speech.listen(
          onResult: (val) {
            if (mounted && !_isDisposed && _recordingAyahIdx != null) {
              setState(() {
                _currentSessionText = val.recognizedWords;
                _recognizedText =
                    "$_cumulativeRecognizedText $_currentSessionText".trim();

                final metrics = _calculateMatchMetrics(
                  _recognizedText,
                  _targetArabicText,
                );

                // If user reached the end of the ayah, complete quickly (1.5s silence).
                // If still mid-reading, give 8s breathing room.
                _resetInactivityTimer(hasReachedEnd: metrics.isEndWordMatched);

                if (metrics.matchCount > _lastMatchedWordCount) {
                  _lastMatchedWordCount = metrics.matchCount;
                }

                if (_checkMatch(_recognizedText, _targetArabicText)) {
                  _onSuccess(_recordingAyahIdx!, _targetArabicText);
                  _stopListening();
                }
              });
            }
          },
          localeId: 'ar_SA',
          pauseFor: const Duration(
            seconds: 4,
          ), // Natural pause allowance for native speech engine
        );

        if (mounted && _speech.isListening && !_isMicReady) {
          HapticFeedback.selectionClick();
          setState(() {
            _isMicReady = true;
            _isInitializing = false;
          });
          _readingStartTime ??= DateTime.now();
          _resetInactivityTimer(hasReachedEnd: false);
        }
      }
    } finally {
      if (mounted && !_isDisposed && !_speech.isListening) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _resetInactivityTimer({bool hasReachedEnd = false}) {
    _inactivityTimer?.cancel();
    final duration = hasReachedEnd
        ? const Duration(milliseconds: 1500)
        : const Duration(seconds: 8);
    _inactivityTimer = Timer(duration, () {
      _evaluateOnTimeout();
    });
  }

  void _evaluateOnTimeout() {
    if (!mounted || _isDisposed || _recordingAyahIdx == null) return;

    if (_checkMatch(
      _recognizedText,
      _targetArabicText,
      isFinalEvaluation: true,
    )) {
      _onSuccess(_recordingAyahIdx!, _targetArabicText);
      _stopListening();
    } else {
      // Reading incomplete or ambient noise after user stopped
      final currentAyah = _recordingAyahIdx;
      _stopListening();

      if (mounted && currentAyah != null) {
        final lang = Provider.of<AppState>(context, listen: false).languageCode;
        final bool hadVoice = _recognizedText.trim().isNotEmpty;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hadVoice
                        ? (lang == 'en'
                              ? "Recitation incomplete. Please recite until the end of the verse."
                              : "Bacaan belum lengkap. Silakan baca hingga akhir ayat.")
                        : (lang == 'en'
                              ? "No voice detected. Please try again."
                              : "Suara belum terdeteksi. Silakan coba lagi."),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blueGrey.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _normalizeArabicText(String text) {
    if (text.isEmpty) return text;

    // 1. Strip Tajweed tags if present e.g. [h:13[ٱ] or [l[ل] or [s[و][n[ٲ]ةَ
    String clean = text.replaceAll(RegExp(r'\[[a-zA-Z0-9:]*\[|\]'), '');

    // 2. Remove Tashkeel, Quranic diacritics, Tatweel (ـ / \u0640), and Dagger Alif (\u0670)
    clean = clean.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'),
      '',
    );

    // 3. Normalize all forms of Alif to standard bare Alif (ا - \u0627)
    // Includes: \u0671 (Alef Wasla ٱ), \u0672 (ٲ), \u0673 (ٳ), \u0622 (آ), \u0623 (أ), \u0625 (إ)
    clean = clean.replaceAll(RegExp(r'[أإآٱٲٳ]'), 'ا');

    // 4. Normalize Ta Marbuta (ة) to Ha (ه)
    clean = clean.replaceAll('ة', 'ه');

    // 5. Normalize Alif Maqsura (ى) to Ya (ي)
    clean = clean.replaceAll('ى', 'ي');

    // 6. Normalize Rasm Utsmani words with silent Waw / special spellings to modern standard
    clean = clean.replaceAll(RegExp(r'صل[واه]+ه'), 'صلاه'); // الصلاة / الصلوة
    clean = clean.replaceAll(RegExp(r'زك[واه]+ه'), 'زكاه'); // الزكاة / الزكوة
    clean = clean.replaceAll(RegExp(r'حي[واه]+ه'), 'حياه'); // الحياة / الحيوة
    clean = clean.replaceAll(RegExp(r'مشك[واه]+ه'), 'مشكاه'); // مشكاة
    clean = clean.replaceAll(RegExp(r'رب[واه]+[ا]?'), 'ربا'); // الربا

    // 7. Remove any non-Arabic letters or punctuation, keeping only Arabic letters and whitespace
    clean = clean.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '');

    return clean.trim();
  }

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  bool _isWordMatch(String targetWord, String recWord) {
    if (targetWord == recWord) return true;
    if (targetWord.isEmpty || recWord.isEmpty) return false;

    // Substring containment for words >= 3 chars
    if (targetWord.length >= 3 && recWord.length >= 3) {
      if (targetWord.contains(recWord) || recWord.contains(targetWord)) {
        return true;
      }
    }

    // Levenshtein fuzzy match (handles STT phonetic misrecognitions like ويوكمون vs ويقيمون)
    final distance = _levenshteinDistance(targetWord, recWord);
    if (targetWord.length <= 4) {
      return distance <= 1;
    } else {
      final maxLen = targetWord.length > recWord.length
          ? targetWord.length
          : recWord.length;
      final similarity = 1.0 - (distance / maxLen);
      return distance <= 2 || similarity >= 0.65;
    }
  }

  ({
    int matchCount,
    int totalWords,
    double matchPercentage,
    bool isStartWordMatched,
    bool isEndWordMatched,
    int firstMatchedTargetIndex,
    int lastMatchedTargetIndex,
  })
  _calculateMatchMetrics(String recognized, String target) {
    if (recognized.trim().isEmpty || target.trim().isEmpty) {
      return (
        matchCount: 0,
        totalWords: 0,
        matchPercentage: 0.0,
        isStartWordMatched: false,
        isEndWordMatched: false,
        firstMatchedTargetIndex: -1,
        lastMatchedTargetIndex: -1,
      );
    }

    final normRecognized = _normalizeArabicText(recognized);
    final normTarget = _normalizeArabicText(target);

    final recWords = normRecognized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final targetWords = normTarget
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (targetWords.isEmpty) {
      return (
        matchCount: 0,
        totalWords: 0,
        matchPercentage: 0.0,
        isStartWordMatched: false,
        isEndWordMatched: false,
        firstMatchedTargetIndex: -1,
        lastMatchedTargetIndex: -1,
      );
    }

    int matchCount = 0;
    int firstMatchedTargetIndex = -1;
    int lastMatchedTargetIndex = -1;
    List<String> remainingRecWords = List.from(recWords);

    for (int tIdx = 0; tIdx < targetWords.length; tIdx++) {
      final tWord = targetWords[tIdx];
      int foundIdx = -1;

      for (int rIdx = 0; rIdx < remainingRecWords.length; rIdx++) {
        if (_isWordMatch(tWord, remainingRecWords[rIdx])) {
          foundIdx = rIdx;
          break;
        }
      }

      if (foundIdx != -1) {
        matchCount++;
        if (firstMatchedTargetIndex == -1) {
          firstMatchedTargetIndex = tIdx;
        }
        lastMatchedTargetIndex = tIdx;
        remainingRecWords.removeAt(foundIdx);
      }
    }

    final double matchPercentage = matchCount / targetWords.length;

    // Start anchor: user must match a word in the first ~35% of the ayah
    final int startThresholdIndex = targetWords.length <= 3
        ? (targetWords.length == 1 ? 0 : 1)
        : (targetWords.length <= 6 ? 1 : (targetWords.length * 0.35).floor());

    // End threshold: user must reach into the final segment of the ayah (last 2-3 words)
    // ensuring the user actually recited through to the end of the verse.
    final int endThresholdIndex = targetWords.length <= 3
        ? (targetWords.length == 1 ? 0 : 1)
        : (targetWords.length <= 6
              ? targetWords.length - 2
              : (targetWords.length * 0.75).floor().clamp(
                  0,
                  targetWords.length - 2,
                ));

    final bool isStartWordMatched =
        firstMatchedTargetIndex != -1 &&
        firstMatchedTargetIndex <= startThresholdIndex;
    final bool isEndWordMatched =
        lastMatchedTargetIndex != -1 &&
        lastMatchedTargetIndex >= endThresholdIndex;

    return (
      matchCount: matchCount,
      totalWords: targetWords.length,
      matchPercentage: matchPercentage,
      isStartWordMatched: isStartWordMatched,
      isEndWordMatched: isEndWordMatched,
      firstMatchedTargetIndex: firstMatchedTargetIndex,
      lastMatchedTargetIndex: lastMatchedTargetIndex,
    );
  }

  bool _checkMatch(
    String recognized,
    String target, {
    bool isFinalEvaluation = false,
  }) {
    final metrics = _calculateMatchMetrics(recognized, target);
    if (metrics.totalWords == 0) return false;

    // Minimum reading duration benchmark (anti-cheat against instant completion):
    // Fastest human recitation is ~0.30s per word, minimum 1.0s.
    final minDurationSeconds = (metrics.totalWords * 0.30).clamp(1.0, 120.0);
    final elapsedSeconds = _readingStartTime != null
        ? DateTime.now().difference(_readingStartTime!).inMilliseconds / 1000.0
        : 0.0;

    // Guard against completing too early
    if (elapsedSeconds < minDurationSeconds) {
      return false;
    }

    // For very short ayahs (<= 3 words)
    if (metrics.totalWords <= 3) {
      final requiredWords = metrics.totalWords == 1 ? 1 : 2;
      return metrics.matchCount >= requiredWords && metrics.isEndWordMatched;
    }

    // Proportional word density requirement: ~40% of words (e.g. 4 words out of 8)
    // Prevents cheating by reciting only the first word and the last word.
    final requiredMatches = (metrics.totalWords * 0.40).ceil().clamp(
      2,
      metrics.totalWords,
    );

    // Multi-Layer Anti-Gaming Verification:
    // 1. Density: user recited enough words across the verse (>= requiredMatches)
    // 2. Start Anchor: user started recitation from the beginning segment (isStartWordMatched)
    // 3. End Anchor: user recited through to the end segment (isEndWordMatched)
    // 4. Time: elapsed time >= min duration benchmark
    return metrics.matchCount >= requiredMatches &&
        metrics.isStartWordMatched &&
        metrics.isEndWordMatched;
  }

  void _stopListening({bool isDisposing = false}) {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _lastMatchedWordCount = 0;
    _isMicReady = false;
    _isInitializing = false;
    if (!isDisposing && mounted) {
      setState(() {
        _recordingAyahIdx = null;
        _cumulativeRecognizedText = "";
        _currentSessionText = "";
        _targetArabicText = "";
      });
    }
    _speech.stop();
  }

  void _onEyeReadingPressed(
    int index,
    String arabic, {
    String? translation,
  }) async {
    // If clicking the same one, just stop
    if (_eyeReadingAyahIdx == index) {
      _stopEyeReading();
      return;
    }

    // If another one was active, stop it first to release camera
    if (_eyeReadingAyahIdx != null) {
      _stopEyeReading();
    }

    // Stop microphone if active
    _stopListening();

    // Request permission
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status != PermissionStatus.granted) {
      final lang = Provider.of<AppState>(context, listen: false).languageCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'en'
                ? "Camera permission is required for eye tracking"
                : "Izin kamera diperlukan untuk deteksi mata",
          ),
        ),
      );
      return;
    }

    _targetArabicSeconds = calculateAccurateArabicSeconds(arabic);
    _targetTranslationSeconds = calculateAccurateTranslationSeconds(translation);

    _readingStartTime = DateTime.now();
    setState(() {
      _isInitializing = true;
      _eyeReadingAyahIdx = index;
      _eyeReadingProgress = 0.0;
      _isEyeFocused = false;
      _eyeReadingPhase = EyeReadingPhase.arabic;
      _eyeDotCount = 1;
      _eyeDotTicks = 0;
      _elapsedFocusedSeconds = 0.0;
      _hasTriggeredPhaseTransitionHaptic = false;
    });

    try {
      await _eyeTrackerService.initialize();
      if (!mounted || _isDisposed) return;

      _eyeFocusSubscription = _eyeTrackerService.focusStream?.listen((focused) {
        if (!mounted || _isDisposed) return;
        setState(() => _isEyeFocused = focused);
        _handleEyeTimer(focused, arabic);
      });

      _handleEyeTimer(_eyeTrackerService.isFocused, arabic);
    } finally {
      if (mounted && !_isDisposed) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _handleEyeTimer(bool focused, String arabic) {
    _eyeTimer?.cancel();
    _eyeTimer = null;

    if (focused) {
      // Stop vibration if focused
      _vibrationTimer?.cancel();
      _vibrationTimer = null;

      if (_eyeReadingAyahIdx != null) {
        final totalSeconds = _targetArabicSeconds + _targetTranslationSeconds;

        _eyeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _eyeDotTicks++;
            if (_eyeDotTicks % 3 == 0) {
              _eyeDotCount = (_eyeDotCount % 3) + 1;
            }

            _elapsedFocusedSeconds += 0.1;

            if (_elapsedFocusedSeconds < _targetArabicSeconds ||
                _targetTranslationSeconds == 0.0) {
              _eyeReadingPhase = EyeReadingPhase.arabic;
            } else {
              if (!_hasTriggeredPhaseTransitionHaptic) {
                _hasTriggeredPhaseTransitionHaptic = true;
                HapticFeedback.lightImpact();
              }
              _eyeReadingPhase = EyeReadingPhase.translation;
            }

            _eyeReadingProgress = (totalSeconds > 0)
                ? (_elapsedFocusedSeconds / totalSeconds).clamp(0.0, 1.0)
                : 1.0;

            if (_eyeReadingProgress >= 1.0) {
              _eyeReadingProgress = 1.0;
              _eyeTimer?.cancel();
              _onSuccess(_eyeReadingAyahIdx!, arabic, method: 'eye_tracker');
              _stopEyeReading();
            }
          });
        });
      }
    } else {
      // Start repeating vibration if not focused and reading is active
      if (_eyeReadingAyahIdx != null && _vibrationTimer == null) {
        // Initial vibration
        HapticFeedback.vibrate();
        // Repeat every 1.0 second
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (
          timer,
        ) {
          HapticFeedback.vibrate();
        });
      }
    }
  }

  Future<void> _stopEyeReading({bool isDisposing = false}) async {
    _eyeTimer?.cancel();
    _eyeTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    await _eyeFocusSubscription?.cancel();
    _eyeFocusSubscription = null;

    await _eyeTrackerService.dispose();

    if (!isDisposing && mounted) {
      setState(() {
        _eyeReadingAyahIdx = null;
        _eyeReadingProgress = 0.0;
        _isEyeFocused = false;
        _eyeReadingPhase = EyeReadingPhase.arabic;
        _eyeDotCount = 1;
        _eyeDotTicks = 0;
        _elapsedFocusedSeconds = 0.0;
        _hasTriggeredPhaseTransitionHaptic = false;
      });
    }
  }

  Future<void> _onSuccess(
    int index,
    String arabic, {
    String method = 'voice',
  }) async {
    if (!mounted || _isDisposed) return;
    final appState = Provider.of<AppState>(context, listen: false);

    // Check if point should be awarded based on strict progression
    final int surahNumber = widget.surah['surah_number'];
    final bool getsPoints = appState.canEarnPoints(surahNumber - 1, index);

    int pointsEarned = 0;
    if (getsPoints) {
      // Rebalanced Base Ayah Economy with Maqam Point Boost + Daily 10-Ayahs Boost (+2 pts):
      // Level 1: 3 pts (long: 5 pts) [Daily Boost 10 ayat: 5-7 pts]
      // Level 2: 4 pts (long: 6 pts) [Daily Boost: 6-8 pts]
      // Level 3: 5 pts (long: 8 pts) [Daily Boost: 7-10 pts]
      // Level 4: 6 pts (long: 9 pts) [Daily Boost: 8-11 pts]
      // Level 5: 7 pts (long: 10 pts) [Daily Boost: 9-12 pts]
      pointsEarned = appState.calculateAndConsumeAyahPoints(arabic.length);
      appState.addPoints(pointsEarned);
      appState.setLastReadAyat(arabic);
    }

    _sessionAyahsCount++;

    // saveProgress handles history internally and only updates "Last Read" if it's new progress
    appState.saveProgress(
      surahNumber - 1,
      index,
      widget.surah['surah_name'],
      index + 1,
      pointsEarned,
    );

    final durationSeconds = _readingStartTime != null
        ? DateTime.now().difference(_readingStartTime!).inSeconds
        : 0;
    _readingStartTime = null;

    // Check if user completed the entire Surah (Milestone Progression)
    final totalAyahsInSurah = (widget.surah['ayahs'] as List).length;
    Map<String, dynamic>? milestoneResult;
    if (index == totalAyahsInSurah - 1 && getsPoints) {
      milestoneResult = await appState.completeSurahMilestone(
        surahNumber: surahNumber,
        surahName:
            widget.surah['surah_name'] as String? ?? 'Surah $surahNumber',
        totalAyahs: totalAyahsInSurah,
        readingDurationSeconds: durationSeconds,
      );
    }

    // Check Prophet's Sunnah missions (independent of khatam progression, with anti-gaming 1x cap)
    final now = SunnahMissionHelper.debugSimulatedTime ?? DateTime.now();
    Map<String, dynamic>? sunnahResult;

    // Track read ayah for active Sunnah mission (enables installment reading markers)
    final activeSunnah = SunnahMissionHelper.getActiveMissionForAyah(
      surahNumber,
      index + 1,
      now,
    );
    if (activeSunnah != null) {
      await appState.recordSunnahAyahRead(activeSunnah.id, index + 1, now);
    }
    if (SunnahMissionHelper.isFajrActive(now)) {
      await appState.recordSunnahAyahRead('quran_fajar', index + 1, now);
    }

    final kahfCount = appState.getSunnahProgressCount('alkahf_jumat', now);
    final mulkCount = appState.getSunnahProgressCount('almulk_malam', now);
    final baqarahAyahs = appState.getSunnahReadAyahs(
      'albaqarah_akhir_malam',
      now,
    );
    final fajrCount = appState.getSunnahProgressCount('quran_fajar', now);

    // 1. Friday Kahf (Surah 18, finished or 110 ayahs completed in installments)
    if (surahNumber == 18 &&
        (index == totalAyahsInSurah - 1 || kahfCount >= 110) &&
        SunnahMissionHelper.isFridayKahfActive(now) &&
        !appState.isSunnahMissionCompletedToday('alkahf_jumat', now)) {
      sunnahResult = await appState.completeSunnahMission(
        missionId: 'alkahf_jumat',
        missionTitle: SunnahMissionHelper.fridayKahf.getTitle(
          appState.languageCode,
        ),
        pointsReward: SunnahMissionHelper.fridayKahf.pointsReward,
        dateTime: now,
      );
    }
    // 2. Night Al-Mulk (Surah 67, finished or 30 ayahs completed in installments)
    else if (surahNumber == 67 &&
        (index == totalAyahsInSurah - 1 || mulkCount >= 30) &&
        SunnahMissionHelper.isNightActive(now) &&
        !appState.isSunnahMissionCompletedToday('almulk_malam', now)) {
      sunnahResult = await appState.completeSunnahMission(
        missionId: 'almulk_malam',
        missionTitle: SunnahMissionHelper.nightMulk.getTitle(
          appState.languageCode,
        ),
        pointsReward: SunnahMissionHelper.nightMulk.pointsReward,
        dateTime: now,
      );
    }
    // 3. Night Ayat Kursi (Surah 2, Ayah 255)
    else if (surahNumber == 2 &&
        (index + 1) == 255 &&
        SunnahMissionHelper.isNightActive(now) &&
        !appState.isSunnahMissionCompletedToday('ayat_kursi_malam', now)) {
      sunnahResult = await appState.completeSunnahMission(
        missionId: 'ayat_kursi_malam',
        missionTitle: SunnahMissionHelper.nightAyatKursi.getTitle(
          appState.languageCode,
        ),
        pointsReward: SunnahMissionHelper.nightAyatKursi.pointsReward,
        dateTime: now,
      );
    }
    // 4. Night Last 2 Verses of Al-Baqarah (Surah 2, Ayah 286 completing 285-286)
    else if (surahNumber == 2 &&
        ((index + 1) == 286 ||
            (baqarahAyahs.contains(285) && baqarahAyahs.contains(286))) &&
        SunnahMissionHelper.isNightActive(now) &&
        !appState.isSunnahMissionCompletedToday('albaqarah_akhir_malam', now)) {
      sunnahResult = await appState.completeSunnahMission(
        missionId: 'albaqarah_akhir_malam',
        missionTitle: SunnahMissionHelper.nightBaqarahEnd.getTitle(
          appState.languageCode,
        ),
        pointsReward: SunnahMissionHelper.nightBaqarahEnd.pointsReward,
        dateTime: now,
      );
    }
    // 5. Fajr Reading (Subuh window, reading finished or at least 3 ayahs recited in this session)
    else if (SunnahMissionHelper.isFajrActive(now) &&
        (index == totalAyahsInSurah - 1 ||
            _sessionAyahsCount >= 3 ||
            fajrCount >= 3) &&
        !appState.isSunnahMissionCompletedToday('quran_fajar', now)) {
      sunnahResult = await appState.completeSunnahMission(
        missionId: 'quran_fajar',
        missionTitle: SunnahMissionHelper.fajrReading.getTitle(
          appState.languageCode,
        ),
        pointsReward: SunnahMissionHelper.fajrReading.pointsReward,
        dateTime: now,
      );
    }

    _stopListening();

    if (!mounted) return;

    // Show Sunnah Mission celebration SnackBar if earned
    if (sunnahResult != null && sunnahResult['isNewMilestone'] == true) {
      final int bonus = sunnahResult['pointsEarned'] as int? ?? 0;
      final String mTitle =
          sunnahResult['missionTitle'] as String? ??
          Translations.get(appState.languageCode, 'sunnah_mission_header');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      Translations.get(
                        appState.languageCode,
                        'sunnah_mission_completed_msg',
                      ).replaceAll('{pts}', '$bonus'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF065F46),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else if (milestoneResult != null &&
        milestoneResult['isNewMilestone'] == true) {
      final int bonus = milestoneResult['bonusPoints'] as int? ?? 10;
      final int tier = milestoneResult['tier'] as int? ?? 1;
      final int boostPercent = milestoneResult['boostPercent'] as int? ?? 0;
      final bool isKhatam = milestoneResult['isKhatam'] == true;

      if (isKhatam) {
        _showKhatmCelebration(context, appState.khatmCount);
      } else {
        final boostSuffix = boostPercent > 0
            ? ' ⚡ (+$boostPercent% Boost)'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Masha Allah! Selesai Surah (Tier $tier: +$bonus Poin Bonus$boostSuffix)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final int boostPercent = appState.maqamBoostPercent;
      final String boostLabel = (getsPoints && boostPercent > 0)
          ? " ⚡ (+$boostPercent%)"
          : "";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                getsPoints ? Icons.check_circle : Icons.history_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                getsPoints
                    ? "Masha Allah! +$pointsEarned Poin$boostLabel"
                    : "Riwayat Bacaan Tersimpan",
              ),
            ],
          ),
          backgroundColor: getsPoints
              ? Colors.teal.shade700
              : Colors.blueGrey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showKhatmCelebration(BuildContext context, int khatmCount) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.teal.shade900,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "MASHA ALLAH!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Anda telah menyelesaikan seluruh Al-Quran!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.teal.shade100, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Khatm ke-$khatmCount",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.teal.shade900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "ALHAMDULILLAH",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahs = widget.surah['ayahs'] as List<dynamic>;
    // Consumer/select used only for language in the root Scaffold
    final lang = context.select<AppState, String>((s) => s.languageCode);

    // Check progress
    final int surahIndex = widget.surah['surah_number'] - 1;
    final int surahNumber =
        widget.surah['surah_number'] as int? ?? (surahIndex + 1);

    final progress = context.select<AppState, (int, int)>(
      (s) => (s.highestSurahIndex, s.highestAyahIndex),
    );
    final highestSurahIdx = progress.$1;
    final highestAyahIdx = progress.$2;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _finalizeSpiritualEnergySession();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBackToSurahList,
          ),
          title: Text(widget.surah['surah_name']),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          scrolledUnderElevation: 2,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.format_list_numbered_rounded),
              tooltip: (lang == 'id' || lang == 'ms')
                  ? 'Navigasi Ayat'
                  : 'Jump to Ayah',
              onPressed: () =>
                  _showAyahNavigatorSheet(context, ayahs.length, lang),
            ),
            Selector<AppState, (int, int)>(
              selector: (_, s) => (s.points, s.khatmCount),
              builder: (_, values, child) =>
                  _PointsBadge(points: values.$1, khatmCount: values.$2),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            ScrollablePositionedList.builder(
              itemCount:
                  ayahs.length +
                  (highestSurahIdx >= surahIndex &&
                          highestAyahIdx == ayahs.length - 1 &&
                          surahIndex <
                              context.read<AppState>().quranData.length - 1
                      ? 1
                      : 0),
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              padding: EdgeInsets.only(
                top: 8,
                bottom: 96 + MediaQuery.of(context).padding.bottom,
              ),

              itemBuilder: (context, index) {
                if (index == ayahs.length) {
                  return Consumer<AppState>(
                    builder: (context, state, _) =>
                        _buildNextSurahButton(context, state, surahIndex),
                  );
                }

                final ayah = ayahs.isEmpty
                    ? null
                    : ayahs[index < 0 ? 0 : index];
                final isRecording = _recordingAyahIdx == index;

                return Selector<AppState, (bool, bool, bool, bool, bool)>(
                  selector: (_, state) {
                    final ayahNumberVal =
                        ayah?['ayah_number'] as int? ?? (index + 1);
                    final now =
                        SunnahMissionHelper.debugSimulatedTime ??
                        DateTime.now();
                    final activeMission =
                        SunnahMissionHelper.getActiveMissionForAyah(
                          surahNumber,
                          ayahNumberVal,
                          now,
                        );
                    bool isSunnahRead = false;
                    bool isSunnahLast = false;
                    if (activeMission != null) {
                      final isCompleted = state.isSunnahMissionCompletedToday(
                        activeMission.id,
                        now,
                      );
                      isSunnahRead =
                          isCompleted ||
                          state
                              .getSunnahReadAyahs(activeMission.id, now)
                              .contains(ayahNumberVal);
                      isSunnahLast =
                          !isCompleted &&
                          state.getSunnahLastReadAyah(activeMission.id, now) ==
                              ayahNumberVal;
                    }
                    return (
                      state.isAyahReached(surahIndex, index),
                      state.isNextAyah(surahIndex, index),
                      state.currentSurahIndex == surahIndex &&
                          index == state.currentAyahIndex,
                      isSunnahRead,
                      isSunnahLast,
                    );
                  },
                  builder: (context, values, child) {
                    final bool isDone = values.$1;
                    final bool isNext = values.$2;
                    final bool isLastReadAyah = values.$3;
                    final bool isSunnahAyahRead = values.$4;
                    final bool isSunnahLastRead = values.$5;
                    final bool isAyahReadDisplay = isDone || isSunnahAyahRead;
                    final bool isAyahLastReadDisplay =
                        isLastReadAyah || isSunnahLastRead;
                    final bool isFuture = !isAyahReadDisplay && !isNext;
                    final int? ayahNumber = ayah?['ayah_number'] as int?;
                    final bool isAlwaysActive =
                        SunnahMissionHelper.isAyahAlwaysActive(
                          surahNumber,
                          index,
                          null,
                          ayahNumber,
                        );

                    return RepaintBoundary(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isAyahReadDisplay
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.3,
                                )
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isAyahLastReadDisplay
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            width: isAyahLastReadDisplay ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Opacity(
                          opacity:
                              (isFuture &&
                                  !isNext &&
                                  !isRecording &&
                                  !isAlwaysActive)
                              ? 0.6
                              : 1.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Ayah Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isAyahReadDisplay
                                      ? colorScheme.primaryContainer.withValues(
                                          alpha: 0.5,
                                        )
                                      : colorScheme.surfaceContainerHigh,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(24),
                                    topRight: Radius.circular(24),
                                  ),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final textScale =
                                        MediaQuery.textScalerOf(
                                          context,
                                        ).scale(14) /
                                        14;
                                    final effectiveWidth =
                                        constraints.maxWidth /
                                        (textScale > 0 ? textScale : 1.0);
                                    final isCompact = effectiveWidth < 360;
                                    final hideActionLabels =
                                        effectiveWidth < 250;

                                    final String? headerLabel = isLastReadAyah
                                        ? _getLastReadLabel(lang)
                                        : (isSunnahLastRead
                                              ? _getSunnahLastReadLabel(lang)
                                              : (isSunnahAyahRead
                                                    ? _getSunnahReadLabel(lang)
                                                    : (isNext
                                                          ? _getReadWithLabel(
                                                              lang,
                                                            )
                                                          : null)));

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Left: Ayah Number Badge & Status Label
                                        Flexible(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSunnahLastRead
                                                      ? Colors.teal
                                                      : (isSunnahAyahRead
                                                            ? Colors
                                                                  .teal
                                                                  .shade100
                                                            : colorScheme
                                                                  .secondaryContainer),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  "${index + 1}",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isSunnahLastRead
                                                        ? Colors.white
                                                        : (isSunnahAyahRead
                                                              ? Colors
                                                                    .teal
                                                                    .shade900
                                                              : colorScheme
                                                                    .onSecondaryContainer),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (headerLabel != null) ...[
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    headerLabel,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          isAyahLastReadDisplay
                                                          ? colorScheme.primary
                                                          : (isSunnahAyahRead
                                                                ? Colors
                                                                      .teal
                                                                      .shade800
                                                                : colorScheme
                                                                      .onSurfaceVariant),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Right: Action Buttons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _MicButton(
                                              lang: lang,
                                              isRecording: isRecording,
                                              isInitializing:
                                                  isRecording && !_isMicReady,
                                              isCompact: isCompact,
                                              hideLabel: hideActionLabels,
                                              onPressed: () =>
                                                  _onAyahMicPressed(
                                                    index,
                                                    ayah['arabic'],
                                                  ),
                                            ),
                                            const SizedBox(width: 6),
                                            _EyeButton(
                                              lang: lang,
                                              isActive:
                                                  _eyeReadingAyahIdx == index,
                                              isFocused: _isEyeFocused,
                                              isCompact: isCompact,
                                              hideLabel: hideActionLabels,
                                              onPressed: () {
                                                final translationText =
                                                    (lang == 'id' || lang == 'ms')
                                                        ? (ayah['translation_id'] ?? '')
                                                        : (ayah['translation_en'] ?? '');
                                                _onEyeReadingPressed(
                                                  index,
                                                  ayah['arabic'],
                                                  translation: translationText,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              if (isRecording)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: _buildListeningInfoContent(
                                    context,
                                    lang,
                                  ),
                                ),
                              if (_eyeReadingAyahIdx == index)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: _buildEyeTrackingInfoContent(
                                    context,
                                    lang,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_eyeReadingAyahIdx == index &&
                                                _eyeReadingPhase == EyeReadingPhase.arabic)
                                            ? Colors.teal.withValues(alpha: 0.08)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (_eyeReadingAyahIdx == index &&
                                                  _eyeReadingPhase == EyeReadingPhase.arabic)
                                              ? Colors.teal.withValues(alpha: 0.35)
                                              : Colors.transparent,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: TajweedText(
                                        text: ayah['arabic'],
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: isAyahReadDisplay
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          height: 2.2,
                                          fontFamily: 'Amiri',
                                          color: isAyahReadDisplay
                                              ? Colors.teal.shade900
                                              : Colors.black,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        ayah['latin'] ?? '',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isAyahReadDisplay
                                              ? Colors.teal.shade800
                                              : Colors.teal.shade700,
                                          fontWeight: FontWeight.w600,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (_eyeReadingAyahIdx == index &&
                                                _eyeReadingPhase == EyeReadingPhase.translation)
                                            ? Colors.amber.withValues(alpha: 0.12)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (_eyeReadingAyahIdx == index &&
                                                  _eyeReadingPhase == EyeReadingPhase.translation)
                                              ? Colors.amber.withValues(alpha: 0.45)
                                              : Colors.transparent,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Text(
                                        (lang == 'id' || lang == 'ms')
                                            ? (ayah['translation_id'] ?? '')
                                            : (ayah['translation_en'] ?? ''),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: (_eyeReadingAyahIdx == index &&
                                                  _eyeReadingPhase == EyeReadingPhase.translation)
                                              ? Colors.teal.shade900
                                              : (isAyahReadDisplay
                                                  ? Colors.teal.shade800
                                                  : (isFuture && !isAlwaysActive)
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade700),
                                          fontWeight: isAyahReadDisplay
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontStyle: FontStyle.italic,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Sticky Ayah Header & Live Info Bar for Long Ayahs
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: RepaintBoundary(
                child: ValueListenableBuilder<int?>(
                  valueListenable: _stickyAyahIndex,
                  builder: (context, stickyIdx, _) {
                    if (stickyIdx == null || stickyIdx >= ayahs.length) {
                      return const SizedBox.shrink();
                    }
                    return _buildStickyAyahHeader(
                      context: context,
                      ayahIndex: stickyIdx,
                      ayahs: ayahs,
                      lang: lang,
                    );
                  },
                ),
              ),
            ),
            if (_isInitializing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            Translations.get(lang, 'initializing'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (ayahs.length >= 7)
              Positioned(
                right: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
                child: RepaintBoundary(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentVisibleAyah,
                    builder: (context, currentAyah, _) {
                      return _AyahNavFloatingPill(
                        currentAyah: currentAyah,
                        totalAyahs: ayahs.length,
                        onTap: () => _showAyahNavigatorSheet(
                          context,
                          ayahs.length,
                          lang,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSurahButton(
    BuildContext context,
    AppState appState,
    int currentSurahIdx,
  ) {
    if (currentSurahIdx >= appState.quranData.length - 1) {
      return const SizedBox.shrink();
    }

    final nextSurah = appState.quranData[currentSurahIdx + 1];
    final lang = appState.languageCode;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.teal.withValues(alpha: 0.3),
        ),
        onPressed: () {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.navigatorKey.currentState?.pushReplacement(
            AppPageRoute(child: SurahDetailScreen(surah: nextSurah)),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          "${Translations.get(lang, 'next_surah')}: ${nextSurah['surah_name']}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  bool _hasFinalizedSession = false;

  void _finalizeSpiritualEnergySession() {
    if (_hasFinalizedSession) return;
    _hasFinalizedSession = true;

    if (_sessionAyahsCount > 0) {
      try {
        final currentProgress =
            QuranProgressHelper.getCombinedSpiritualProgress(
              khatmCount: _appState.khatmCount,
              currentSurahIndex: _appState.currentSurahIndex,
              currentAyahNumber: _appState.lastReadAyahNumber,
              quranData: _appState.quranData,
              totalDzikirCount: _appState.totalDzikirCount,
            );
        _appState.triggerSpiritualEnergy(
          previousProgress: _sessionStartProgress ?? currentProgress,
          targetProgress: currentProgress,
          source: 'quran',
          itemsCount: _sessionAyahsCount,
        );
      } catch (e) {
        debugPrint('[SurahDetailScreen] Error triggering spiritual energy: $e');
      }
    }
  }

  bool _isExiting = false;

  void _handleBackToSurahList() {
    if (_isExiting || !mounted) return;
    _isExiting = true;
    _finalizeSpiritualEnergySession();

    // Check if SurahListScreen is already in the navigation stack below
    bool foundSurahList = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == 'SurahListScreen') {
        foundSurahList = true;
        return true;
      }
      return route.isFirst;
    });

    // If SurahListScreen was not in the stack (e.g. user jumped straight to SurahDetailScreen from HomeScreen),
    // navigate to SurahListScreen so the user sees the Quran surah selection menu.
    if (!foundSurahList && mounted) {
      Navigator.of(context).push(AppPageRoute(child: const SurahListScreen()));
    }
  }

  void _onItemPositionsChanged() {
    if (!mounted || _isDisposed) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int minIdx = 999999;
    for (final position in positions) {
      if (position.itemTrailingEdge > 0 && position.index < minIdx) {
        minIdx = position.index;
      }
    }

    final ayahs = widget.surah['ayahs'] as List<dynamic>;
    final totalAyahs = ayahs.length;
    if (minIdx >= 0 && minIdx < totalAyahs) {
      final newAyah = minIdx + 1;
      if (newAyah != _currentVisibleAyah.value) {
        _currentVisibleAyah.value = newAyah;
      }
    }

    // Determine sticky header for long ayahs
    int? stickyIdx;
    final activeIdx = _recordingAyahIdx ?? _eyeReadingAyahIdx;

    // 1. Prioritize active reading ayah if it is long and scrolled past top
    if (activeIdx != null && activeIdx >= 0 && activeIdx < totalAyahs) {
      final activeArabic = ayahs[activeIdx]['arabic'] as String? ?? '';
      if (_isLongAyah(activeArabic)) {
        for (final position in positions) {
          if (position.index == activeIdx &&
              position.itemLeadingEdge < -0.015 &&
              position.itemTrailingEdge > 0.08) {
            stickyIdx = activeIdx;
            break;
          }
        }
      }
    }

    // 2. Otherwise find the topmost long ayah spanning past top of viewport
    if (stickyIdx == null) {
      double bestLeading = -999999.0;
      for (final position in positions) {
        if (position.index >= 0 && position.index < totalAyahs) {
          final ayahArabic = ayahs[position.index]['arabic'] as String? ?? '';
          if (_isLongAyah(ayahArabic)) {
            if (position.itemLeadingEdge < -0.015 &&
                position.itemTrailingEdge > 0.08) {
              if (position.itemLeadingEdge > bestLeading) {
                bestLeading = position.itemLeadingEdge;
                stickyIdx = position.index;
              }
            }
          }
        }
      }
    }

    if (_stickyAyahIndex.value != stickyIdx) {
      _stickyAyahIndex.value = stickyIdx;
    }
  }

  void _scrollToAyah(int index) {
    if (index < 0) index = 0;
    final totalAyahs = (widget.surah['ayahs'] as List).length;
    if (index >= totalAyahs) index = totalAyahs - 1;

    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: index);
    }
    _currentVisibleAyah.value = index + 1;
  }

  void _showAyahNavigatorSheet(
    BuildContext context,
    int totalAyahs,
    String lang,
  ) {
    final appState = Provider.of<AppState>(context, listen: false);
    final int surahIndex = widget.surah['surah_number'] - 1;
    final int surahNumber = widget.surah['surah_number'];

    // Identify Juz starting points located inside this surah
    final juzInSurah = <Map<String, int>>[];
    for (int i = 0; i < QuranProgressHelper.juzStarts.length; i++) {
      if (QuranProgressHelper.juzStarts[i][0] == surahNumber) {
        juzInSurah.add({
          'juz': i + 1,
          'ayah': QuranProgressHelper.juzStarts[i][1],
        });
      }
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 6,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AyahNavigatorBottomSheet(
        surahName: widget.surah['surah_name'],
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        currentVisibleAyah: _currentVisibleAyah.value,
        lastReadAyahNumber:
            appState.currentSurahIndex == surahIndex &&
                appState.lastReadAyahNumber > 0
            ? appState.lastReadAyahNumber
            : null,
        nextUnreadAyahNumber:
            appState.highestSurahIndex == surahIndex &&
                appState.highestAyahIndex + 1 < totalAyahs
            ? appState.highestAyahIndex + 2
            : null,
        juzInSurah: juzInSurah,
        lang: lang,
        onAyahSelected: (ayahNum) {
          Navigator.pop(ctx);
          _scrollToAyah(ayahNum - 1);
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopEyeReading();
      _stopListening();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _itemPositionsListener.itemPositions.removeListener(
      _onItemPositionsChanged,
    );

    // Cancel all timers immediately
    _eyeTimer?.cancel();
    _eyeTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    // Stop services without setState
    _stopListening(isDisposing: true);
    _stopEyeReading(isDisposing: true);

    _currentVisibleAyah.dispose();
    _stickyAyahIndex.dispose();
    _finalizeSpiritualEnergySession();

    super.dispose();
  }

  void _showLongAyahVoiceSuggestionModal({
    required BuildContext context,
    required int ayahIndex,
    required String arabic,
    required String lang,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isEn = lang == 'en';
    final wordCount = _getWordCount(arabic);
    bool doNotShowAgain = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      elevation: 6,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header with Icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: Colors.amber.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn
                                    ? 'Reading Method Suggestion'
                                    : 'Saran Metode Membaca',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.surah['surah_name']} • Ayat ${ayahIndex + 1} ($wordCount kata)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Information Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.amber.shade900.withValues(alpha: 0.4)
                              : Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade900,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isEn
                                  ? 'This ayah is quite long ($wordCount words). Voice recognition for long ayahs is currently under development. We recommend using the "Silent Reading" method (eye tracking) for a smoother recitation.'
                                  : 'Ayat ini tergolong panjang ($wordCount kata). Fitur suara untuk ayat panjang masih dalam tahap pengembangan. Disarankan menggunakan metode "Baca Dalam Hati" (deteksi fokus mata) agar tilawah lebih lancar.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Checkbox
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          doNotShowAgain = !doNotShowAgain;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: doNotShowAgain,
                                activeColor: Colors.teal,
                                onChanged: (val) {
                                  setModalState(() {
                                    doNotShowAgain = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEn
                                    ? 'Do not show again for this surah'
                                    : 'Jangan ingatkan lagi untuk surah ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Primary Button: Gunakan Baca Dalam Hati
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (doNotShowAgain) {
                          _suppressLongAyahVoiceWarningForSurah = true;
                        }
                        Navigator.pop(ctx);
                        final ayahs = widget.surah['ayahs'] as List<dynamic>?;
                        String? translationText;
                        if (ayahs != null && ayahIndex < ayahs.length) {
                          translationText = (lang == 'id' || lang == 'ms')
                              ? (ayahs[ayahIndex]['translation_id'] ?? '')
                              : (ayahs[ayahIndex]['translation_en'] ?? '');
                        }
                        _onEyeReadingPressed(
                          ayahIndex,
                          arabic,
                          translation: translationText,
                        );
                      },
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                      label: Text(
                        isEn
                            ? 'Use Silent Reading (Recommended)'
                            : 'Gunakan Baca Dalam Hati (Disarankan)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Secondary Button: Tetap Pakai Suara
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (doNotShowAgain) {
                          _suppressLongAyahVoiceWarningForSurah = true;
                        }
                        Navigator.pop(ctx);
                        _startListeningForAyah(ayahIndex, arabic);
                      },
                      icon: const Icon(Icons.mic_rounded, size: 18),
                      label: Text(
                        isEn ? 'Continue with Voice' : 'Tetap Pakai Suara',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _getLastReadLabel(String lang) {
    switch (lang) {
      case 'en':
        return 'Last Read';
      case 'ar':
        return 'آخر قراءة';
      case 'af':
        return 'Laas Gelees';
      case 'sw':
        return 'Mwisho Kusomwa';
      case 'ms':
      case 'id':
      default:
        return 'Terakhir Dibaca';
    }
  }

  static String _getSunnahReadLabel(String lang) {
    switch (lang) {
      case 'en':
        return '✓ Read';
      case 'ar':
        return '✓ تمت القراءة';
      case 'af':
        return '✓ Gelees';
      case 'sw':
        return '✓ Imesomwa';
      case 'ms':
      case 'id':
      default:
        return '✓ Dibaca';
    }
  }

  static String _getSunnahLastReadLabel(String lang) {
    switch (lang) {
      case 'en':
        return '✓ Last Read';
      case 'ar':
        return '✓ آخر قراءة';
      case 'af':
        return '✓ Laas Gelees';
      case 'sw':
        return '✓ Mwisho Kusomwa';
      case 'ms':
      case 'id':
      default:
        return '✓ Terakhir Dibaca';
    }
  }

  static String _getReadWithLabel(String lang) {
    switch (lang) {
      case 'en':
        return 'Read with:';
      case 'ar':
        return 'اقرأ بـ:';
      case 'af':
        return 'Lees met:';
      case 'sw':
        return 'Soma kwa:';
      case 'ms':
      case 'id':
      default:
        return 'Baca dengan:';
    }
  }

  static String _getMicPreparingText(String lang) {
    switch (lang) {
      case 'en':
        return 'Microphone is preparing, please wait...';
      case 'ar':
        return 'الميكروفون قيد الإعداد، يرجى الانتظار...';
      case 'af':
        return 'Mikrofoon berei voor, wag asseblief...';
      case 'sw':
        return 'Kipaza sauti kinaandaliwa, tafadhali subiri...';
      case 'ms':
        return 'Mikrofon sedang disiapkan, sila tunggu...';
      case 'id':
      default:
        return 'Mikrofon sedang menyiapkan, mohon tunggu...';
    }
  }

  static String _getListeningPromptText(String lang) {
    switch (lang) {
      case 'en':
        return 'Listening... (Please recite now)';
      case 'ar':
        return 'جارٍ الاستماع... (يرجى البدء بالقراءة)';
      case 'af':
        return 'Luister... (Begin asseblief lees)';
      case 'sw':
        return 'Inasikiliza... (Tafadhali anza kusoma)';
      case 'ms':
        return 'Mendengar... (Sila mula membaca)';
      case 'id':
      default:
        return 'Mendengarkan... (Silakan mulai membaca)';
    }
  }

  static String _getVerifyingText(String lang) {
    switch (lang) {
      case 'en':
        return 'Verifying recitation...';
      case 'ar':
        return 'جارٍ التحقق من التلاوة...';
      case 'af':
        return 'Verifieer resitasie...';
      case 'sw':
        return 'Inathibitisha usomaji...';
      case 'ms':
        return 'Mengesahkan bacaan...';
      case 'id':
      default:
        return 'Memverifikasi bacaan...';
    }
  }

  static String getEyeTrackingText(
    String lang, {
    required bool isFocused,
    EyeReadingPhase phase = EyeReadingPhase.arabic,
    int dotCount = 1,
  }) {
    if (!isFocused) {
      switch (lang) {
        case 'en':
          return 'NOT FOCUSED: Look at Ayah to read';
        case 'ar':
          return 'غير مركز: انظر إلى الآية للقراءة';
        case 'af':
          return 'NIE GEFOKUS: Kyk na Vers om te lees';
        case 'sw':
          return 'HAIJALENGA: Tazama Aya ili kusoma';
        case 'ms':
          return 'TIDAK FOKUS: Pandang Ayat untuk Membaca';
        case 'id':
        default:
          return 'TIDAK FOKUS: Tatap Ayat untuk Membaca';
      }
    }

    final dots = '.' * dotCount.clamp(1, 3);
    if (phase == EyeReadingPhase.arabic) {
      switch (lang) {
        case 'en':
          return 'Reading Arabic$dots';
        case 'ar':
          return 'قراءة النص العربي$dots';
        case 'af':
          return 'Lees Arabiese Teks$dots';
        case 'sw':
          return 'Kusoma Maandishi ya Kiarabu$dots';
        case 'ms':
          return 'Membaca Teks Arab$dots';
        case 'id':
        default:
          return 'Membaca Arab$dots';
      }
    } else {
      switch (lang) {
        case 'en':
          return 'Reading Meaning$dots';
        case 'ar':
          return 'قراءة المعنى$dots';
        case 'af':
          return 'Lees Betekenis$dots';
        case 'sw':
          return 'Kusoma Maana$dots';
        case 'ms':
          return 'Membaca Terjemahan$dots';
        case 'id':
        default:
          return 'Membaca Arti$dots';
      }
    }
  }

  static String _getEyeTrackingText(
    String lang, {
    required bool isFocused,
    EyeReadingPhase phase = EyeReadingPhase.arabic,
    int dotCount = 1,
  }) {
    return getEyeTrackingText(
      lang,
      isFocused: isFocused,
      phase: phase,
      dotCount: dotCount,
    );
  }

  /// Calculates accurate reading duration for Arabic text in silent reading (eye tracking) mode.
  /// Accounts for actual hijaiyah letter count, shaddah (tasydid), long madd (4-6 harakat),
  /// inter-word transitions, and baseline ayah orientation/waqf pause.
  static double calculateAccurateArabicSeconds(String arabic) {
    final clean = arabic
        .replaceAll(RegExp(r'\[[a-zA-Z0-9:#]*\[|\]'), '')
        .replaceAll(RegExp(r'[\u0660-\u0669\d\s\u06D6-\u06ED]'), ' ')
        .trim();
    if (clean.isEmpty) return 2.5;

    // Count pure hijaiyah letters (excluding harakat)
    final letterMatches = RegExp(r'[\u0621-\u064A\u0671\u0670]').allMatches(clean);
    final letterCount = letterMatches.length;

    // Count shaddah (tasydid \u0651) -> doubled letter phonetics
    final shaddahCount = RegExp(r'\u0651').allMatches(arabic).length;

    // Count long madd signs (maddah \u0653, \u06E4, or alif maddah \u0622) -> 4-6 harakat
    final longMaddCount = RegExp(r'[\u0653\u06E4\u0622]').allMatches(arabic).length;

    // Word count for inter-word breathing and pauses
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

    // Base duration: 0.8s (waqf / visual orientation)
    // + 0.22s per hijaiyah letter (optimal silent reading pace with basic vowels)
    // + 0.25s per shaddah (emphasis & doubling)
    // + 0.75s per long madd (4-6 harakat elongation)
    // + 0.12s per word transition
    final double rawSeconds = 0.8 +
        (letterCount * 0.22) +
        (shaddahCount * 0.25) +
        (longMaddCount * 0.75) +
        (words * 0.12);

    return math.max(2.5, double.parse(rawSeconds.toStringAsFixed(1)));
  }

  /// Calculates accurate reading duration for translation text in silent reading mode.
  /// Accounts for reading speed (WPM ~210), clauses/commas, sentence ends, and eye transition pause.
  static double calculateAccurateTranslationSeconds(String? translation) {
    if (translation == null || translation.trim().isEmpty) return 0.0;
    final clean = translation.trim();

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words == 0) return 0.0;

    final commas = RegExp(r'[,;:]').allMatches(clean).length;
    final periods = RegExp(r'[.!?]').allMatches(clean).length;

    // 0.6s eye repositioning from Arabic to translation
    // + 0.28s per word (~210 WPM for reflective comprehension)
    // + 0.25s per comma/semicolon/colon
    // + 0.40s per period/question/exclamation mark
    final double rawSeconds = 0.6 +
        (words * 0.28) +
        (commas * 0.25) +
        (periods * 0.40);

    return math.max(1.8, double.parse(rawSeconds.toStringAsFixed(1)));
  }

  Widget _buildListeningInfoContent(
    BuildContext context,
    String lang, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: !_isMicReady ? Colors.amber.shade50 : Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !_isMicReady ? Colors.amber.shade300 : Colors.teal.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                !_isMicReady
                    ? Icons.hourglass_top_rounded
                    : (_recognizedText.isEmpty
                          ? Icons.mic_rounded
                          : Icons.hearing_rounded),
                size: isCompact ? 16 : 18,
                color: !_isMicReady ? Colors.amber.shade800 : Colors.teal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  !_isMicReady
                      ? _getMicPreparingText(lang)
                      : (_recognizedText.isEmpty
                            ? _getListeningPromptText(lang)
                            : _recognizedText),
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 13,
                    color: !_isMicReady
                        ? Colors.amber.shade900
                        : Colors.teal.shade800,
                    fontWeight: FontWeight.bold,
                    fontStyle: (!_isMicReady || _recognizedText.isEmpty)
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  textDirection: (_isMicReady && _recognizedText.isNotEmpty)
                      ? TextDirection.rtl
                      : (lang == 'ar' ? TextDirection.rtl : TextDirection.ltr),
                  maxLines: isCompact ? 2 : null,
                  overflow: isCompact ? TextOverflow.ellipsis : null,
                ),
              ),
            ],
          ),
          if (_isMicReady && _recognizedText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "...",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.teal.shade700,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _getVerifyingText(lang),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.teal.shade700,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEyeTrackingInfoContent(
    BuildContext context,
    String lang, {
    bool isCompact = false,
  }) {
    final isArabicPhase = _eyeReadingPhase == EyeReadingPhase.arabic;
    final primaryColor = _isEyeFocused
        ? (isArabicPhase ? Colors.green.shade800 : Colors.amber.shade900)
        : Colors.red.shade700;
    final bgColor = _isEyeFocused
        ? (isArabicPhase
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.amber.withValues(alpha: 0.12))
        : Colors.red.withValues(alpha: 0.1);
    final borderColor = _isEyeFocused
        ? (isArabicPhase
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.amber.withValues(alpha: 0.45))
        : Colors.red.withValues(alpha: 0.3);
    final iconData = _isEyeFocused
        ? (isArabicPhase ? Icons.visibility_rounded : Icons.auto_stories_rounded)
        : Icons.visibility_off_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 14,
            color: primaryColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _getEyeTrackingText(
                lang,
                isFocused: _isEyeFocused,
                phase: _eyeReadingPhase,
                dotCount: _eyeDotCount,
              ),
              style: TextStyle(
                fontSize: 10,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyAyahHeader({
    required BuildContext context,
    required int ayahIndex,
    required List<dynamic> ayahs,
    required String lang,
  }) {
    if (ayahIndex < 0 || ayahIndex >= ayahs.length) {
      return const SizedBox.shrink();
    }

    final ayah = ayahs[ayahIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isRecording = _recordingAyahIdx == ayahIndex;
    final isEyeReading = _eyeReadingAyahIdx == ayahIndex;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHigh
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRecording
                ? Colors.teal
                : (isEyeReading
                      ? Colors.indigo
                      : colorScheme.outlineVariant.withValues(alpha: 0.6)),
            width: (isRecording || isEyeReading) ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final effectiveWidth =
                constraints.maxWidth / (textScale > 0 ? textScale : 1.0);
            final isVeryNarrow = effectiveWidth < 250;
            final ayahLabel = Translations.get(lang, 'ayah');

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Ayah badge (Clean, proportional, and overflow-protected)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bookmark_outline_rounded,
                                size: 13,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$ayahLabel ${ayahIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MicButton(
                            lang: lang,
                            isRecording: isRecording,
                            isInitializing: isRecording && !_isMicReady,
                            isCompact: true,
                            hideLabel: isVeryNarrow,
                            onPressed: () =>
                                _onAyahMicPressed(ayahIndex, ayah['arabic']),
                          ),
                          const SizedBox(width: 6),
                          _EyeButton(
                            lang: lang,
                            isActive: isEyeReading,
                            isFocused: _isEyeFocused,
                            isCompact: true,
                            hideLabel: isVeryNarrow,
                            onPressed: () {
                              final translationText =
                                  (lang == 'id' || lang == 'ms')
                                      ? (ayah['translation_id'] ?? '')
                                      : (ayah['translation_en'] ?? '');
                              _onEyeReadingPressed(
                                ayahIndex,
                                ayah['arabic'],
                                translation: translationText,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // If listening / recording:
                if (isRecording)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: _buildListeningInfoContent(
                      context,
                      lang,
                      isCompact: true,
                    ),
                  ),
                // If eye tracking:
                if (isEyeReading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: _buildEyeTrackingInfoContent(
                      context,
                      lang,
                      isCompact: true,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final String lang;
  final bool isRecording;
  final bool isInitializing;
  final bool isCompact;
  final bool hideLabel;
  final VoidCallback onPressed;

  const _MicButton({
    required this.lang,
    required this.isRecording,
    this.isInitializing = false,
    this.isCompact = false,
    this.hideLabel = false,
    required this.onPressed,
  });

  static String _getVoiceLabel(
    String lang, {
    required bool isCompact,
    required bool isPreparing,
  }) {
    if (isPreparing) {
      if (isCompact) {
        switch (lang) {
          case 'en':
            return 'Wait...';
          case 'ar':
            return 'انتظر...';
          case 'af':
            return 'Wag...';
          case 'sw':
            return 'Subiri...';
          case 'ms':
          case 'id':
          default:
            return 'Tunggu...';
        }
      } else {
        switch (lang) {
          case 'en':
            return 'Preparing...';
          case 'ar':
            return 'جارٍ الإعداد...';
          case 'af':
            return 'Berei voor...';
          case 'sw':
            return 'Inaandaa...';
          case 'ms':
          case 'id':
          default:
            return 'Menyiapkan...';
        }
      }
    }

    if (isCompact) {
      switch (lang) {
        case 'en':
          return 'Voice';
        case 'ar':
          return 'صوت';
        case 'af':
          return 'Stem';
        case 'sw':
          return 'Sauti';
        case 'ms':
        case 'id':
        default:
          return 'Suara';
      }
    } else {
      return Translations.get(lang, 'voice');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreparing = isRecording && isInitializing;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? (hideLabel ? 7 : 8) : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isPreparing
              ? Colors.amber.shade700
              : (isRecording ? Colors.red : Colors.teal.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPreparing
                  ? Icons.hourglass_top_rounded
                  : (isRecording ? Icons.mic : Icons.mic_none),
              color: (isRecording || isPreparing)
                  ? Colors.white
                  : Colors.teal.shade800,
              size: isCompact ? 14 : 16,
            ),
            if (!hideLabel) ...[
              const SizedBox(width: 4),
              Text(
                _getVoiceLabel(
                  lang,
                  isCompact: isCompact,
                  isPreparing: isPreparing,
                ),
                style: TextStyle(
                  color: (isRecording || isPreparing)
                      ? Colors.white
                      : Colors.teal.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  final int khatmCount;
  const _PointsBadge({required this.points, this.khatmCount = 0});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: colorScheme.onSecondaryContainer,
                size: 10,
              ),
              const SizedBox(width: 4),
              Text(
                "Khatm $khatmCount'x",
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.stars_rounded,
                color: colorScheme.onTertiaryContainer,
                size: 10,
              ),
              const SizedBox(width: 4),
              Text(
                points.toString(),
                style: TextStyle(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EyeButton extends StatelessWidget {
  final String lang;
  final bool isActive;
  final bool isFocused;
  final bool isCompact;
  final bool hideLabel;
  final VoidCallback onPressed;

  const _EyeButton({
    required this.lang,
    required this.isActive,
    required this.isFocused,
    this.isCompact = false,
    this.hideLabel = false,
    required this.onPressed,
  });

  static String _getSilentLabel(String lang, {required bool isCompact}) {
    if (isCompact) {
      switch (lang) {
        case 'en':
          return 'Silent';
        case 'ar':
          return 'قلب';
        case 'af':
          return 'Stil';
        case 'sw':
          return 'Moyoni';
        case 'ms':
        case 'id':
        default:
          return 'Hati';
      }
    } else {
      switch (lang) {
        case 'en':
          return 'Silent';
        case 'ar':
          return 'في القلب';
        case 'af':
          return 'Stil Lees';
        case 'sw':
          return 'Moyoni';
        case 'ms':
        case 'id':
        default:
          return 'Dalam Hati';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? (hideLabel ? 7 : 8) : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? (isFocused ? Colors.green : Colors.orange)
              : Colors.teal.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? (isFocused ? Icons.visibility : Icons.visibility_off)
                  : Icons.remove_red_eye_rounded,
              color: isActive ? Colors.white : Colors.teal.shade800,
              size: isCompact ? 14 : 16,
            ),
            if (!hideLabel) ...[
              const SizedBox(width: 4),
              Text(
                _getSilentLabel(lang, isCompact: isCompact),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.teal.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AyahNavFloatingPill extends StatelessWidget {
  final int currentAyah;
  final int totalAyahs;
  final VoidCallback onTap;

  const _AyahNavFloatingPill({
    required this.currentAyah,
    required this.totalAyahs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      shadowColor: Colors.black38,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.teal.shade900 : Colors.teal.shade700,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'Ayat $currentAyah / $totalAyahs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.unfold_more_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AyahNavigatorBottomSheet extends StatefulWidget {
  final String surahName;
  final int surahNumber;
  final int totalAyahs;
  final int currentVisibleAyah;
  final int? lastReadAyahNumber;
  final int? nextUnreadAyahNumber;
  final List<Map<String, int>> juzInSurah;
  final String lang;
  final ValueChanged<int> onAyahSelected;

  const _AyahNavigatorBottomSheet({
    required this.surahName,
    required this.surahNumber,
    required this.totalAyahs,
    required this.currentVisibleAyah,
    this.lastReadAyahNumber,
    this.nextUnreadAyahNumber,
    required this.juzInSurah,
    required this.lang,
    required this.onAyahSelected,
  });

  @override
  State<_AyahNavigatorBottomSheet> createState() =>
      _AyahNavigatorBottomSheetState();
}

class _AyahNavigatorBottomSheetState extends State<_AyahNavigatorBottomSheet> {
  String _enteredNumber = '';
  String? _errorMessage;

  void _onDigitPressed(int digit) {
    HapticFeedback.selectionClick();
    if (_enteredNumber.isEmpty && digit == 0) return;
    final candidate = '$_enteredNumber$digit';
    final parsed = int.tryParse(candidate);
    if (parsed != null && parsed > widget.totalAyahs) {
      setState(() {
        _errorMessage = widget.lang == 'en'
            ? 'Max ayah is ${widget.totalAyahs}'
            : 'Maksimal ayat ${widget.totalAyahs}';
      });
      return;
    }
    setState(() {
      _enteredNumber = candidate;
      _errorMessage = null;
    });
  }

  void _onBackspacePressed() {
    HapticFeedback.selectionClick();
    if (_enteredNumber.isNotEmpty) {
      setState(() {
        _enteredNumber = _enteredNumber.substring(0, _enteredNumber.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClearPressed() {
    HapticFeedback.selectionClick();
    setState(() {
      _enteredNumber = '';
      _errorMessage = null;
    });
  }

  void _onJumpPressed() {
    if (_enteredNumber.isEmpty) return;
    final parsed = int.tryParse(_enteredNumber);
    if (parsed == null || parsed < 1 || parsed > widget.totalAyahs) {
      setState(() {
        _errorMessage = widget.lang == 'en'
            ? 'Enter 1 - ${widget.totalAyahs}'
            : 'Pilih ayat 1 - ${widget.totalAyahs}';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onAyahSelected(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isEn = widget.lang == 'en';

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.near_me_rounded,
                      color: Colors.teal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Jump to Ayah' : 'Lompat ke Ayat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.surahName} (Ayat 1 - ${widget.totalAyahs})',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Number Display Field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.red
                        : Colors.teal.withValues(alpha: 0.3),
                    width: _errorMessage != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      isEn ? 'Ayah: ' : 'Ayat: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _enteredNumber.isEmpty ? '-' : _enteredNumber,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: _enteredNumber.isEmpty
                              ? colorScheme.onSurface.withValues(alpha: 0.3)
                              : Colors.teal,
                        ),
                      ),
                    ),
                    Text(
                      '1 - ${widget.totalAyahs}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    if (_enteredNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _onClearPressed,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.cancel_rounded,
                            size: 20,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Quick Shortcuts
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickChip(
                      label: isEn ? 'Ayah 1 (Start)' : 'Ayat 1 (Awal)',
                      icon: Icons.first_page_rounded,
                      onTap: () => widget.onAyahSelected(1),
                    ),
                    if (widget.lastReadAyahNumber != null &&
                        widget.lastReadAyahNumber !=
                            widget.currentVisibleAyah) ...[
                      const SizedBox(width: 8),
                      _buildQuickChip(
                        label: isEn
                            ? 'Last Read (${widget.lastReadAyahNumber})'
                            : 'Terakhir Dibaca (${widget.lastReadAyahNumber})',
                        icon: Icons.bookmark_added_rounded,
                        color: Colors.teal,
                        onTap: () =>
                            widget.onAyahSelected(widget.lastReadAyahNumber!),
                      ),
                    ],
                    if (widget.nextUnreadAyahNumber != null &&
                        widget.nextUnreadAyahNumber! <= widget.totalAyahs) ...[
                      const SizedBox(width: 8),
                      _buildQuickChip(
                        label: isEn
                            ? 'Target (${widget.nextUnreadAyahNumber})'
                            : 'Target Lanjut (${widget.nextUnreadAyahNumber})',
                        icon: Icons.track_changes_rounded,
                        color: Colors.orange.shade700,
                        onTap: () =>
                            widget.onAyahSelected(widget.nextUnreadAyahNumber!),
                      ),
                    ],
                    for (final juz in widget.juzInSurah) ...[
                      const SizedBox(width: 8),
                      _buildQuickChip(
                        label: 'Awal Juz ${juz['juz']} (Ayat ${juz['ayah']})',
                        icon: Icons.auto_stories_rounded,
                        color: Colors.indigo,
                        onTap: () => widget.onAyahSelected(juz['ayah']!),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: isEn
                          ? 'Ayah ${widget.totalAyahs} (End)'
                          : 'Ayat ${widget.totalAyahs} (Akhir)',
                      icon: Icons.last_page_rounded,
                      onTap: () => widget.onAyahSelected(widget.totalAyahs),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // In-App Numeric Keypad
              _buildKeypadRow([1, 2, 3], isDark, colorScheme),
              _buildKeypadRow([4, 5, 6], isDark, colorScheme),
              _buildKeypadRow([7, 8, 9], isDark, colorScheme),
              Row(
                children: [
                  _buildKeyButton(
                    child: Text(
                      'C',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade400,
                      ),
                    ),
                    onTap: _onClearPressed,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                  _buildKeyButton(
                    child: Text(
                      '0',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    onTap: () => _onDigitPressed(0),
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                  _buildKeyButton(
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    onTap: _onBackspacePressed,
                    isDark: isDark,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Big Jump Action Button
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                    disabledForegroundColor: isDark
                        ? Colors.grey.shade600
                        : Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _enteredNumber.isNotEmpty ? _onJumpPressed : null,
                  icon: const Icon(Icons.near_me_rounded, size: 18),
                  label: Text(
                    _enteredNumber.isNotEmpty
                        ? (isEn
                              ? 'Jump to Ayah $_enteredNumber'
                              : 'Lompat ke Ayat $_enteredNumber')
                        : (isEn ? 'Enter Ayah Number' : 'Ketik Nomor Ayat'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(
    List<int> digits,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: digits.map((d) {
        return _buildKeyButton(
          child: Text(
            '$d',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          onTap: () => _onDigitPressed(d),
          isDark: isDark,
          colorScheme: colorScheme,
        );
      }).toList(),
    );
  }

  Widget _buildKeyButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Material(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? Colors.teal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: chipColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
