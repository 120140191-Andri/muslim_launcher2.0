import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../services/eye_tracker_service.dart';
import '../../utils/translations.dart';
import '../../services/analytics_service.dart';
import '../../utils/quran_progress_helper.dart';

class DzikirPreset {
  final int id;
  final String arabic;
  final String transliteration;
  final Map<String, String> translations;
  final Map<String, String> virtues;
  final String title;
  final int cooldownMs;

  const DzikirPreset({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translations,
    required this.virtues,
    required this.cooldownMs,
  });

  String getTranslation(String lang) {
    return translations[lang] ?? translations['en'] ?? translations['id'] ?? '';
  }

  String getVirtue(String lang) {
    return virtues[lang] ?? virtues['en'] ?? virtues['id'] ?? '';
  }
}

final List<DzikirPreset> kDzikirPresets = [
  const DzikirPreset(
    id: 1,
    title: 'Subhanallah',
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'Subhanallah',
    cooldownMs: 1000,
    translations: {
      'id': 'Maha Suci Allah',
      'en': 'Glory be to Allah',
      'ms': 'Maha Suci Allah',
      'ar': 'سُبْحَانَ اللَّهِ',
      'af': 'Eer aan Allah',
      'sw': 'Utukufu una Mwenyezi Mungu',
    },
    virtues: {
      'id': 'Ditanamkan satu pohon kurma di surga bagi yang membacanya. (HR. Tirmidzi)',
      'en': 'A palm tree is planted in Paradise for whoever recites it. (Tirmidhi)',
      'ms': 'Ditanamkan satu pohon kurma di syurga bagi yang membacanya. (HR. Tirmizi)',
      'ar': 'غرست له نخلة في الجنة (رواه الترمذي)',
      'af': '\'n Palmboom word in die Paradys geplant vir wie dit resiteer.',
      'sw': 'Mti wa mtende hupandwa Peponi kwa yeyote anayeisoma.',
    },
  ),
  const DzikirPreset(
    id: 2,
    title: 'Alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    cooldownMs: 1000,
    translations: {
      'id': 'Segala puji bagi Allah',
      'en': 'All praise is due to Allah',
      'ms': 'Segala puji bagi Allah',
      'ar': 'الْحَمْدُ لِلَّهِ',
      'af': 'Alle lof kom Allah toe',
      'sw': 'Sifa zote njema ni za Mwenyezi Mungu',
    },
    virtues: {
      'id': 'Memenuhi timbangan amal kebaikan di Hari Kiamat. (HR. Muslim)',
      'en': 'Fills the scale of good deeds on the Day of Resurrection. (Muslim)',
      'ms': 'Memenuhi timbangan amal kebaikan pada Hari Kiamat. (HR. Muslim)',
      'ar': 'الحمد لله تملأ الميزان (رواه مسلم)',
      'af': 'Vul die skaal van goeie dade op die Oordeelsdag.',
      'sw': 'Inajaza mizani ya matendo mema Siku ya Qiyama.',
    },
  ),
  const DzikirPreset(
    id: 3,
    title: 'Allahu Akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    cooldownMs: 1000,
    translations: {
      'id': 'Allah Maha Besar',
      'en': 'Allah is the Greatest',
      'ms': 'Allah Maha Besar',
      'ar': 'اللَّهُ أَكْبَرُ',
      'af': 'Allah is die Grootste',
      'sw': 'Mwenyezi Mungu ni Mkuu',
    },
    virtues: {
      'id': 'Kalimat agung pengakuan kebesaran Allah yang dicintai Ar-Rahman.',
      'en': 'Sublime declaration of Allah\'s supremacy beloved to the Most Merciful.',
      'ms': 'Kalimah agung pengakuan kebesaran Allah yang dicintai Ar-Rahman.',
      'ar': 'كلمة عظيمة لتعظيم الله وإجلاله',
      'af': 'Verhewe verklaring van Allah se grootheid.',
      'sw': 'Tamko kuu la kutambua ukuu wa Mwenyezi Mungu.',
    },
  ),
  const DzikirPreset(
    id: 4,
    title: 'Astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    transliteration: 'Astaghfirullah',
    cooldownMs: 1200,
    translations: {
      'id': 'Aku memohon ampun kepada Allah',
      'en': 'I seek forgiveness from Allah',
      'ms': 'Aku memohon keampunan kepada Allah',
      'ar': 'أَسْتَغْفِرُ اللَّهَ',
      'af': 'Ek soek vergifnis by Allah',
      'sw': 'Naomba msamaha kwa Mwenyezi Mungu',
    },
    virtues: {
      'id': 'Membuka pintu rezeki, menghapus dosa, dan memberi ketenangan jiwa.',
      'en': 'Opens the doors of sustenance, erases sins, and brings inner peace.',
      'ms': 'Membuka pintu rezeki, menghapuskan dosa, dan memberikan ketenangan jiwa.',
      'ar': 'يفتح أبواب الرزق ويغفر الذنوب ويشرح الصدر',
      'af': 'Maak deure van voorspoed oop en wis sondes uit.',
      'sw': 'Hufungua milango ya riziki na kufuta dhambi.',
    },
  ),
  const DzikirPreset(
    id: 5,
    title: 'Laa Ilaha Illallah',
    arabic: 'لَا إِلَهَ إِلَّا اللَّهُ',
    transliteration: 'Laa ilaha illallah',
    cooldownMs: 1800,
    translations: {
      'id': 'Tiada Tuhan selain Allah',
      'en': 'There is no god but Allah',
      'ms': 'Tiada Tuhan melainkan Allah',
      'ar': 'لَا إِلَهَ إِلَّا اللَّهُ',
      'af': 'Daar is geen god behalwe Allah nie',
      'sw': 'Hapana mungu ila Mwenyezi Mungu',
    },
    virtues: {
      'id': 'Dzikir yang paling utama dan kunci utama pintu surga. (HR. Tirmidzi)',
      'en': 'The most superior dhikr and the key to Paradise. (Tirmidhi)',
      'ms': 'Zikir yang paling utama dan kunci utama pintu syurga. (HR. Tirmizi)',
      'ar': 'أفضل الذكر لا إله إلا الله (رواه الترمذي)',
      'af': 'Die voortreflikste gedenking en die sleutel tot die Paradys.',
      'sw': 'Dhikri bora zaidi na ufunguo mkuu wa Pepo.',
    },
  ),
  const DzikirPreset(
    id: 6,
    title: 'Shalawat Nabi',
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    transliteration: 'Allahumma Shalli \'Ala Muhammad',
    cooldownMs: 2000,
    translations: {
      'id': 'Ya Allah limpahkanlah shalawat kepada Nabi Muhammad',
      'en': 'O Allah, send blessings upon Muhammad',
      'ms': 'Ya Allah kurniakanlah selawat ke atas Nabi Muhammad',
      'ar': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
      'af': 'O Allah, stuur seëninge oor Mohammed',
      'sw': 'Ee Mwenyezi Mungu, mswalie Muhammad',
    },
    virtues: {
      'id': 'Allah bershalawat 10 kali dan mengangkat 10 derajat bagi pembacanya. (HR. Muslim)',
      'en': 'Allah sends blessings tenfold and elevates ten ranks for the reciter. (Muslim)',
      'ms': 'Allah berselawat 10 kali dan mengangkat 10 darjat bagi pembacanya. (HR. Muslim)',
      'ar': 'من صلى علي واحدة صلى الله عليه بها عشرا (رواه مسلم)',
      'af': 'Allah seën hom tienvoudig en verhef hom tien grade.',
      'sw': 'Mwenye kumswalia mara moja, Mwenyezi Mungu humswalia mara kumi.',
    },
  ),
  const DzikirPreset(
    id: 7,
    title: 'Hauqalah',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    transliteration: 'Laa hawla wa laa quwwata illa billah',
    cooldownMs: 2500,
    translations: {
      'id': 'Tiada daya dan kekuatan kecuali dengan pertolongan Allah',
      'en': 'There is no power nor strength except through Allah',
      'ms': 'Tiada daya dan upaya melainkan dengan pertolongan Allah',
      'ar': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      'af': 'Daar is geen krag of mag behalwe deur Allah nie',
      'sw': 'Hakuna hila wala nguvu ila kwa msaada wa Mwenyezi Mungu',
    },
    virtues: {
      'id': 'Merupakan salah satu harta simpanan yang berharga di surga. (HR. Bukhari)',
      'en': 'It is one of the cherished treasures of Paradise. (Bukhari)',
      'ms': 'Merupakan salah satu khazanah simpanan yang berharga di syurga. (HR. Bukhari)',
      'ar': 'كنز من كنوز الجنة (رواه البخاري ومسلم)',
      'af': '\'n Kosbare skat uit die skatte van die Paradys.',
      'sw': 'Hazina miongoni mwa hazina za Peponi.',
    },
  ),
  const DzikirPreset(
    id: 8,
    title: 'Hasbunallah',
    arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
    transliteration: 'Hasbunallahu wa ni\'mal wakeel',
    cooldownMs: 2000,
    translations: {
      'id': 'Cukuplah Allah menjadi Penolong kami dan Dia sebaik-baik Pelindung',
      'en': 'Allah is sufficient for us, and He is the best Disposer of affairs',
      'ms': 'Cukuplah Allah sebagai Penolong kami dan Dia sebaik-baik Pelindung',
      'ar': 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      'af': 'Allah is voldoende vir ons, en Hy is die beste Beskermer',
      'sw': 'Mwenyezi Mungu anatutosha, naye ni Mbora wa kutegemewa',
    },
    virtues: {
      'id': 'Doa perlindungan agung Nabi Ibrahim AS dan Rasulullah SAW saat menghadapi kesulitan.',
      'en': 'The great supplication of Prophet Ibrahim and Prophet Muhammad in hardship.',
      'ms': 'Doa perlindungan agung Nabi Ibrahim AS dan Rasulullah SAW ketika menghadapi kesukaran.',
      'ar': 'دعاء عظيم للأمان والتوكل على الله',
      'af': 'Magtige smeekgebed van vrome profete in beproewing.',
      'sw': 'Dua tukufu ya ulinzi na kumtegemea Mwenyezi Mungu.',
    },
  ),
];

class DzikirScreen extends StatefulWidget {
  const DzikirScreen({super.key});

  @override
  State<DzikirScreen> createState() => _DzikirScreenState();
}

class _DzikirScreenState extends State<DzikirScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _selectedPresetIndex = 0;
  int _count = 0;
  DateTime? _roundStartTime;
  final int _target = 33;
  int _lastTapTime = 0;
  bool _isFacePresent = false;
  bool _isCameraReady = false;
  bool _isInCooldown = false;
  bool _isRequestingPermission = false;
  String _rateLimitMessage = '';
  Timer? _rateLimitClearTimer;
  StreamSubscription<bool>? _presenceSub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _cooldownController;
  late Animation<double> _cooldownAnimation;

  // Spiritual Energy Session Tracking
  double? _sessionStartProgress;
  int _sessionDzikirTotal = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionStartProgress == null) {
      final appState = Provider.of<AppState>(context, listen: false);
      _sessionStartProgress = QuranProgressHelper.getCombinedSpiritualProgress(
        khatmCount: appState.khatmCount,
        currentSurahIndex: appState.currentSurahIndex,
        currentAyahNumber: appState.lastReadAyahNumber,
        quranData: appState.quranData,
        totalDzikirCount: appState.totalDzikirCount,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('DzikirScreen');
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cooldownController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: kDzikirPresets[_selectedPresetIndex].cooldownMs),
    );
    _cooldownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cooldownController, curve: Curves.linear),
    );

    _cooldownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isInCooldown = false;
          });
          // Option 4: Micro-haptic tick when ready (so users with eyes closed know cooldown is finished)
          HapticFeedback.selectionClick();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initFaceTracker();
      }
    });
  }

  Future<void> _initFaceTracker() async {
    if (!mounted) return;
    try {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        _isRequestingPermission = true;
        final requested = await Permission.camera.request();
        _isRequestingPermission = false;
        if (!requested.isGranted) {
          if (mounted) {
            setState(() {
              _isCameraReady = false;
              _isFacePresent = true; // Fallback to graceful mode
            });
          }
          return;
        }
      }

      await EyeTrackerService().initialize();
      if (!mounted) return;

      setState(() {
        _isCameraReady = EyeTrackerService().isCameraReady;
        _isFacePresent = EyeTrackerService().isFacePresent;
      });

      _presenceSub?.cancel();
      _presenceSub = EyeTrackerService().facePresenceStream?.listen((present) {
        if (!mounted) return;
        setState(() {
          _isFacePresent = present;
        });
      });
    } catch (e) {
      debugPrint("Dzikir camera init error: $e");
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _isFacePresent = true; // Fallback to graceful mode
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isRequestingPermission) {
        _initFaceTracker();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (!_isRequestingPermission) {
        _presenceSub?.cancel();
        EyeTrackerService().dispose();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rateLimitClearTimer?.cancel();
    _presenceSub?.cancel();
    _pulseController.dispose();
    _cooldownController.dispose();
    EyeTrackerService().dispose();

    if (_sessionDzikirTotal > 0) {
      try {
        final appState = Provider.of<AppState>(context, listen: false);
        // Persist any partial round taps that were not saved in onCompletedRound
        final uncompletedTaps = _count % _target;
        if (uncompletedTaps > 0) {
          appState.addDzikirCount(uncompletedTaps);
        }
        final currentProgress = QuranProgressHelper.getCombinedSpiritualProgress(
          khatmCount: appState.khatmCount,
          currentSurahIndex: appState.currentSurahIndex,
          currentAyahNumber: appState.lastReadAyahNumber,
          quranData: appState.quranData,
          totalDzikirCount: appState.totalDzikirCount,
        );
        appState.triggerSpiritualEnergy(
          previousProgress: _sessionStartProgress ?? currentProgress,
          targetProgress: currentProgress,
          source: 'dzikir',
          itemsCount: _sessionDzikirTotal,
        );
      } catch (_) {}
    }

    super.dispose();
  }

  void _onTapTasbih() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lang = Provider.of<AppState>(context, listen: false).languageCode;

    // Check Face Presence (if camera is working)
    if (_isCameraReady && !_isFacePresent) {
      // NO vibration on invalid
      _showRateLimitBanner(Translations.get(lang, 'dzikir_face_not_detected'));
      return;
    }

    // Cooldown check: dynamic based on current preset length
    final currentPreset = kDzikirPresets[_selectedPresetIndex];
    if (now - _lastTapTime < currentPreset.cooldownMs) {
      // NO vibration on invalid
      _showRateLimitBanner(Translations.get(lang, 'dzikir_too_fast'));
      return;
    }

    // Valid Tap: Trigger distinct vibration!
    _lastTapTime = now;
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) {
      if (mounted) _pulseController.reverse();
    });

    // Start radial cooldown animation
    _cooldownController.duration = Duration(milliseconds: currentPreset.cooldownMs);
    _cooldownController.forward(from: 0.0);

    _roundStartTime ??= DateTime.now();

    _sessionDzikirTotal++;

    setState(() {
      _isInCooldown = true;
      _count++;
      _rateLimitMessage = '';
    });

    if (_count >= _target) {
      _onCompletedRound();
    }
  }

  void _showRateLimitBanner(String message) {
    _rateLimitClearTimer?.cancel();
    setState(() {
      _rateLimitMessage = message;
    });
    _rateLimitClearTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _rateLimitMessage = '';
        });
      }
    });
  }

  void _onCompletedRound() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;
    final currentPreset = kDzikirPresets[_selectedPresetIndex];

    final result = await appState.saveDzikirProgress(
      currentPreset.title,
      _target,
      10,
    );
    final pointsEarned = result['pointsEarned'] as int? ?? 0;
    final roundNumber = result['round'] as int? ?? 1;

    final durationSeconds = _roundStartTime != null
        ? DateTime.now().difference(_roundStartTime!).inSeconds
        : 0;
    _roundStartTime = null;

    AnalyticsService.logDzikirCompleted(
      dzikirTitle: currentPreset.title,
      dzikirTransliteration: currentPreset.transliteration,
      dzikirArabic: currentPreset.arabic,
      targetCount: _target,
      pointsEarned: pointsEarned,
      durationSeconds: durationSeconds,
    );

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.stars_rounded,
                      color: colorScheme.onTertiaryContainer,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    Translations.get(lang, 'dzikir_completed_congrats'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      pointsEarned > 0
                          ? '+$pointsEarned ${Translations.get(lang, 'points')} (Putaran $roundNumber/3)'
                          : 'Putaran ke-$roundNumber (Batas 3 putaran poin tercapai, tasbih tetap tercatat)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _cooldownController.reset();
                        setState(() {
                          _count = 0;
                          _roundStartTime = null;
                          _isInCooldown = false;
                          _rateLimitMessage = '';
                        });
                        _openDzikirSelector();
                      },
                      icon: const Icon(Icons.grain_rounded, size: 18),
                      label: Text(
                        Translations.get(lang, 'choose_other_dzikir'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _cooldownController.reset();
                        setState(() {
                          _count = 0;
                          _roundStartTime = null;
                          _isInCooldown = false;
                          _rateLimitMessage = '';
                        });
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        Translations.get(lang, 'repeat_this_dzikir'),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDzikirSelector() {
    final lang = Provider.of<AppState>(context, listen: false).languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.grain_rounded, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          Translations.get(lang, 'change_dzikir'),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: kDzikirPresets.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = kDzikirPresets[idx];
                      final isSelected = idx == _selectedPresetIndex;

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(alpha: 0.5),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            _cooldownController.reset();
                            setState(() {
                              _selectedPresetIndex = idx;
                              _count = 0;
                              _roundStartTime = null;
                              _isInCooldown = false;
                              _rateLimitMessage = '';
                            });
                            Navigator.pop(ctx);
                          },
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? colorScheme.primary
                                : colorScheme.surfaceContainerHighest,
                            child: Text(
                              "${idx + 1}",
                              style: TextStyle(
                                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.getTranslation(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            item.arabic,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = appState.languageCode;
    final currentPreset = kDzikirPresets[_selectedPresetIndex];
    final progress = (_count / _target).clamp(0.0, 1.0);
    final screenHeight = MediaQuery.of(context).size.height;
    final beadSize = (screenHeight * 0.20).clamp(140.0, 185.0);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 2,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translations.get(lang, 'dzikir_mode_title'),
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: Translations.get(lang, 'reset_counter'),
            icon: Icon(Icons.refresh_rounded, color: colorScheme.onSurfaceVariant),
            onPressed: () {
              _cooldownController.reset();
              setState(() {
                _count = 0;
                _roundStartTime = null;
                _isInCooldown = false;
                _rateLimitMessage = '';
              });
            },
          ),
          IconButton(
            tooltip: Translations.get(lang, 'change_dzikir'),
            icon: Icon(Icons.format_list_bulleted_rounded, color: colorScheme.onSurfaceVariant),
            onPressed: _openDzikirSelector,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Face Presence Status Pill Indicator (M3 Expressive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isFacePresent
                                ? colorScheme.primaryContainer
                                : colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isFacePresent
                                  ? colorScheme.primary.withValues(alpha: 0.5)
                                  : colorScheme.tertiary.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFacePresent
                                    ? Icons.visibility_rounded
                                    : Icons.face_retouching_off_rounded,
                                size: 16,
                                color: _isFacePresent
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onTertiaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _isFacePresent
                                      ? Translations.get(lang, 'dzikir_face_detected')
                                      : Translations.get(lang, 'dzikir_face_not_detected'),
                                  style: TextStyle(
                                    color: _isFacePresent
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onTertiaryContainer,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Rate Limit Warning Badge
                        AnimatedOpacity(
                          opacity: _rateLimitMessage.isNotEmpty ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.error.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _rateLimitMessage,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Arabic & Latin Main Dzikir Display Card (Option 1: Emerald Sanctuary)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isInCooldown
                                  ? [
                                      const Color(0xFF1E3A2F),
                                      const Color(0xFF142B22),
                                    ]
                                  : [
                                      const Color(0xFF0F5E3B),
                                      const Color(0xFF094027),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: _isInCooldown ? 0.08 : 0.15),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isInCooldown
                                    ? Colors.black.withValues(alpha: 0.06)
                                    : const Color(0xFF0D5C3A).withValues(alpha: 0.28),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Arabic Matan Display
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 250),
                                opacity: _isInCooldown ? 0.45 : 1.0,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    currentPreset.arabic,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFBFDFC),
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Amiri',
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Latin Transliteration Pill (Frosted glass effect)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  currentPreset.transliteration,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Translation
                              Text(
                                "\"${currentPreset.getTranslation(lang)}\"",
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 12),

                        // Large Interactive Circular Tasbih Tap Bead (M3 Expressive)
                        GestureDetector(
                          onTap: _onTapTasbih,
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: AnimatedBuilder(
                              animation: _cooldownAnimation,
                              builder: (context, child) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: beadSize,
                                  height: beadSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: _isInCooldown
                                          ? [
                                              colorScheme.surfaceContainerHigh,
                                              colorScheme.surfaceContainerHighest,
                                            ]
                                          : [
                                              colorScheme.primary,
                                              colorScheme.primary.withValues(alpha: 0.85),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _isInCooldown
                                            ? Colors.black.withValues(alpha: 0.04)
                                            : colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: _isInCooldown ? 12 : 28,
                                        spreadRadius: _isInCooldown ? 1 : 4,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Target Progress Ring
                                      SizedBox(
width: beadSize - 10,
                                        height: beadSize - 10,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 7,
                                          backgroundColor: _isInCooldown
                                              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                                              : Colors.white.withValues(alpha: 0.2),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _isInCooldown
                                                ? colorScheme.outline
                                                : Colors.white,
                                          ),
                                        ),
                                      ),

                                      // Radial Cooldown Arc
                                      if (_isInCooldown)
                                        SizedBox(
                                          width: beadSize - 2,
                                          height: beadSize - 2,
                                          child: CircularProgressIndicator(
                                            value: _cooldownAnimation.value,
                                            strokeWidth: 3.5,
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              colorScheme.tertiary,
                                            ),
                                          ),
                                        ),

                                      // Counter
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "$_count",
                                            style: TextStyle(
                                              color: _isInCooldown
                                                  ? colorScheme.onSurfaceVariant
                                                  : Colors.white,
                                              fontSize: (beadSize * 0.26).clamp(36.0, 48.0),
                                              fontWeight: FontWeight.bold,
                                              height: 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "/ $_target",
                                            style: TextStyle(
                                              color: _isInCooldown
                                                  ? colorScheme.outline
                                                  : Colors.white.withValues(alpha: 0.7),
                                              fontSize: (beadSize * 0.085).clamp(12.0, 15.0),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          Translations.get(lang, 'dzikir_tap_instruction'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 12),

                        // Virtue (Fadhilah) Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: colorScheme.tertiary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      lang == 'id' ? 'FADHILAH / KEUTAMAAN' : 'VIRTUE OF DHIKR',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.tertiary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _openDzikirSelector,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            Translations.get(lang, 'change_dzikir'),
                                            style: TextStyle(
                                              color: colorScheme.onPrimaryContainer,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: colorScheme.onPrimaryContainer,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentPreset.getVirtue(lang),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
