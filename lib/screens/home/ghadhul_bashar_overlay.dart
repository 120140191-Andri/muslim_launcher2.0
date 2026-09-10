import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/ghadhul_bashar_data.dart';
import '../../utils/translations.dart';

class GhadhulBasharOverlay extends StatefulWidget {
  final String packageName;

  const GhadhulBasharOverlay({super.key, required this.packageName});

  @override
  State<GhadhulBasharOverlay> createState() => _GhadhulBasharOverlayState();
}

class _GhadhulBasharOverlayState extends State<GhadhulBasharOverlay> {
  late final GhadhulBasharVerse _verse;

  @override
  void initState() {
    super.initState();
    _verse = GhadhulBasharData.getRandomVerse();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final lang = appState.languageCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          appState.clearGhadhulBashar();
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: const Color(0xFF031E1B),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF063E36),
                  Color(0xFF031E1B),
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
                            onPressed: () => appState.clearGhadhulBashar(),
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                          ),
                          IconButton(
                            onPressed: () => appState.clearGhadhulBashar(),
                            icon: const Icon(Icons.home_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Eye / Guard Icon Badge
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.visibility_off_rounded,
                          size: 48,
                          color: Color(0xFF34D399),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        Translations.get(lang, 'ghadhul_bashar_title'),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),

                      // Subtitle
                      Text(
                        Translations.get(lang, 'ghadhul_bashar_subtitle'),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // App Name target info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: Colors.teal.shade200,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appState.getAppNameSync(widget.packageName),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Surah Reference Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34D399).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF34D399).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          _verse.getReference(),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF34D399),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Arabic Verse Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _verse.arabic,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD1FAE5),
                                height: 1.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.1),
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "\"${_verse.getTranslation(lang)}\"",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons: Batal & Lanjutkan
                      Row(
                        children: [
                          // Batal Button
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => appState.clearGhadhulBashar(),
                              child: Text(
                                Translations.get(lang, 'cancel'),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Lanjutkan Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => appState.confirmGhadhulBashar(widget.packageName),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              label: Text(
                                Translations.get(lang, 'ok'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => appState.clearGhadhulBashar(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white60),
                          label: Text(
                            Translations.get(lang, 'go_back'),
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
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
    );
  }
}
