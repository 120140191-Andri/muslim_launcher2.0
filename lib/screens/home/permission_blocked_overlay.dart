import 'package:flutter/material.dart';
import '../../providers/app_state.dart';
import '../onboarding/setup_hub_screen.dart';
import '../../utils/page_transitions.dart';
import '../../utils/translations.dart';

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

    final lang = appState.languageCode;

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
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
                          Translations.get(lang, 'action_required'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          Translations.get(lang, 'permission_disabled_desc'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        _buildRepairButton(
                          icon: Icons.tune_rounded,
                          label: Translations.get(lang, 'open_setup_hub'),
                          onTap: () {
                            appState.setIgnorePermissionGuard(true);
                            appState.navigatorKey.currentState?.push(
                              AppPageRoute(child: const SetupHubScreen(isOnboarding: false)),
                            ).then((_) => appState.setIgnorePermissionGuard(false));
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            appState.setIgnorePermissionGuard(true);
                          },
                          child: Text(
                            Translations.get(lang, 'continue_without_protection'),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepairButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 56),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          backgroundColor: Colors.white,
          foregroundColor: Colors.red.shade900,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
