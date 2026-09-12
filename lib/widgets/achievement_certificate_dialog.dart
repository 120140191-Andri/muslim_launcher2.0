import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../screens/home/achievements_screen.dart';
import '../../services/milestone_share_service.dart';
import '../../utils/translations.dart';

class AchievementCertificateDialog extends StatefulWidget {
  final SpiritualBadge badge;
  final String lang;

  const AchievementCertificateDialog({
    super.key,
    required this.badge,
    required this.lang,
  });

  static Future<void> show(
    BuildContext context, {
    required SpiritualBadge badge,
    required String lang,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => AchievementCertificateDialog(
        badge: badge,
        lang: lang,
      ),
    );
  }

  @override
  State<AchievementCertificateDialog> createState() =>
      _AchievementCertificateDialogState();
}

class _AchievementCertificateDialogState
    extends State<AchievementCertificateDialog> {
  late TextEditingController _nameController;
  final GlobalKey _certificateBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _nameController = TextEditingController(text: appState.userName);
    _nameController.addListener(() {
      setState(() {});
      // Nama yang di-input otomatis langsung tersimpan ke AppState & SharedPreferences
      appState.setUserName(_nameController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _getRarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return const Color(0xFF0D9488); // Teal
      case BadgeRarity.rare:
        return const Color(0xFF2563EB); // Royal Blue
      case BadgeRarity.epic:
        return const Color(0xFF7C3AED); // Deep Purple
      case BadgeRarity.legendary:
        return const Color(0xFFD97706); // Amber Gold
    }
  }

  Future<void> _handleShare() async {
    if (_isSharing || _isSaving) return;
    setState(() {
      _isSharing = true;
      _statusMessage = null;
    });

    try {
      final caption = Translations.get(widget.lang, 'share_success_caption')
          .replaceAll('{title}', widget.badge.title);

      final success = await MilestoneShareService.captureAndShare(
        boundaryKey: _certificateBoundaryKey,
        badgeId: widget.badge.id,
        shareText: caption,
      );

      if (!success && mounted) {
        setState(() {
          _statusMessage = Translations.get(widget.lang, 'share_failed');
          _statusIsError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = widget.lang == 'en'
              ? 'Failed to share certificate: $e'
              : 'Gagal membagikan sertifikat: $e';
          _statusIsError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _handleSaveToGallery() async {
    if (_isSharing || _isSaving) return;
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final success = await MilestoneShareService.saveToGallery(
        boundaryKey: _certificateBoundaryKey,
        badgeId: widget.badge.id,
      );

      if (mounted) {
        setState(() {
          if (success) {
            _statusMessage = Translations.get(widget.lang, 'save_to_gallery_success');
            _statusIsError = false;
          } else {
            _statusMessage = Translations.get(widget.lang, 'save_to_gallery_failed');
            _statusIsError = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = Translations.get(widget.lang, 'save_to_gallery_failed');
          _statusIsError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── DIALOG HEADER ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Translations.get(widget.lang, 'share_certificate'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: textColor.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── INPUT NAMA (OTOMATIS TERSIMPAN) ──
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: Translations.get(widget.lang, 'input_name_label'),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                  hintText: Translations.get(widget.lang, 'input_name_hint'),
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                  helperText: Translations.get(widget.lang, 'input_name_helper'),
                  helperStyle: TextStyle(
                    fontSize: 10.5,
                    color: textColor.withValues(alpha: 0.55),
                  ),
                  prefixIcon: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: textColor.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF10B981),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── PRATINJAU SERTIFIKAT (9:16 PREVIEW & CAPTURE) ──
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _certificateBoundaryKey,
                          child: _buildOfficialCertificateWidget(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── PESAN STATUS / FEEDBACK (DI ATAS TOMBOL) ──
              if (_statusMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _statusIsError
                        ? Colors.red.withValues(alpha: 0.12)
                        : const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _statusIsError
                          ? Colors.red.withValues(alpha: 0.3)
                          : const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIsError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: _statusIsError
                            ? Colors.red.shade400
                            : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusIsError
                                ? Colors.red.shade400
                                : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // ── TOMBOL AKSI BAGIKAN & SIMPAN KE GALERI ──
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: (_isSharing || _isSaving) ? null : _handleShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0xFF059669).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share_rounded, size: 19),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  Translations.get(widget.lang, 'share_to_story'),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: (_isSharing || _isSaving) ? null : _handleSaveToGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(
                      color: textColor.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: textColor,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded, size: 19, color: textColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  Translations.get(widget.lang, 'save_to_gallery'),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desain Resmi Sertifikat 9:16 yang Elegan, Sakral, dan Sangat Postable
  Widget _buildOfficialCertificateWidget() {
    final rarityColor = _getRarityColor(widget.badge.rarity);
    final appState = Provider.of<AppState>(context, listen: false);
    final String currentName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : appState.displayName;

    String dateString;
    try {
      dateString = DateFormat('d MMMM yyyy', widget.lang).format(DateTime.now());
    } catch (_) {
      try {
        dateString = DateFormat('d MMMM yyyy').format(DateTime.now());
      } catch (_) {
        final now = DateTime.now();
        dateString = '${now.day}/${now.month}/${now.year}';
      }
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: Container(
        width: 360,
        height: 640, // 9:16 Aspect Ratio (Story Format)
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06140E),
            Color(0xFF0B241A),
            Color(0xFF061C13),
            Color(0xFF030D08),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 1. Watermark Radiant Glow in Background
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF10B981).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Ornate Dual Golden Certificate Border
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.75),
                width: 1.8,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── BAGIAN ATAS: BISMILLAH & HEADER SYAHADAH ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 4 Ornate corner stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                          Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Bismillah Calligraphy Text
                      const Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),

                      Text(
                        Translations.get(widget.lang, 'certificate_subtitle').toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 8,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Title Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD97706).withValues(alpha: 0.25),
                              const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              const Color(0xFFD97706).withValues(alpha: 0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Translations.get(widget.lang, 'certificate_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── BAGIAN TENGAH: NAMA PENERIMA & PENCAPAIAN ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Translations.get(widget.lang, 'certificate_awarded_to'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 9.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // User Display Name (FittedBox prevents truncation)
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currentName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFD97706),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Ornate Divider
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF59E0B).withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Text(
                        Translations.get(widget.lang, 'certificate_achievement_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 9.0,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Badge Card Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: rarityColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rarityColor.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 3D Badge Icon Circle
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    rarityColor.withValues(alpha: 0.35),
                                    rarityColor.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(color: rarityColor, width: 1.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: rarityColor.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.badge.icon,
                                color: rarityColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Badge Title & Description (Full text, no ellipsis)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.badge.title,
                                    maxLines: 2,
                                    softWrap: true,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.badge.description,
                                    softWrap: true,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: widget.badge.description.length > 100 ? 9.0 : 9.5,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Fadhilah / Keutamaan Quote (Full text without maxLines truncation)
                      if (widget.badge.fadhilah.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Builder(
                          builder: (context) {
                            final fLen = widget.badge.fadhilah.length;
                            final double fSize = fLen > 140
                                ? 7.8
                                : (fLen > 90 ? 8.2 : 8.8);

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.badge.fadhilah,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFDE68A).withValues(alpha: 0.95),
                                  fontSize: fSize,
                                  fontStyle: FontStyle.italic,
                                  height: 1.24,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),

                  // ── BAGIAN BAWAH: STEMPEL RESMI & BRANDING FOOTER ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stamp & Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Date Achieved
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Translations.get(widget.lang, 'certificate_date_label'),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    dateString,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right: Official Certified Seal (3D Stamp)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 13),
                                const SizedBox(width: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    Translations.get(widget.lang, 'certificate_official_seal'),
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Color(0xFFFDE68A),
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Footer Line (Muslim Launcher 2 Branding)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Translations.get(widget.lang, 'certificate_verified_by'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1.5),
                            Text(
                              'play.google.com/store/apps/details?id=com.kraftech.muslim_launcher_2',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 7.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
