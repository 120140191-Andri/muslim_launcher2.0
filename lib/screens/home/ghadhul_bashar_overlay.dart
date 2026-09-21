import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/ghadhul_bashar_data.dart';
import '../../utils/translations.dart';

class GhadhulBasharOverlay extends StatefulWidget {
  final String packageName;

  const GhadhulBasharOverlay({super.key, required this.packageName});

  @override
  State<GhadhulBasharOverlay> createState() => _GhadhulBasharOverlayState();
}

class _GhadhulBasharOverlayState extends State<GhadhulBasharOverlay>
    with SingleTickerProviderStateMixin {
  late final GhadhulBasharVerse _verse;
  bool _isProcessing = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _isSocialGroup = false;
  bool _hasCheckedSocialGroup = false;

  @override
  void initState() {
    super.initState();
    _verse = GhadhulBasharData.getRandomVerse();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -12.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -12.0, end: 12.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 12.0, end: -9.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -9.0, end: 9.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 9.0, end: -5.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -5.0, end: 5.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_shakeController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedSocialGroup) {
      _hasCheckedSocialGroup = true;
      final appState = Provider.of<AppState>(context, listen: false);
      final extra = appState.lastAttemptedGhadhulBasharExtra;
      final pkg = widget.packageName.toLowerCase();
      _isSocialGroup = extra == 'social_group_link' ||
          pkg.contains('whatsapp') ||
          pkg.contains('telegram') ||
          pkg.contains('t.me');

      if (_isSocialGroup) {
        _countdownSeconds = 5;
        // Trigger initial wobble so the user immediately notices the ayah translation
        _shakeController.forward(from: 0.0);
        // Start 5-second countdown timer
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            if (_countdownSeconds > 1) {
              _countdownSeconds--;
              // Wobble again to draw focus to the translation text
              if (_countdownSeconds % 2 == 1) {
                _shakeController.forward(from: 0.0);
              }
            } else {
              _countdownSeconds = 0;
              timer.cancel();
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _safeDismiss(AppState appState) {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    appState.clearGhadhulBashar();
  }

  Future<void> _safeProceed(AppState appState) async {
    if (_isProcessing || _countdownSeconds > 0) return;
    setState(() => _isProcessing = true);
    await appState.confirmGhadhulBashar(widget.packageName);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _safeDismiss(appState);
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: const Color(0xFF031E1B),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF063E36),
                  Color(0xFF031E1B),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top Navigation Header (Kembali & Home)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _isProcessing ? null : () => _safeDismiss(appState),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: _isProcessing ? null : () => _safeDismiss(appState),
                            icon: const Icon(Icons.home_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Eye / Guard Icon Badge
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _isSocialGroup
                              ? Colors.amber.withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isSocialGroup
                                ? Colors.amber.withValues(alpha: 0.45)
                                : const Color(0xFF10B981).withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isSocialGroup
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : const Color(0xFF10B981).withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isSocialGroup
                              ? Icons.security_rounded
                              : Icons.visibility_off_rounded,
                          size: 48,
                          color: _isSocialGroup
                              ? Colors.amber.shade300
                              : const Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        Translations.get(lang, 'ghadhul_bashar_title'),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        Translations.get(lang, 'ghadhul_bashar_subtitle'),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // App Name target info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: Colors.teal.shade200,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appState.getAppNameSync(widget.packageName),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Social Group Link Warning Banner
                      if (_isSocialGroup) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade900.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amber.shade400.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade300,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Translations.get(lang, 'social_group_warning_title'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade200,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Translations.get(lang, 'social_group_warning_subtitle'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Surah Reference Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF34D399).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _verse.getReference(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Arabic Verse & Translation Card with Wobble / Shake Animation
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: _isSocialGroup
                                ? const Color(0xFF042D26).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _isSocialGroup
                                  ? Colors.amber.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: _isSocialGroup ? 1.5 : 1.0,
                            ),
                            boxShadow: _isSocialGroup
                                ? [
                                    BoxShadow(
                                      color: Colors.amber.withValues(alpha: 0.18),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                _verse.arabic,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD1FAE5),
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.1),
                                height: 1,
                              ),
                              const SizedBox(height: 12),
                              if (_isSocialGroup) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.menu_book_rounded, size: 14, color: Colors.amber.shade200),
                                      const SizedBox(width: 6),
                                      Text(
                                        Translations.get(lang, 'social_group_continue_wait') == 'Lanjutkan'
                                            ? 'Bacalah Terjemahan & Renungkan:'
                                            : 'Read Translation & Ponder:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade200,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Text(
                                "\"${_verse.getTranslation(lang)}\"",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontStyle: FontStyle.italic,
                                  color: _isSocialGroup
                                      ? Colors.amber.shade100
                                      : Colors.white.withValues(alpha: 0.85),
                                  height: 1.45,
                                  fontWeight: _isSocialGroup ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons: Batal & Lanjutkan
                      Row(
                        children: [
                          // Batal Button (always available immediately)
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isProcessing ? null : () => _safeDismiss(appState),
                              child: Text(
                                Translations.get(lang, 'cancel'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Lanjutkan Button (with 5-second countdown lock for social group links)
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _countdownSeconds > 0
                                    ? Colors.grey.shade800
                                    : const Color(0xFF059669),
                                foregroundColor: _countdownSeconds > 0
                                    ? Colors.white54
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: (_isProcessing || _countdownSeconds > 0)
                                  ? null
                                  : () => _safeProceed(appState),
                              icon: _countdownSeconds > 0
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.amberAccent,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text(
                                _countdownSeconds > 0
                                    ? "${Translations.get(lang, 'ok')} (${_countdownSeconds}s)"
                                    : Translations.get(lang, 'ok'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
