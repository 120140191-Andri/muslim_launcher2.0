import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'package:intl/intl.dart';
import '../../utils/translations.dart';

class ReadingHistoryScreen extends StatelessWidget {
  const ReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final history = appState.readingHistory;
    final lang = appState.languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: Text(Translations.get(lang, 'reading_history')),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: history.isEmpty
          ? _buildEmptyState(lang)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final timestamp = entry['timestamp'];
                final int ts = (timestamp is int)
                    ? timestamp
                    : (int.tryParse(timestamp.toString()) ?? 0);
                final date = DateTime.fromMillisecondsSinceEpoch(ts);
                final formattedDate = ts == 0
                    ? '--'
                    : DateFormat('dd MMM yyyy, HH:mm').format(date);

                final titleStr = entry['surah'] as String? ?? '';
                final isHadith = titleStr.startsWith('Hadits');
                final isDzikir = titleStr.startsWith('Dzikir');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDzikir
                            ? const Color(0xFFCCFBF1)
                            : isHadith
                            ? const Color(0xFFD8F3DC)
                            : Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDzikir
                            ? Icons.grain_rounded
                            : isHadith
                            ? Icons.spa_rounded
                            : Icons.menu_book_rounded,
                        color: isDzikir
                            ? const Color(0xFF0F766E)
                            : isHadith
                            ? const Color(0xFF1B4332)
                            : Colors.teal.shade700,
                      ),
                    ),
                    title: Text(
                      (isHadith || isDzikir)
                          ? titleStr
                          : "$titleStr : ${Translations.get(lang, 'ayah')} ${entry['ayah']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: entry['points'] != null && entry['points'] > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  color: Colors.amber.shade700,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "+${entry['points']}",
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.teal.shade100),
          const SizedBox(height: 16),
          Text(
            Translations.get(lang, 'no_history_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Translations.get(lang, 'no_history_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
