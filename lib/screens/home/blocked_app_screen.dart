import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../quran/surah_list_screen.dart';
import '../hadith/hadith_list_screen.dart';
import '../dzikir/dzikir_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';
import '../../utils/quran_progress_helper.dart';
import '../../services/ad_service.dart';

class BlockedAppScreen extends StatefulWidget {
  final String packageName;
  final bool isRoute;

  const BlockedAppScreen({
    super.key,
    required this.packageName,
    this.isRoute = false,
  });

  @override
  State<BlockedAppScreen> createState() => _BlockedAppScreenState();
}

class _BlockedAppScreenState extends State<BlockedAppScreen> {
  bool _isUnlocking = false;
  bool _showConfirmProductive = false;
  Future<bool?> _showAdConfirmationDialog({
    required BuildContext context,
    required String lang,
    required int cost,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isId = lang == 'id';
        final isMs = lang == 'ms';
        final isAr = lang == 'ar';

        final title = isId
            ? 'Batas Harian Tercapai (3x)'
            : isMs
                ? 'Had Harian Dicapai (3x)'
                : isAr
                    ? 'تم الوصول إلى الحد اليومي (٣ مرات)'
                    : 'Daily Limit Reached (3x)';

        final desc = isId
            ? 'Kamu telah membuka aplikasi non-produktif 3 kali hari ini. Tonton 1 video singkat untuk mendapatkan tiket akses selama 10 menit (tetap menggunakan $cost poin).'
            : isMs
                ? 'Anda telah membuka aplikasi bukan produktif 3 kali hari ini. Tonton 1 video pendek untuk mendapatkan tiket akses selama 10 minit (tetap menggunakan $cost mata).'
                : isAr
                    ? 'لقد فتحت تطبيقات غير منتجة ٣ مرات اليوم. شاهد مقطع فيديو قصير للحصول على تصريح وصول لمدة ١٠ دقائق (لا يزال يستهلك $cost نقطة).'
                    : 'You have opened non-productive apps 3 times today. Watch a short video to get a 10-minute access pass (still requires $cost points).';

        final btnWatch = isId
            ? 'Tonton Iklan & Buka'
            : isMs
                ? 'Tonton Iklan & Buka'
                : isAr
                    ? 'شاهد الإعلان وافتح'
                    : 'Watch Ad & Unlock';

        final btnCancel = isId
            ? 'Batal'
            : isMs
                ? 'Batal'
                : isAr
                    ? 'إلغاء'
                    : 'Cancel';

        return AlertDialog(
          backgroundColor: const Color(0xFF06332E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.ondemand_video_rounded, color: Colors.amber, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(btnCancel, style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(btnWatch, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  void _safeDismiss(AppState appState) {
    if (_isUnlocking) return;
    if (_showConfirmProductive) {
      setState(() => _showConfirmProductive = false);
      return;
    }
    appState.clearBlockedApp();
    if (widget.isRoute && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final unlockCost = appState.currentUnlockCost;
    final canUnlock = appState.points >= unlockCost;
    final appName = appState.getAppNameSync(widget.packageName);
    final category = appState.getAppCategorySync(widget.packageName);
    final isStrictlyNonProductive = AppState.isStrictlyNonProductive(widget.packageName, appName, category);

    final int baseMinAyahPts = QuranProgressHelper.calculateAyahPoints(
      arabicLength: 10,
      khatmCount: appState.khatmCount,
    );
    final int baseMaxAyahPts = QuranProgressHelper.calculateAyahPoints(
      arabicLength: 100,
      khatmCount: appState.khatmCount,
    );
    final int boostRem = appState.dailyAyahsBoostRemaining;
    final int displayMinAyahPts = baseMinAyahPts + (boostRem > 0 ? 2 : 0);
    final int displayMaxAyahPts = baseMaxAyahPts + (boostRem > 0 ? 2 : 0);

    final int minDzikirPts = (2 * appState.maqamBoostMultiplier).round();
    final int maxDzikirPts = (5 * appState.maqamBoostMultiplier).round();

    final quranPtsLabel = (boostRem > 0)
        ? Translations.get(lang, 'quran_boost_active')
            .replaceAll('{min}', '$displayMinAyahPts')
            .replaceAll('{max}', '$displayMaxAyahPts')
            .replaceAll('{rem}', '$boostRem')
        : Translations.get(lang, 'quran_normal_pts')
            .replaceAll('{min}', '$displayMinAyahPts')
            .replaceAll('{max}', '$displayMaxAyahPts');

    final dzikirPtsLabel = Translations.get(lang, 'dzikir_label_pts_round')
        .replaceAll('{min}', '$minDzikirPts')
        .replaceAll('{max}', '$maxDzikirPts');

    final hadithPtsLabel = lang == 'id'
        ? '+1-4 Poin'
        : lang == 'ms'
            ? '+1-4 Mata'
            : lang == 'ar'
                ? '+١-٤ نقاط'
                : '+1-4 Pts';

    return PopScope(
      canPop: false, // Prevent back button from bypassing block
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _safeDismiss(appState);
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: const Color(0xFF031E1B),
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF063E36),
                  const Color(0xFF031E1B),
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
                            onPressed: _isUnlocking ? null : () => _safeDismiss(appState),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: _isUnlocking ? null : () => _safeDismiss(appState),
                            icon: const Icon(Icons.home_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Lock Icon Badge
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade900.withValues(alpha: 0.25),
                          border: Border.all(
                            color: Colors.red.shade400.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Color(0xFFF87171),
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. App Name (ABOVE the blocked label)
                      Text(
                        appState.getAppNameSync(widget.packageName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // 2. Status Label (BELOW app name)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade400.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          Translations.get(lang, 'app_blocked'),
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        Translations.get(lang, 'app_blocked_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      
                      // Points Balance Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "${appState.points} ${Translations.get(lang, 'points_available')}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 22),
                      
                      // 1. Unlock Button (Active if points >= 50)
                      if (appState.isAdGracePeriodActive) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade900.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade300.withValues(alpha: 0.5), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.tealAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                lang == 'id'
                                    ? 'Tiket Akses 10m Aktif (${appState.remainingAdGracePeriodMinutes}m tersisa)'
                                    : '10m Access Pass Active (${appState.remainingAdGracePeriodMinutes}m left)',
                                style: const TextStyle(color: Colors.tealAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
                        child: ElevatedButton.icon(
                          onPressed: (canUnlock && !_isUnlocking)
                            ? () async {
                                if (appState.points < unlockCost) return;

                                if (appState.shouldShowAdBeforeUnlock) {
                                  final confirmed = await _showAdConfirmationDialog(
                                    context: context,
                                    lang: lang,
                                    cost: unlockCost,
                                  );
                                  if (confirmed != true) return;

                                  if (mounted) setState(() => _isUnlocking = true);

                                  try {
                                    final watched = await AdService.instance.showRewardedAd();
                                    if (watched) {
                                      await appState.activateAdGracePeriod(durationMinutes: 10);
                                    } else {
                                      debugPrint('[BlockedAppScreen] Rewarded ad offline/unavailable -> bypass ke potongan poin.');
                                    }
                                  } catch (e) {
                                    debugPrint('[BlockedAppScreen] Rewarded ad error -> bypass: $e');
                                  }
                                } else {
                                  setState(() => _isUnlocking = true);
                                }

                                final success = await appState.unlockAppWithPoints(widget.packageName, cost: unlockCost);
                                if (!success) {
                                  if (mounted) {
                                    setState(() => _isUnlocking = false);
                                  }
                                  return;
                                }
                                final appName = appState.getAppNameSync(widget.packageName);
                                final isGhadhulTarget = AppState.shouldShowGhadhulBasharReminder(
                                  widget.packageName,
                                  appName,
                                  appState.languageCode,
                                );
                                appState.clearBlockedApp();
                                if (!context.mounted) return;
                                if (widget.isRoute && Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                                if (isGhadhulTarget) {
                                  appState.setGhadhulBasharPackage(widget.packageName);
                                } else {
                                  await appState.openApp(widget.packageName, bypassGuards: true);
                                }
                              }
                            : null,
                          icon: Icon(
                            canUnlock
                                ? (appState.shouldShowAdBeforeUnlock
                                    ? Icons.ondemand_video_rounded
                                    : Icons.lock_open_rounded)
                                : Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appState.shouldShowAdBeforeUnlock
                                ? const Color(0xFFD97706)
                                : Colors.teal.shade500,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                            disabledForegroundColor: Colors.white38,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          label: Text(
                            _isUnlocking
                                ? (lang == 'id' ? 'Membuka...' : 'Unlocking...')
                                : canUnlock
                                    ? (appState.shouldShowAdBeforeUnlock
                                        ? (lang == 'id'
                                            ? 'Tonton Iklan & Buka ($unlockCost Poin)'
                                            : lang == 'ms'
                                                ? 'Tonton Iklan & Buka ($unlockCost Mata)'
                                                : lang == 'ar'
                                                    ? 'شاهد الإعلان وافتح ($unlockCost نقطة)'
                                                    : 'Watch Ad & Unlock ($unlockCost Pts)')
                                        : Translations.get(lang, 'unlock_cost_pts').replaceAll('{cost}', '$unlockCost'))
                                    : Translations.get(lang, 'need_cost_points').replaceAll('{cost}', '$unlockCost'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      if (!isStrictlyNonProductive) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (_isUnlocking || _showConfirmProductive)
                                ? null
                                : () {
                                    setState(() => _showConfirmProductive = true);
                                  },
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade200,
                              side: BorderSide(color: Colors.teal.shade300.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            label: Text(
                              Translations.get(lang, 'mark_as_productive'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 18),
                      
                      // Header for Ways to Earn Points
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              lang == 'id'
                                  ? 'PILIHAN BACAAN & IBADAH (+POIN)'
                                  : Translations.get(lang, 'earn_points').toUpperCase(),
                              style: TextStyle(
                                color: Colors.teal.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 2. Primary Option: Baca Al-Quran (Di atas sendiri)
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            appState.clearBlockedApp();
                            if (widget.isRoute && mounted && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                            appState.navigatorKey.currentState?.push(
                              AppPageRoute(child: const SurahListScreen()),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded, size: 20, color: Colors.white),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.teal.shade300.withValues(alpha: 0.4)),
                            ),
                            elevation: 1,
                          ),
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  Translations.get(lang, 'read_quran'),
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  quranPtsLabel,
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // 3. Keterangan Sedang Berhalangan / Haid / Rukhsah (Di bawah Quran)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade900.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.teal.shade400.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 18,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                Translations.get(lang, 'hadith_excused_hint'),
                                style: TextStyle(
                                  color: Colors.teal.shade100,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 4. Pilihan Berhalangan A: Dzikir Khusyu' (33x Tasbih)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF04433A).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              appState.clearBlockedApp();
                              if (widget.isRoute && mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              appState.navigatorKey.currentState?.push(
                                AppPageRoute(child: const DzikirScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.grain_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                Translations.get(lang, 'dzikir'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade400.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                dzikirPtsLabel,
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang == 'id'
                                              ? 'Tasbih 33x & Deteksi Wajah (Boleh Meram)'
                                              : Translations.get(lang, 'dzikir_mode_title'),
                                          style: TextStyle(
                                            color: Colors.amber.shade100,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.amber,
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 5. Pilihan Berhalangan B: Hadith Card Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF34D399).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              appState.clearBlockedApp();
                              if (widget.isRoute && mounted && Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                              appState.navigatorKey.currentState?.push(
                                AppPageRoute(child: const HadithListScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34D399).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.spa_rounded,
                                      color: Color(0xFF34D399),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                Translations.get(lang, 'read_hadith'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade400.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                hadithPtsLabel,
                                                style: const TextStyle(
                                                  color: Colors.amber,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          lang == 'id'
                                              ? '50 Kumpulan Hadits Shahih Harian'
                                              : Translations.get(lang, 'read_hadith'),
                                          style: TextStyle(
                                            color: Colors.teal.shade200,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF34D399),
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _safeDismiss(appState),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white70),
                          label: Text(
                            Translations.get(lang, 'go_back'),
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_showConfirmProductive)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_isUnlocking) {
                    setState(() => _showConfirmProductive = false);
                  }
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () {}, // Prevent taps inside dialog from closing it
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: Colors.teal.shade700,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Translations.get(lang, 'confirm_mark_productive_title'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        '$appName: ${Translations.get(lang, 'confirm_mark_productive_desc')}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() => _showConfirmProductive = false);
                          },
                          child: Text(
                            Translations.get(lang, 'cancel'),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isUnlocking
                              ? null
                              : () async {
                                  setState(() {
                                    _showConfirmProductive = false;
                                    _isUnlocking = true;
                                  });
                                  try {
                                    await appState.markAppAsProductive(widget.packageName, appName: appName, category: category);
                                    appState.clearBlockedApp();
                                    if (!context.mounted) return;
                                    if (widget.isRoute && Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                    await appState.openApp(widget.packageName, bypassGuards: true);
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isUnlocking = false);
                                    }
                                  }
                                },
                          child: _isUnlocking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  Translations.get(lang, 'ok'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
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
}
