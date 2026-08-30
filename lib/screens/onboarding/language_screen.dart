import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';
import 'setup_hub_screen.dart';
import '../../utils/page_transitions.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selectedLang;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _selectedLang = appState.languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(Icons.language_rounded, size: 72, color: Colors.teal.shade800),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Pilih Bahasa\nSelect Language',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Silakan pilih bahasa pengantar Anda\nPlease select your preferred language',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildLanguageOption(
                          context: context,
                          title: 'Bahasa Indonesia',
                          code: 'id',
                          isSelected: _selectedLang == 'id',
                          onTap: () => setState(() => _selectedLang = 'id'),
                        ),
                        const SizedBox(height: 16),
                        _buildLanguageOption(
                          context: context,
                          title: 'English (US)',
                          code: 'en',
                          isSelected: _selectedLang == 'en',
                          onTap: () => setState(() => _selectedLang = 'en'),
                        ),
                        const Spacer(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final appState = Provider.of<AppState>(context, listen: false);
                              await appState.setLanguage(_selectedLang);
                              appState.navigatorKey.currentState?.pushReplacement(
                                AppPageRoute(child: const SetupHubScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      Translations.get(_selectedLang, 'next').toUpperCase(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.teal.shade800 : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title, 
                  style: TextStyle(
                    fontSize: 17, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.teal.shade800 : Colors.teal.shade900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              if (isSelected) 
                Icon(Icons.check_circle_rounded, color: Colors.teal.shade800)
              else 
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.teal.shade50, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
