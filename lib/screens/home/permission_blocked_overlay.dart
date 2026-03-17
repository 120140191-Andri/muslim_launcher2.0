import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import 'accessibility_setup_screen.dart';
import '../onboarding/setup_launcher_screen.dart';
import '../../utils/page_transitions.dart';

class PermissionBlockedOverlay extends StatelessWidget {
  final AppState appState;
  final Widget child;

  const PermissionBlockedOverlay({
    super.key,
    required this.appState,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Only enforce strict checks AFTER onboarding is completed
    if (!appState.hasCompletedOnboarding) return child;
    if (appState.ignorePermissionGuard) return child;

    final isMissingDefault = !appState.isDefaultLauncher;
    final isMissingAccess = !appState.isAccessibilityEnabled;

    if (!isMissingDefault && !isMissingAccess) return child;

    final isEn = appState.languageCode == 'en';

    return Stack(
      children: [
        child,
        // The Blocking Overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.85),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security_rounded,
                          color: Colors.red.shade800,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        isEn ? 'Action Required' : 'Aksi Diperlukan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEn
                            ? 'Some essential permissions were disabled. To keep you focused, please re-enable them.'
                            : 'Beberapa izin utama dinonaktifkan. Agar Anda tetap fokus, silakan aktifkan kembali.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (isMissingDefault)
                        _buildRepairButton(
                          context,
                          icon: Icons.home_rounded,
                          label: isEn ? 'Set Default Launcher' : 'Atur Beranda Utama',
                          onTap: () {
                            appState.setIgnorePermissionGuard(true);
                            Navigator.push(
                              context,
                              AppPageRoute(child: const SetupLauncherScreen()),
                            ).then((_) => appState.setIgnorePermissionGuard(false));
                          },
                        ),
                      if (isMissingDefault && isMissingAccess) const SizedBox(height: 16),
                      if (isMissingAccess)
                        _buildRepairButton(
                          context,
                          icon: Icons.accessibility_new_rounded,
                          label: isEn ? 'Enable Accessibility' : 'Aktifkan Aksesibilitas',
                          onTap: () {
                            appState.setIgnorePermissionGuard(true);
                            Navigator.push(
                              context,
                              AppPageRoute(child: const AccessibilitySetupScreen()),
                            ).then((_) => appState.setIgnorePermissionGuard(false));
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade900,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
