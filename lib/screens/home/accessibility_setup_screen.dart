import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'home_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/device_instructions.dart';

class AccessibilitySetupScreen extends StatefulWidget {
  final bool isOnboarding;
  const AccessibilitySetupScreen({super.key, this.isOnboarding = false});

  @override
  State<AccessibilitySetupScreen> createState() =>
      _AccessibilitySetupScreenState();
}

class _AccessibilitySetupScreenState extends State<AccessibilitySetupScreen>
    with WidgetsBindingObserver {
  bool _isEnabled = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  Future<void> _checkStatus() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final enabled = await appState.appBlockService.isAccessibilityEnabled();
    if (mounted && enabled != _isEnabled) {
      setState(() => _isEnabled = enabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final manufacturer = appState.manufacturer;
    final isEn = lang == 'en';

    final instructions =
        DeviceInstructions.getAccessibilityInstructions(manufacturer, lang);
    final brandDisplay = manufacturer.isNotEmpty
        ? manufacturer[0].toUpperCase() + manufacturer.substring(1)
        : "";

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Emerald Gradient Header ─────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F5E3B),
                    Color(0xFF083C25),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D5C3A).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      // Top Row with Back Button
                      Row(
                        children: [
                          if (!widget.isOnboarding)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.maybePop(context),
                            )
                          else
                            const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isEn ? 'App Blocker Setup' : 'Keamanan Fokus',
                              textAlign: widget.isOnboarding ? TextAlign.center : TextAlign.start,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (!widget.isOnboarding)
                            const SizedBox(width: 48)
                          else
                            const SizedBox(width: 4),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Status Icon
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isEnabled
                              ? Icons.verified_user_rounded
                              : Icons.app_blocking_rounded,
                          color: _isEnabled ? const Color(0xFF34D399) : Colors.amber,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isEnabled
                            ? (isEn ? 'Ready to Focus!' : 'Siap Beribadah!')
                            : (isEn ? 'Enable App Blocker' : 'Aktifkan Fokus'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _isEnabled
                              ? (isEn
                                  ? 'Muslim Launcher will help you stay away from distractions.'
                                  : 'Aplikasi akan otomatis membatasi gangguan saat Anda sedang belajar Al-Quran.')
                              : (isEn
                                  ? 'To block disruptive apps, we need your permission in Accessibility settings.'
                                  : 'Agar fitur pembatas gangguan bekerja, kami perlu izin di menu Aksesibilitas HP Anda.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isEnabled) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF0D5C3A),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isEn
                                ? "FOR YOUR $brandDisplay DEVICE:"
                                : "PETUNJUK HP $brandDisplay:",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontSize: 12,
                              color: Color(0xFF0D5C3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: List.generate(instructions.length, (index) {
                          return _buildFancyStep(
                            index + 1,
                            instructions[index],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Colors.amber.shade900,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DeviceInstructions.getAccessibilityTip(lang),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () =>
                          appState.appBlockService.openAccessibilitySettings(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: _isEnabled
                            ? Colors.white
                            : const Color(0xFF0D5C3A),
                        foregroundColor: _isEnabled
                            ? const Color(0xFF0D5C3A)
                            : Colors.white,
                        elevation: _isEnabled ? 0 : 2,
                        shadowColor: const Color(0xFF0D5C3A).withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _isEnabled
                                ? const Color(0xFF0D5C3A).withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isEnabled
                              ? (isEn
                                    ? 'Adjust Settings'
                                    : 'Buka Pengaturan Lagi')
                              : (isEn
                                    ? 'Open Settings Now'
                                    : 'Buka Pengaturan Sekarang'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_isEnabled) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F5E3B), Color(0xFF094027)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D5C3A).withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (widget.isOnboarding) {
                              appState.completeOnboarding();
                              appState.navigatorKey.currentState?.pushAndRemoveUntil(
                                  AppPageRoute(child: const HomeScreen()),
                                  (route) => false);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEn ? 'CONTINUE' : 'LANJUTKAN',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFancyStep(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0D5C3A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$num",
              style: const TextStyle(
                color: Color(0xFF0D5C3A),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF374151),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
