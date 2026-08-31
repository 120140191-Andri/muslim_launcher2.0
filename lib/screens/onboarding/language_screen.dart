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

  final List<Map<String, String>> _languages = const [
    {
      'code': 'id',
      'title': 'Bahasa Indonesia',
      'subtitle': 'Indonesia',
      'flag': '🇮🇩',
    },
    {
      'code': 'en',
      'title': 'English',
      'subtitle': 'International',
      'flag': '🇬🇧',
    },
    {
      'code': 'ms',
      'title': 'Bahasa Melayu',
      'subtitle': 'Malaysia / Nusantara',
      'flag': '🇲🇾',
    },
    {
      'code': 'ar',
      'title': 'العربية',
      'subtitle': 'Arabic / الشرق الأوسط',
      'flag': '🇸🇦',
    },
    {
      'code': 'af',
      'title': 'Afrikaans',
      'subtitle': 'Suid-Afrika',
      'flag': '🇿🇦',
    },
    {
      'code': 'sw',
      'title': 'Kiswahili',
      'subtitle': 'Swahili / Afrika Mashariki',
      'flag': '🇹🇿',
    },
  ];

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Icon(
                          Icons.language_rounded,
                          size: 56,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        Translations.get(_selectedLang, 'language_selection'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Translations.get(_selectedLang, 'language_subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Column(
                        children: _languages.map((lang) {
                          final isSelected = _selectedLang == lang['code'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLanguageOption(
                              context: context,
                              title: lang['title']!,
                              subtitle: lang['subtitle']!,
                              flag: lang['flag']!,
                              code: lang['code']!,
                              isSelected: isSelected,
                              onTap: () => setState(() => _selectedLang = lang['code']!),
                            ),
                          );
                        }).toList(),
                      ),
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
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String flag,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
              Text(
                flag,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.teal.shade800 : Colors.teal.shade900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: Colors.teal.shade800)
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
