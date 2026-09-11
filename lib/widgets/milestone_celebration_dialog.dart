import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/milestone_share_service.dart';
import 'milestone_share_card.dart';

class MilestoneCelebrationDialog extends StatefulWidget {
  final MilestoneCardData data;

  const MilestoneCelebrationDialog({
    super.key,
    required this.data,
  });

  static Future<void> show(
    BuildContext context, {
    required MilestoneCardData data,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MilestoneCelebrationDialog(data: data),
    );
  }

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState
    extends State<MilestoneCelebrationDialog> with SingleTickerProviderStateMixin {
  final GlobalKey _cardKey = GlobalKey();
  late MilestoneCardTheme _selectedTheme;
  late bool _showUserName;
  bool _isSharing = false;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.data.type == MilestoneCardType.khatam
        ? MilestoneCardTheme.royalGoldCertificate
        : MilestoneCardTheme.midnightObsidian;
    _showUserName = widget.data.showUserName;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    // Haptic feedback micro-delight
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  MilestoneCardData get _effectiveData => MilestoneCardData(
        type: widget.data.type,
        title: widget.data.title,
        arabicTitle: widget.data.arabicTitle,
        subtitle: widget.data.subtitle,
        surahNumber: widget.data.surahNumber,
        ayahCount: widget.data.ayahCount,
        durationMinutes: widget.data.durationMinutes,
        streakDays: widget.data.streakDays,
        khatamProgressJuz: widget.data.khatamProgressJuz,
        khatamProgressPercent: widget.data.khatamProgressPercent,
        khatamCount: widget.data.khatamCount,
        userName: widget.data.userName,
        showUserName: _showUserName,
        dateStr: widget.data.dateStr,
        quote: widget.data.quote,
        quoteSource: widget.data.quoteSource,
        badgeIcon: widget.data.badgeIcon,
        bonusPoints: widget.data.bonusPoints,
      );

  Future<void> _handleShare() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final shareText = MilestoneShareService.buildShareText(
        title: widget.data.title,
        subtitle: widget.data.subtitle,
        ayahOrDzikirCount: widget.data.ayahCount != null
            ? '${widget.data.ayahCount} ${widget.data.type == MilestoneCardType.surah ? 'Ayat' : 'x Dzikir'}'
            : null,
      );

      await MilestoneShareService.shareMilestoneCard(
        boundaryKey: _cardKey,
        shareText: shareText,
        fileNamePrefix: widget.data.type == MilestoneCardType.khatam
            ? 'khatam_30_juz'
            : 'milestone_${widget.data.title.toLowerCase().replaceAll(' ', '_')}',
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleSaveToGallery() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final savedPath = await MilestoneShareService.saveMilestoneToGallery(
        boundaryKey: _cardKey,
        fileNamePrefix: widget.data.type == MilestoneCardType.khatam
            ? 'khatam_30_juz'
            : 'milestone_${widget.data.title.toLowerCase().replaceAll(' ', '_')}',
      );

      if (!mounted) return;
      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Gambar berhasil disimpan ke Galeri! Siap dibagikan ke Story.'),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal menyimpan gambar ke penyimpanan.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isDark = themeData.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A2A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Bar with Close Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.data.type == MilestoneCardType.khatam
                              ? 'Mubarak! Khatam 30 Juz'
                              : 'Pencapaian Berkah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                ),

                // Card Preview Container
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // RepaintBoundary wrapping the Card
                        Center(
                          child: RepaintBoundary(
                            key: _cardKey,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 290,
                                  maxHeight: 515,
                                ),
                                child: MilestoneShareCard(
                                  data: _effectiveData,
                                  theme: _selectedTheme,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Theme Selection Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildThemeChip(
                                'Midnight',
                                MilestoneCardTheme.midnightObsidian,
                                const Color(0xFF0B0F19),
                              ),
                              const SizedBox(width: 8),
                              _buildThemeChip(
                                'Emerald Luxe',
                                MilestoneCardTheme.deepEmeraldLuxe,
                                const Color(0xFF063B26),
                              ),
                              const SizedBox(width: 8),
                              _buildThemeChip(
                                'Warm Sand',
                                MilestoneCardTheme.minimalistWarmSand,
                                const Color(0xFFFAF7F2),
                                textColor: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              _buildThemeChip(
                                'Royal Gold',
                                MilestoneCardTheme.royalGoldCertificate,
                                const Color(0xFF2A2312),
                                borderColor: const Color(0xFFFFD700),
                              ),
                            ],
                          ),
                        ),

                        // Toggle Name display
                        if (widget.data.userName != null && widget.data.userName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              setState(() => _showUserName = !_showUserName);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showUserName
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sematkan nama saya di kartu',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0E1422) : const Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Save to Gallery Button
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _handleSaveToGallery,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download_rounded, size: 18),
                          label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Foto'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Share Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _isSharing ? null : _handleShare,
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.share_rounded, size: 18),
                          label: Text(_isSharing ? 'Membagikan...' : 'Bagikan ke Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
        ),
      ),
    );
  }

  Widget _buildThemeChip(
    String label,
    MilestoneCardTheme theme,
    Color bgColor, {
    Color? textColor,
    Color? borderColor,
  }) {
    final isSelected = _selectedTheme == theme;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: textColor ?? Colors.white,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedTheme = theme);
      },
      backgroundColor: bgColor,
      selectedColor: bgColor,
      side: BorderSide(
        color: isSelected
            ? (borderColor ?? const Color(0xFF10B981))
            : Colors.transparent,
        width: 2,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
