import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/app_state.dart';
import '../../services/eye_tracker_service.dart';
import '../../utils/translations.dart';

class HadithDetailScreen extends StatefulWidget {
  final Map<String, dynamic> hadith;
  final int hadithIndex;

  const HadithDetailScreen({
    super.key,
    required this.hadith,
    required this.hadithIndex,
  });

  @override
  State<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends State<HadithDetailScreen>
    with WidgetsBindingObserver {
  // Silent Reading & Eye Tracking State
  final EyeTrackerService _eyeTrackerService = EyeTrackerService();
  StreamSubscription? _eyeFocusSubscription;
  Timer? _readingTimer;
  Timer? _vibrationTimer;

  double _readingProgress = 0.0;
  int _totalDurationSeconds = 25;
  bool _isEyeFocused = false;
  bool _hasCompleted = false;
  bool _isDisposed = false;
  bool _isCameraSupported = true;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _calculateDuration();
    _initEyeReading();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!_isRequestingPermission) {
        _stopEyeTracking(isDisposing: false);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!_isRequestingPermission && !_hasCompleted && mounted && !_isDisposed) {
        _initEyeReading();
      }
    }
  }

  int get _pointsEarned {
    final arabic = widget.hadith['arabic'] as String? ?? '';
    final translations =
        widget.hadith['translations'] as Map<String, dynamic>? ?? {};
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;
    final translationText = translations[lang] as String? ??
        translations['en'] as String? ??
        translations['id'] as String? ??
        '';

    final arabicBonus = arabic.trim().length ~/ 25;
    final translationBonus = translationText.trim().length ~/ 60;
    return (3 + arabicBonus + translationBonus).clamp(3, 8);
  }

  void _calculateDuration() {
    final arabic = widget.hadith['arabic'] as String? ?? '';
    final translations =
        widget.hadith['translations'] as Map<String, dynamic>? ?? {};
    final narrators = widget.hadith['narrators'] as Map<String, dynamic>? ?? {};

    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;

    final translationText = translations[lang] as String? ??
        translations['en'] as String? ??
        translations['id'] as String? ??
        '';
    final narratorText = narrators[lang] as String? ??
        narrators['en'] as String? ??
        narrators['id'] as String? ??
        '';

    // Word counts
    final arabicWords = arabic
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final translationWords = translationText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final narratorWords = narratorText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    // Deep Tadabbur duration:
    // Arabic reading & reflection: ~1.5s per word
    // Translation comprehension: ~0.8s per word
    // Narrator reading: ~0.5s per word
    // Base reflection buffer: + 6.0s
    final double calculatedSec = 6.0 +
        (arabicWords * 1.5) +
        (translationWords * 0.8) +
        (narratorWords * 0.5);
    _totalDurationSeconds = calculatedSec.ceil().clamp(20, 50);
  }

  Future<void> _initEyeReading() async {
    _hasCompleted = false;
    _readingProgress = 0.0;

    final status = await Permission.camera.status;
    if (!status.isGranted) {
      _isRequestingPermission = true;
      final requested = await Permission.camera.request();
      _isRequestingPermission = false;
      if (!mounted || _isDisposed) return;

      if (!requested.isGranted) {
        // Fallback: If camera permission is denied, run timer smoothly without blocking user
        setState(() {
          _isCameraSupported = false;
          _isEyeFocused = true;
        });
        _handleEyeTimer(true);
        return;
      }
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      _isEyeFocused = false;
    });

    try {
      await _eyeTrackerService.initialize();
      if (!mounted || _isDisposed) return;

      _eyeFocusSubscription = _eyeTrackerService.focusStream?.listen((focused) {
        if (!mounted || _isDisposed) return;
        setState(() => _isEyeFocused = focused);
        _handleEyeTimer(focused);
      });

      _handleEyeTimer(_eyeTrackerService.isFocused);
    } catch (e) {
      debugPrint("Eye tracker init error: $e");
      setState(() {
        _isCameraSupported = false;
        _isEyeFocused = true;
      });
      _handleEyeTimer(true);
    }
  }

  void _handleEyeTimer(bool focused) {
    _readingTimer?.cancel();
    _readingTimer = null;

    if (focused) {
      _vibrationTimer?.cancel();
      _vibrationTimer = null;

      _readingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted || _isDisposed) {
          timer.cancel();
          return;
        }

        setState(() {
          _readingProgress += 0.1 / _totalDurationSeconds;

          if (_readingProgress >= 1.0) {
            _readingProgress = 1.0;
            timer.cancel();
            _onReadingCompleted();
            _stopEyeTracking(isDisposing: false);
          }
        });
      });
    } else {
      if (!_hasCompleted && _isCameraSupported && _vibrationTimer == null) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onReadingCompleted() {
    if (_hasCompleted) return;
    _hasCompleted = true;

    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;
    final hadithId = widget.hadith['id'] as int? ?? (widget.hadithIndex + 1);
    final themes = widget.hadith['themes'] as Map<String, dynamic>? ?? {};
    final theme = themes[lang] as String? ??
        themes['en'] as String? ??
        themes['id'] as String? ??
        widget.hadith['theme'] as String? ??
        'Hadits Shahih';

    final points = _pointsEarned;
    final title = "Hadits #$hadithId: $theme";
    appState.saveHadithProgress(hadithId, title, points);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "${Translations.get(appState.languageCode, 'hadith_read_success')} (+$points ${Translations.get(appState.languageCode, 'points')})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _stopEyeTracking({bool isDisposing = false}) async {
    _readingTimer?.cancel();
    _readingTimer = null;
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    await _eyeFocusSubscription?.cancel();
    _eyeFocusSubscription = null;

    await _eyeTrackerService.dispose();

    if (!isDisposing && mounted) {
      setState(() {
        _isEyeFocused = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopEyeTracking(isDisposing: true);
    super.dispose();
  }

  void _goToNextHadith() {
    final appState = Provider.of<AppState>(context, listen: false);
    final allHadiths = appState.hadithData;
    if (widget.hadithIndex + 1 < allHadiths.length) {
      final nextHadith =
          allHadiths[widget.hadithIndex + 1] as Map<String, dynamic>;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HadithDetailScreen(
            hadith: nextHadith,
            hadithIndex: widget.hadithIndex + 1,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  String _getFocusText(String lang) {
    if (_isEyeFocused) {
      switch (lang) {
        case 'id':
          return "Mata Terdeteksi: Membaca & Mentadabburi...";
        case 'ms':
          return "Mata Dikesan: Membaca & Mentadabbur...";
        case 'ar':
          return "تم اكتشاف العين: تدبر وقراءة...";
        case 'af':
          return "Oog Bespeur: Lees en Oordink...";
        case 'sw':
          return "Jicho Limegunduliwa: Kusoma na Kutafakari...";
        default:
          return "Eye Detected: Reading & Contemplating...";
      }
    } else {
      switch (lang) {
        case 'id':
          return "TIDAK FOKUS: Tatap Hadits untuk Membaca";
        case 'ms':
          return "TIDAK FOKUS: Tatap Hadis untuk Membaca";
        case 'ar':
          return "غير مركز: انظر إلى الحديث للمتابعة";
        case 'af':
          return "NIE GEFOKUS NIE: Kyk na Hadieth om te lees";
        case 'sw':
          return "HAUJAZINGATIA: Tazama Hadithi ili Kusoma";
        default:
          return "NOT FOCUSED: Look at Hadith to read";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;

    final hadithId = widget.hadith['id'] as int? ?? (widget.hadithIndex + 1);
    final arabic = widget.hadith['arabic'] as String? ?? '';
    final themes =
        widget.hadith['themes'] as Map<String, dynamic>? ?? {};
    final theme = themes[lang] as String? ??
        themes['en'] as String? ??
        themes['id'] as String? ??
        widget.hadith['theme'] as String? ??
        '';
    final translations =
        widget.hadith['translations'] as Map<String, dynamic>? ?? {};
    final narrators = widget.hadith['narrators'] as Map<String, dynamic>? ?? {};

    final translationText = translations[lang] as String? ??
        translations['en'] as String? ??
        translations['id'] as String? ??
        '';
    final narratorText = narrators[lang] as String? ??
        narrators['en'] as String? ??
        narrators['id'] as String? ??
        '';

    final isRead = appState.isHadithRead(hadithId);
    final currentPoints = _pointsEarned;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Hadits #$hadithId",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${appState.points} ${Translations.get(lang, 'points')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Sticky Reading Progress & Eye Detection Bar
            Container(
              color: Colors.teal.shade800,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasCompleted
                                ? Icons.check_circle_rounded
                                : Icons.visibility_rounded,
                            color: _hasCompleted
                                ? Colors.amber
                                : (_isEyeFocused
                                    ? const Color(0xFF4ADE80)
                                    : Colors.orange.shade300),
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hasCompleted
                                ? Translations.get(lang, 'reading_done')
                                : (_isEyeFocused
                                    ? Translations.get(lang, 'silent_reading')
                                    : (lang == 'en' ? 'Focus Paused' : 'Fokus Dijeda')),
                            style: TextStyle(
                              color: _hasCompleted
                                  ? Colors.amber
                                  : (_isEyeFocused
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : Colors.orange.shade200),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(_readingProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _readingProgress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _hasCompleted
                            ? Colors.amber
                            : (_isEyeFocused
                                ? const Color(0xFF4ADE80)
                                : Colors.orange),
                      ),
                    ),
                  ),
                  if (!_hasCompleted && _isCameraSupported) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _isEyeFocused
                            ? Colors.green.shade900.withValues(alpha: 0.6)
                            : Colors.red.shade900.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getFocusText(lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _isEyeFocused
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFCA5A5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Hadith Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade900.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: isRead
                              ? Colors.teal.shade200
                              : Colors.teal.shade50,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Theme Tag Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  theme,
                                  style: TextStyle(
                                    color: Colors.teal.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+$currentPoints ${Translations.get(lang, 'points')}',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Arabic Matan
                          Text(
                            arabic,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 2.1,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002B24),
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 18),

                          // Translation in active language
                          Text(
                            '"$translationText"',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          if (narratorText.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 14,
                                      color: Colors.teal.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      narratorText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Next / Reading Progress Button
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: ElevatedButton(
                        onPressed: _hasCompleted ? _goToNextHadith : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          backgroundColor: _hasCompleted
                              ? const Color(0xFF0F5132)
                              : Colors.teal.shade50,
                          foregroundColor: _hasCompleted
                              ? Colors.white
                              : Colors.teal.shade800,
                          disabledBackgroundColor: Colors.teal.shade50,
                          disabledForegroundColor: Colors.teal.shade800,
                          elevation: _hasCompleted ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _hasCompleted
                                  ? Colors.transparent
                                  : Colors.teal.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasCompleted
                                  ? Icons.arrow_forward_rounded
                                  : Icons.auto_stories_rounded,
                              size: 18,
                              color: _hasCompleted
                                  ? Colors.white
                                  : Colors.teal.shade700,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _hasCompleted
                                      ? Translations.get(lang, 'next_hadith')
                                      : "${Translations.get(lang, 'reading_hadith_progress')} (${(_readingProgress * 100).toInt()}%) • +$currentPoints ${Translations.get(lang, 'points')}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: _hasCompleted
                                        ? Colors.white
                                        : Colors.teal.shade900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
