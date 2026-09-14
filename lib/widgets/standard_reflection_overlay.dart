import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../screens/onboarding/mode_selection_screen.dart';
import '../utils/page_transitions.dart';
import '../utils/quran_progress_helper.dart';
import '../utils/translations.dart';

class StandardReflectionOverlay extends StatelessWidget {
  const StandardReflectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final isEn = lang == 'en';

    // 1. Calculate stats
    int totalAyahsRead = 0;
    if (appState.quranData.isNotEmpty) {
      for (int i = 0;
          i < appState.highestSurahIndex && i < appState.quranData.length;
          i++) {
        totalAyahsRead += (appState.quranData[i]['total_ayah'] as int? ?? 0);
      }
      totalAyahsRead += (appState.highestAyahIndex + 1).clamp(0, 300);
    }
    if (appState.khatmCount > 0) {
      totalAyahsRead +=
          appState.khatmCount * QuranProgressHelper.totalQuranAyahs;
    }

    final int streakDays =
        math.max(appState.quranDailyStreak, appState.dzikirDailyStreak);
    final String dzikirFormatted =
        NumberFormat.decimalPattern(isEn ? 'en' : 'id')
            .format(appState.totalDzikirCount);
    final String ayahsFormatted =
        NumberFormat.decimalPattern(isEn ? 'en' : 'id').format(totalAyahsRead);

    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF063E2A),
                    Color(0xFF032217),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Icon with soft golden-emerald aura
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.3),
                            const Color(0xFF047857).withValues(alpha: 0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF34D399).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        color: Color(0xFF34D399),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Title
                    Text(
                      Translations.get(lang, 'reflection_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      Translations.get(lang, 'reflection_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Milestone Highlights Grid
                    Row(
                      children: [
                        // Card 1: Quran Reading
                        Expanded(
                          child: _buildMilestoneCard(
                            icon: Icons.menu_book_rounded,
                            iconColor: const Color(0xFF34D399),
                            value: ayahsFormatted,
                            label: Translations.get(lang, 'reflection_quran_read'),
                            badge: appState.khatmCount > 0
                                ? "${appState.khatmCount}x Khatam"
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Card 2: Dzikir Tasbih
                        Expanded(
                          child: _buildMilestoneCard(
                            icon: Icons.fingerprint_rounded,
                            iconColor: const Color(0xFF6EE7B7),
                            value: dzikirFormatted,
                            label: Translations.get(lang, 'reflection_dzikir_count'),
                            badge: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Card 3: Daily Streak
                        Expanded(
                          child: _buildMilestoneCard(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            value: "$streakDays",
                            label: Translations.get(lang, 'reflection_streak_days'),
                            badge: streakDays > 0 ? "🔥 Istiqomah" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Card 4: Spiritual Points
                        Expanded(
                          child: _buildMilestoneCard(
                            icon: Icons.military_tech_rounded,
                            iconColor: const Color(0xFFFBBF24),
                            value: "${appState.points}",
                            label: Translations.get(lang, 'reflection_points_earned'),
                            badge: appState.claimedBadgeIds.isNotEmpty
                                ? "${appState.claimedBadgeIds.length} Lencana"
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Strict Mode Hero Card / Offer Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF065F46).withValues(alpha: 0.85),
                            const Color(0xFF042F2E).withValues(alpha: 0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  Translations.get(
                                      lang, 'reflection_strict_offer_badge'),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF451A03),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.shield_rounded,
                                color: Color(0xFFFBBF24),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Translations.get(lang, 'reflection_strict_offer_title'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Translations.get(lang, 'reflection_strict_offer_desc'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Activate Strict Mode Primary Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                appState.clearStandardReflection();
                                Navigator.of(context).push(
                                  AppPageRoute(
                                    child: const ModeSelectionScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: const Color(0xFF451A03),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.lock_clock_rounded, size: 18),
                              label: Text(
                                Translations.get(
                                    lang, 'reflection_activate_strict_btn'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stay & Return Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => appState.clearStandardReflection(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          Translations.get(lang, 'reflection_stay_in_launcher'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Skip & Continue to Settings Button (Mode Standar perk)
                    TextButton(
                      onPressed: () {
                        appState.dismissStandardReflectionAndSkip(
                            durationMillis: 180000);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.65),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Translations.get(lang, 'reflection_skip_btn'),
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
