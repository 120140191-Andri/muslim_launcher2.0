import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../utils/translations.dart';
import '../../widgets/language_selection_dialog.dart';
import 'hadith_detail_screen.dart';

class HadithListScreen extends StatefulWidget {
  const HadithListScreen({super.key});

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  String _selectedTheme = '';

  String _getHadithTheme(Map<String, dynamic> item, String lang) {
    final themes = item['themes'] as Map<String, dynamic>?;
    if (themes != null) {
      return themes[lang] as String? ??
          themes['en'] as String? ??
          themes['id'] as String? ??
          item['theme'] as String? ??
          '';
    }
    return item['theme'] as String? ?? '';
  }

  int _calculateHadithPoints(String arabic, String translation) {
    final arabicBonus = arabic.trim().length ~/ 25;
    final translationBonus = translation.trim().length ~/ 60;
    return (3 + arabicBonus + translationBonus).clamp(3, 8);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final lang = appState.languageCode;
    final allHadiths = appState.hadithData;

    // Extract unique localized themes
    final themes = <String>{};
    for (final item in allHadiths) {
      if (item is Map<String, dynamic>) {
        final t = _getHadithTheme(item, lang);
        if (t.isNotEmpty) themes.add(t);
      }
    }
    final themeList = [Translations.get(lang, 'theme_all'), ...themes];

    // Filter hadiths based on selected theme
    final filteredHadiths = allHadiths.where((item) {
      if (item is! Map<String, dynamic>) return false;
      final theme = _getHadithTheme(item, lang);

      final matchesTheme = _selectedTheme.isEmpty ||
          _selectedTheme == Translations.get(lang, 'theme_all') ||
          theme == _selectedTheme;

      return matchesTheme;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          Translations.get(lang, 'hadith_collection'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded, size: 22),
            tooltip: Translations.get(lang, 'language_selection'),
            onPressed: () {
              LanguageSelectionDialog.show(context);
              setState(() {
                _selectedTheme = '';
              });
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${appState.points}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card: Hadith Mode Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            decoration: BoxDecoration(
              color: Colors.teal.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa_rounded, color: Color(0xFF4ADE80), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        Translations.get(lang, 'hadith_mode_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Translations.get(lang, 'hadith_mode_desc'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Theme Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: themeList.map((theme) {
                final isSelected = (_selectedTheme.isEmpty &&
                        theme == Translations.get(lang, 'theme_all')) ||
                    _selectedTheme == theme;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      theme,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.teal.shade800,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTheme = selected ? theme : '';
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.teal.shade700,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.teal.shade100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),

          // Hadith List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filteredHadiths.length,
              itemBuilder: (context, index) {
                final item = filteredHadiths[index] as Map<String, dynamic>;
                final hadithId = item['id'] as int? ?? (index + 1);
                final isRead = appState.isHadithRead(hadithId);
                final theme = _getHadithTheme(item, lang);
                final arabic = item['arabic'] as String? ?? '';
                final translations =
                    item['translations'] as Map<String, dynamic>? ?? {};
                final narrators =
                    item['narrators'] as Map<String, dynamic>? ?? {};

                final translationText = translations[lang] as String? ??
                    translations['en'] as String? ??
                    translations['id'] as String? ??
                    '';
                final narratorText = narrators[lang] as String? ??
                    narrators['en'] as String? ??
                    narrators['id'] as String? ??
                    '';

                final pts = _calculateHadithPoints(arabic, translationText);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isRead ? Colors.teal.shade300 : Colors.teal.shade50,
                      width: isRead ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        final originalIndex = allHadiths.indexOf(item);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HadithDetailScreen(
                              hadith: item,
                              hadithIndex:
                                  originalIndex >= 0 ? originalIndex : index,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header: Number + Theme Badge + Completion Status
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? Colors.teal.shade700
                                        : Colors.teal.shade800,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "#$hadithId",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    theme,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.teal.shade900,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isRead)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 14,
                                          color: Colors.teal.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          Translations.get(
                                            lang,
                                            'hadith_completed',
                                          ),
                                          style: TextStyle(
                                            color: Colors.teal.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.stars_rounded,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+$pts ${Translations.get(lang, 'points')}',
                                          style: TextStyle(
                                            color: Colors.amber.shade900,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Arabic snippet
                            Text(
                              arabic,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                fontFamily: 'Amiri',
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Translation snippet
                            Text(
                              '"$translationText"',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade700,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                            if (narratorText.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 12,
                                    color: Colors.teal.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      narratorText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
