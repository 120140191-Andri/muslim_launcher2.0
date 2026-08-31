import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/translations.dart';

class LanguageSelectionDialog {
  static const List<Map<String, String>> languages = [
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

  static Future<void> show(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentLang = appState.languageCode;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: Colors.teal.shade800,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Translations.get(currentLang, 'language_selection'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4332),
                            ),
                          ),
                          Text(
                            Translations.get(currentLang, 'language_subtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: languages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = languages[index];
                      final isSelected = currentLang == item['code'];
                      return Material(
                        color: isSelected
                            ? const Color(0xFFD8F3DC)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final selectedCode = item['code']!;
                            await appState.setLanguage(selectedCode);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  item['flag']!,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF1B4332)
                                              : Colors.blueGrey.shade900,
                                        ),
                                      ),
                                      Text(
                                        item['subtitle']!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isSelected
                                              ? const Color(0xFF2D6A4F)
                                              : Colors.blueGrey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF1B4332),
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
