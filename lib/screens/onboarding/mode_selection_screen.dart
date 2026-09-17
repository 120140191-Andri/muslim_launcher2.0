import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../home/home_screen.dart';
import '../home/app_list_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';

class ModeSelectionScreen extends StatefulWidget {
  final bool isOnboarding;
  const ModeSelectionScreen({super.key, this.isOnboarding = true});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with WidgetsBindingObserver {
  bool _isStrictModeSelected = true;
  int _selectedDays = 30;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshDeviceAdminStatus();
      if (appState.isStrictActiveNow) {
        setState(() {
          _isStrictModeSelected = true;
          _selectedDays = appState.strictModeDays;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.refreshDeviceAdminStatus();
    }
  }

  Future<void> _handleConfirm() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;

    if (_isStrictModeSelected) {
      // If Device Admin is not active, prompt user to activate it first
      if (!appState.isDeviceAdminActive) {
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.amber.shade800),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Translations.get(lang, 'device_admin_required'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              Translations.get(lang, 'device_admin_desc'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(Translations.get(lang, 'cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5C3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(Translations.get(lang, 'activate_device_admin')),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          await appState.requestDeviceAdmin();
        }
        return;
      }

      // Show strict commitment pledge confirmation dialog
      final confirmed = await _showCommitmentPledgeModal(context, lang, _selectedDays);
      if (confirmed != true) return;

      setState(() => _isProcessing = true);
      await appState.enableStrictMode(_selectedDays);
    } else {
      if (appState.isStrictActiveNow) {
        final days = appState.remainingStrictDuration.inDays;
        final daysStr = days > 0 ? '$days' : '<1';
        final msg = lang == 'id'
            ? 'Komitmen Mode Ketat sedang berjalan ($daysStr hari tersisa). Anda tidak dapat beralih ke Mode Standar hingga periode selesai.'
            : 'Strict Mode commitment is active ($daysStr days remaining). You cannot switch to Standard Mode until the period expires.';
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.lock_rounded, color: Colors.red.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang == 'id' ? 'Komitmen Terkunci' : 'Commitment Locked',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(msg, style: const TextStyle(fontSize: 14, height: 1.4)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      setState(() => _isProcessing = true);
      await appState.enableStandardMode();
    }

    // Complete setup & transition to HomeScreen
    await _finishAndGoHome(appState);
  }

  Future<bool?> _showCommitmentPledgeModal(
      BuildContext context, String lang, int days) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool check1 = false;
        bool check2 = false;
        final textController = TextEditingController();
        bool isKeywordMatched = false;
        const targetKeyword = 'BISMILLAH';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            final canConfirm = check1 && check2 && isKeywordMatched;

            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_clock_rounded,
                            color: Colors.red.shade800,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Translations.get(lang, 'confirm_commitment_title'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      Translations.get(lang, 'confirm_commitment_desc',
                          {'days': days.toString()}),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Checkbox 1
                    InkWell(
                      onTap: () {
                        setModalState(() => check1 = !check1);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: check1,
                              activeColor: const Color(0xFF0D5C3A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setModalState(() => check1 = val ?? false);
                              },
                            ),
                            Expanded(
                              child: Text(
                                Translations.get(lang, 'confirm_check_1'),
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Checkbox 2
                    InkWell(
                      onTap: () {
                        setModalState(() => check2 = !check2);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Checkbox(
                              value: check2,
                              activeColor: const Color(0xFF0D5C3A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setModalState(() => check2 = val ?? false);
                              },
                            ),
                            Expanded(
                              child: Text(
                                Translations.get(lang, 'confirm_check_2'),
                                style: const TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      Translations.get(lang, 'type_to_confirm',
                          {'keyword': targetKeyword}),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D5C3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: targetKeyword,
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFF0D5C3A), width: 1.6),
                        ),
                      ),
                      onChanged: (val) {
                        final matches =
                            val.trim().toUpperCase() == targetKeyword;
                        if (matches != isKeywordMatched) {
                          setModalState(() => isKeywordMatched = matches);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canConfirm
                            ? () => Navigator.pop(ctx, true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5C3A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          Translations.get(lang, 'start_strict_mode'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            letterSpacing: 0.5,
                          ),
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

  Future<void> _finishAndGoHome(AppState appState) async {
    final lang = appState.languageCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F5E3B), Color(0xFF083C25)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: Color(0xFF34D399),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  Translations.get(lang, 'setup_preparing_home'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await AppListScreen.preload(
      onRawAppsFetched: (raw) => appState.syncAppsWithCategories(raw),
    ).timeout(
      const Duration(milliseconds: 3500),
      onTimeout: () {},
    ).whenComplete(() {
      if (mounted) {
        appState.completeOnboarding();
        appState.navigatorKey.currentState?.pushAndRemoveUntil(
          AppPageRoute(child: const HomeScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final isEn = lang == 'en';
    final isAdminActive = appState.isDeviceAdminActive;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Column(
        children: [
          // ── Top Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F5E3B), Color(0xFF083C25)],
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        Expanded(
                          child: Text(
                            Translations.get(lang, 'mode_selection_title'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Translations.get(lang, 'mode_selection_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Mode Cards List ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              children: [
                // 1. MODE KETAT CARD (DEFAULT)
                _buildModeCard(
                  isSelected: _isStrictModeSelected,
                  title: Translations.get(lang, 'strict_mode_title'),
                  badgeText: Translations.get(lang, 'strict_mode_badge'),
                  isRecommended: true,
                  icon: Icons.shield_rounded,
                  onTap: () => setState(() => _isStrictModeSelected = true),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get(lang, 'strict_mode_desc'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Protection Checklist
                      _buildCheckItem(
                        icon: Icons.delete_forever_rounded,
                        text: Translations.get(lang, 'strict_protection_uninstaller'),
                      ),
                      const SizedBox(height: 8),
                      _buildCheckItem(
                        icon: Icons.lock_outline_rounded,
                        text: Translations.get(lang, 'strict_protection_accessibility'),
                      ),
                      const SizedBox(height: 8),
                      _buildCheckItem(
                        icon: Icons.cleaning_services_rounded,
                        text: Translations.get(lang, 'strict_protection_clear_data'),
                      ),
                      const SizedBox(height: 8),
                      _buildCheckItem(
                        icon: Icons.schedule_rounded,
                        text: Translations.get(lang, 'strict_protection_time'),
                      ),
                      const SizedBox(height: 18),

                      // Duration Selector Chips
                      Text(
                        isEn ? 'Commitment Duration:' : 'Pilih Durasi Komitmen:',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D5C3A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildDurationChip(30, 'duration_30_days', 'duration_30_subtitle', lang),
                          const SizedBox(width: 8),
                          _buildDurationChip(60, 'duration_60_days', 'duration_60_subtitle', lang),
                          const SizedBox(width: 8),
                          _buildDurationChip(90, 'duration_90_days', 'duration_90_subtitle', lang),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D5C3A).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0D5C3A).withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFF0D5C3A)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                Translations.get(lang, 'duration_${_selectedDays}_desc'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Device Admin Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isAdminActive
                              ? const Color(0xFF0D5C3A).withValues(alpha: 0.08)
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isAdminActive
                                ? const Color(0xFF0D5C3A).withValues(alpha: 0.25)
                                : Colors.amber.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAdminActive
                                  ? Icons.verified_user_rounded
                                  : Icons.info_outline_rounded,
                              color: isAdminActive
                                  ? const Color(0xFF0D5C3A)
                                  : Colors.amber.shade900,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isAdminActive
                                    ? Translations.get(lang, 'device_admin_active')
                                    : Translations.get(lang, 'device_admin_required'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isAdminActive
                                      ? const Color(0xFF0D5C3A)
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ),
                            if (!isAdminActive)
                              TextButton(
                                onPressed: () => appState.requestDeviceAdmin(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  Translations.get(lang, 'activate_device_admin'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. MODE STANDAR CARD
                _buildModeCard(
                  isSelected: !_isStrictModeSelected,
                  title: Translations.get(lang, 'standard_mode_title'),
                  badgeText: appState.isStrictActiveNow
                      ? (isEn ? 'LOCKED' : 'TERKUNCI')
                      : (isEn ? 'FLEXIBLE' : 'FLEKSIBEL'),
                  isRecommended: false,
                  icon: appState.isStrictActiveNow ? Icons.lock_outline_rounded : Icons.touch_app_rounded,
                  onTap: () {
                    if (appState.isStrictActiveNow) {
                      final days = appState.remainingStrictDuration.inDays;
                      final daysStr = days > 0 ? '$days' : '<1';
                      final msg = lang == 'id'
                          ? 'Mode Ketat sedang aktif ($daysStr hari tersisa). Anda tidak dapat mengubah ke Mode Standar hingga periode selesai.'
                          : 'Strict Mode is currently active ($daysStr days remaining). You cannot switch to Standard Mode until the period expires.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.red.shade800,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    setState(() => _isStrictModeSelected = false);
                  },
                  child: Text(
                    Translations.get(lang, 'standard_mode_desc'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Confirmation Button ──────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              14 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
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
                  onPressed: _isProcessing ? null : _handleConfirm,
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
                        _isStrictModeSelected
                            ? Translations.get(lang, 'start_strict_mode')
                            : Translations.get(lang, 'start_standard_mode'),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required bool isSelected,
    required String title,
    required String badgeText,
    required bool isRecommended,
    required IconData icon,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0D5C3A)
              : Colors.black.withValues(alpha: 0.08),
          width: isSelected ? 2.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF0D5C3A).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D5C3A)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF0D5C3A)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isRecommended
                                      ? const Color(0xFF0D5C3A).withValues(alpha: 0.1)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isRecommended
                                        ? const Color(0xFF0D5C3A)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0D5C3A)
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF0D5C3A),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D5C3A), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(
      int days, String titleKey, String subKey, String lang) {
    final isSelected = _selectedDays == days;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDays = days),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0D5C3A)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D5C3A)
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                Translations.get(lang, titleKey),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFF0D5C3A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  Translations.get(lang, subKey),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF0D5C3A),
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
