import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';

class ProhibitedAppOverlay extends StatefulWidget {
  final String packageName;

  const ProhibitedAppOverlay({super.key, required this.packageName});

  @override
  State<ProhibitedAppOverlay> createState() => _ProhibitedAppOverlayState();
}

class _ProhibitedAppOverlayState extends State<ProhibitedAppOverlay> {

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;
    final isAdultApp = AppState.isExplicitAdultApp(widget.packageName);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          appState.clearProhibitedPackage();
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: const Color(0xFF160407),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF380A10),
                  Color(0xFF1E0407),
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
                            onPressed: () => appState.clearProhibitedPackage(),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: () => appState.clearProhibitedPackage(),
                            icon: const Icon(Icons.home_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Prohibition Shield Icon Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gpp_bad_rounded,
                          size: 52,
                          color: Color(0xFFFB7185),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Title
                      Text(
                        Translations.get(lang, 'prohibited_app_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // App Name Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.block_rounded,
                              size: 14,
                              color: Color(0xFFFB7185),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appState.getAppNameSync(widget.packageName),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Description
                      Text(
                        isAdultApp
                            ? Translations.get(lang, 'prohibited_adult_desc')
                            : Translations.get(lang, 'prohibited_app_desc'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Islamic Quran Reminder Card (Surah Al-An'am: 151)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24060B).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Arabic Ayah
                            const Text(
                              'وَلَا تَقْرَبُوا الْفَوَاحِشَ مَا ظَهَرَ مِنْهَا وَمَا بَطَنَ',
                              style: TextStyle(
                                color: Color(0xFFFDE047),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.12),
                              thickness: 1,
                            ),
                            const SizedBox(height: 12),

                            // Translation Text
                            Text(
                              Translations.get(lang, 'prohibited_app_verse'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13.5,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Recommendation Box: Nasihat Syariat for Adult Apps OR Safe Browsers for Bypass Browsers
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isAdultApp
                              ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isAdultApp
                                ? const Color(0xFFE11D48).withValues(alpha: 0.35)
                                : const Color(0xFF10B981).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isAdultApp
                                    ? const Color(0xFFE11D48).withValues(alpha: 0.2)
                                    : const Color(0xFF10B981).withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAdultApp
                                    ? Icons.health_and_safety_rounded
                                    : Icons.tips_and_updates_rounded,
                                size: 20,
                                color: isAdultApp
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFF34D399),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAdultApp
                                        ? Translations.get(lang, 'prohibited_adult_suggestion_title')
                                        : Translations.get(lang, 'prohibited_suggestion_title'),
                                    style: TextStyle(
                                      color: isAdultApp
                                          ? const Color(0xFFFB7185)
                                          : const Color(0xFF34D399),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAdultApp
                                        ? Translations.get(lang, 'prohibited_adult_suggestion_desc')
                                        : Translations.get(lang, 'prohibited_suggestion_desc'),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      if (isAdultApp) ...[
                        // Uninstall App Button for Adult Content Apps
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              const channel = MethodChannel('com.muslimlauncher/apps');
                              try {
                                await channel.invokeMethod('uninstallApp', {'packageName': widget.packageName});
                              } catch (_) {}
                              appState.clearProhibitedPackage();
                            },
                            icon: const Icon(Icons.delete_forever_rounded, size: 20),
                            label: Text(
                              Translations.get(lang, 'uninstall_prohibited_app'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBE123C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Back to Home Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => appState.clearProhibitedPackage(),
                            icon: const Icon(Icons.arrow_back_rounded, size: 20),
                            label: Text(
                              Translations.get(lang, 'go_back'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.12),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Primary Action Button for Browsers: Back to Home
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => appState.clearProhibitedPackage(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFFE11D48).withValues(alpha: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  Translations.get(lang, 'go_back'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
