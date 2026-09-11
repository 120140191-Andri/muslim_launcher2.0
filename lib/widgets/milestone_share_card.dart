import 'package:flutter/material.dart';

enum MilestoneCardType {
  surah,
  dzikir,
  khatam,
}

enum MilestoneCardTheme {
  midnightObsidian,
  deepEmeraldLuxe,
  minimalistWarmSand,
  royalGoldCertificate,
}

class MilestoneCardData {
  final MilestoneCardType type;
  final String title;
  final String? arabicTitle;
  final String subtitle;
  final int? surahNumber;
  final int? ayahCount;
  final int? durationMinutes;
  final int? streakDays;
  final int? khatamProgressJuz;
  final int? khatamProgressPercent;
  final int? khatamCount;
  final String? userName;
  final bool showUserName;
  final String dateStr;
  final String? quote;
  final String? quoteSource;
  final IconData badgeIcon;
  final int? bonusPoints;

  const MilestoneCardData({
    required this.type,
    required this.title,
    this.arabicTitle,
    required this.subtitle,
    this.surahNumber,
    this.ayahCount,
    this.durationMinutes,
    this.streakDays,
    this.khatamProgressJuz,
    this.khatamProgressPercent,
    this.khatamCount,
    this.userName,
    this.showUserName = true,
    required this.dateStr,
    this.quote,
    this.quoteSource,
    this.badgeIcon = Icons.military_tech_rounded,
    this.bonusPoints,
  });
}

class MilestoneShareCard extends StatelessWidget {
  final MilestoneCardData data;
  final MilestoneCardTheme theme;

  const MilestoneShareCard({
    super.key,
    required this.data,
    this.theme = MilestoneCardTheme.midnightObsidian,
  });

  @override
  Widget build(BuildContext context) {
    // 9:16 aspect ratio container designed for 1080x1920 Story capture
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: _buildBackgroundDecoration(),
        child: Stack(
          children: [
            // Background Ornaments / Glow
            ..._buildBackgroundAccents(),

            // Card Inner Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Safe Zone Top Margin + Header Branding
                  _buildHeader(),

                  const Spacer(flex: 2),

                  // Hero Badge & Maqam Indicator
                  _buildHeroBadge(),

                  const SizedBox(height: 16),

                  // Main Achievement Title & Arabic
                  _buildTitleSection(),

                  const SizedBox(height: 16),

                  // Stats Grid 2x2
                  _buildStatsGrid(),

                  const SizedBox(height: 14),

                  // Khatam Progress Bar
                  if (data.type != MilestoneCardType.khatam &&
                      data.khatamProgressJuz != null)
                    _buildKhatamProgress(),

                  // Quote / Hadith
                  if (data.quote != null && data.quote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildQuoteSection(),
                    ),

                  const Spacer(flex: 3),

                  // Footer & Play Store Link
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Theme Styling Helpers ───────────────────────────────────────────────────

  BoxDecoration _buildBackgroundDecoration() {
    switch (theme) {
      case MilestoneCardTheme.midnightObsidian:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0F19),
              Color(0xFF06141D),
              Color(0xFF0A1826),
            ],
          ),
        );
      case MilestoneCardTheme.deepEmeraldLuxe:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF042417),
              Color(0xFF063B26),
              Color(0xFF021B11),
            ],
          ),
        );
      case MilestoneCardTheme.minimalistWarmSand:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAF7F2),
              Color(0xFFF3EDE4),
              Color(0xFFEBE2D5),
            ],
          ),
        );
      case MilestoneCardTheme.royalGoldCertificate:
        return const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Color(0xFF1E1B0E),
              Color(0xFF0C101A),
              Color(0xFF05070D),
            ],
          ),
        );
    }
  }

  List<Widget> _buildBackgroundAccents() {
    final isDark = theme != MilestoneCardTheme.minimalistWarmSand;
    return [
      // Top right subtle glow
      Positioned(
        top: -60,
        right: -60,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (theme == MilestoneCardTheme.royalGoldCertificate ||
                    theme == MilestoneCardTheme.deepEmeraldLuxe)
                ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                : (isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF047857).withValues(alpha: 0.08)),
          ),
        ),
      ),
      // Bottom left glow
      Positioned(
        bottom: -50,
        left: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                : const Color(0xFFD97706).withValues(alpha: 0.06),
          ),
        ),
      ),
    ];
  }

  Color get _primaryTextColor {
    switch (theme) {
      case MilestoneCardTheme.minimalistWarmSand:
        return const Color(0xFF1E293B);
      case MilestoneCardTheme.royalGoldCertificate:
        return const Color(0xFFFFDF7A);
      default:
        return Colors.white;
    }
  }

  Color get _secondaryTextColor {
    switch (theme) {
      case MilestoneCardTheme.minimalistWarmSand:
        return const Color(0xFF64748B);
      case MilestoneCardTheme.royalGoldCertificate:
        return const Color(0xFFE2C98A);
      default:
        return Colors.white.withValues(alpha: 0.72);
    }
  }

  Color get _accentColor {
    switch (theme) {
      case MilestoneCardTheme.minimalistWarmSand:
        return const Color(0xFF047857);
      case MilestoneCardTheme.royalGoldCertificate:
        return const Color(0xFFFFD700);
      case MilestoneCardTheme.deepEmeraldLuxe:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color get _boxBackgroundColor {
    switch (theme) {
      case MilestoneCardTheme.minimalistWarmSand:
        return Colors.white.withValues(alpha: 0.85);
      case MilestoneCardTheme.royalGoldCertificate:
        return const Color(0xFF2A2312).withValues(alpha: 0.65);
      default:
        return Colors.white.withValues(alpha: 0.07);
    }
  }

  Color get _boxBorderColor {
    switch (theme) {
      case MilestoneCardTheme.minimalistWarmSand:
        return const Color(0xFFE2D9CC);
      case MilestoneCardTheme.royalGoldCertificate:
        return const Color(0xFFFFD700).withValues(alpha: 0.4);
      case MilestoneCardTheme.deepEmeraldLuxe:
        return const Color(0xFFF59E0B).withValues(alpha: 0.35);
      default:
        return Colors.white.withValues(alpha: 0.12);
    }
  }

  // ── Component Builders ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    final effectiveName = (data.showUserName && data.userName != null && data.userName!.isNotEmpty)
        ? data.userName!
        : 'Pejuang Kebaikan';

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.brightness_2_rounded, size: 14, color: _accentColor),
              const SizedBox(width: 6),
              Text(
                'MUSLIM LAUNCHER • ISTIQOMAH JOURNEY',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
            color: _accentColor.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _boxBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _boxBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline_rounded, size: 11, color: _secondaryTextColor),
              const SizedBox(width: 4),
              Text(
                effectiveName,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (data.khatamCount != null && data.khatamCount! > 0) ...[
                const SizedBox(width: 4),
                const Text('👑', style: TextStyle(fontSize: 10)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBadge() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withValues(alpha: 0.25),
            _accentColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: _accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          data.type == MilestoneCardType.khatam
              ? Icons.workspace_premium_rounded
              : data.badgeIcon,
          size: 40,
          color: _accentColor,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    String categoryLabel;
    switch (data.type) {
      case MilestoneCardType.surah:
        categoryLabel = 'SURAH SELESAI';
        break;
      case MilestoneCardType.dzikir:
        categoryLabel = 'DZIKIR SELESAI';
        break;
      case MilestoneCardType.khatam:
        categoryLabel = 'KHATAM 30 JUZ AL-QUR\'AN';
        break;
    }

    return Column(
      children: [
        Text(
          categoryLabel,
          style: TextStyle(
            color: _accentColor,
            fontSize: 11,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        if (data.arabicTitle != null && data.arabicTitle!.isNotEmpty) ...[
          Text(
            data.arabicTitle!,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: _primaryTextColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '"${data.subtitle}"',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _boxBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _boxBorderColor),
      ),
      child: Row(
        children: [
          // Stat 1: Ayat / Butir
          Expanded(
            child: _buildStatItem(
              icon: data.type == MilestoneCardType.surah
                  ? Icons.menu_book_rounded
                  : Icons.radio_button_checked_rounded,
              value: data.type == MilestoneCardType.surah
                  ? '${data.ayahCount ?? 0} Ayat'
                  : '${data.ayahCount ?? 33}x Tasbih',
              label: data.type == MilestoneCardType.surah ? 'Panjang Surah' : 'Hitungan',
            ),
          ),
          Container(width: 1, height: 32, color: _boxBorderColor),
          // Stat 2: Waktu / Bonus Poin
          Expanded(
            child: _buildStatItem(
              icon: Icons.timer_outlined,
              value: '${data.durationMinutes ?? 5} Menit',
              label: 'Waktu Tilawah',
            ),
          ),
          Container(width: 1, height: 32, color: _boxBorderColor),
          // Stat 3: Bonus Kebaikan
          Expanded(
            child: _buildStatItem(
              icon: Icons.stars_rounded,
              value: '+${data.bonusPoints ?? 25}',
              label: 'Poin Kebaikan',
              valueColor: _accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: _accentColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? _primaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: _secondaryTextColor,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildKhatamProgress() {
    final juz = data.khatamProgressJuz ?? 1;
    final percent = data.khatamProgressPercent ?? ((juz / 30) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _boxBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _boxBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Perjalanan Khatam: Juz $juz / 30',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _secondaryTextColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _boxBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _boxBorderColor),
      ),
      child: Column(
        children: [
          Text(
            '"${data.quote!}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
          if (data.quoteSource != null && data.quoteSource!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data.quoteSource!,
              style: TextStyle(
                color: _accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.dateStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'muslimlauncher.com/app',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock_rounded, size: 12, color: Colors.black),
              SizedBox(width: 4),
              Text(
                'Istiqomah & Disiplin',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
