import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../providers/app_state.dart';
import 'quran_tajweed_text.dart';

class SurahDetailScreen extends StatefulWidget {
  final Map<String, dynamic> surah;
  final int? initialAyahIndex;

  const SurahDetailScreen({
    super.key,
    required this.surah,
    this.initialAyahIndex,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  int? _recordingAyahIdx;
  String _recognizedText = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Auto-scroll to initial ayah if provided
    if (widget.initialAyahIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.jumpTo(index: widget.initialAyahIndex!);
      });
    }
  }

  void _initSpeech() async {
    await _speech.initialize(
      onError: (val) {
        debugPrint('onError: $val');
        if (mounted) setState(() => _recordingAyahIdx = null);
      },
      onStatus: (val) {
        debugPrint('onStatus: $val');
        if (val == 'done' || val == 'notListening') {
          if (mounted) setState(() => _recordingAyahIdx = null);
        }
      },
    );
  }

  void _onAyahMicPressed(int index, String arabic) async {
    if (_recordingAyahIdx == index) {
      _stopListening();
    } else {
      if (_recordingAyahIdx != null) _speech.stop();

      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _recordingAyahIdx = index;
          _recognizedText = "";
        });

        _speech.listen(
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0.1) {
                _onSuccess(index, arabic);
              }
            });
          },
          localeId: 'ar_SA',
        );
      }
    }
  }

  void _stopListening() {
    setState(() => _recordingAyahIdx = null);
    _speech.stop();
  }

  void _onSuccess(int index, String arabic) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Check if point should be awarded based on strict progression
    final int surahNumber = widget.surah['surah_number'];
    final bool getsPoints = appState.canEarnPoints(surahNumber - 1, index);

    if (getsPoints) {
      appState.addPoints(10);
      appState.setLastReadAyat(arabic);
    }

    // saveProgress handles history internally and only updates "Last Read" if it's new progress
    appState.saveProgress(
      surahNumber - 1,
      index,
      widget.surah['surah_name'],
      index + 1,
    );

    _stopListening();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              getsPoints ? Icons.check_circle : Icons.history_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(getsPoints ? "Masha Allah! +10 Poin" : "Riwayat Bacaan Tersimpan"),
          ],
        ),
        backgroundColor: getsPoints ? Colors.teal.shade700 : Colors.blueGrey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final ayahs = widget.surah['ayahs'] as List<dynamic>;
    final lang = appState.languageCode;

    // Check progress
    final int surahIndex = widget.surah['surah_number'] - 1;

    final bool isLastReadSurah = surahIndex == appState.currentSurahIndex;
    final int lastReadAyahIdx = appState.currentAyahIndex;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      appBar: AppBar(
        title: Text(widget.surah['surah_name']),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          _PointsBadge(points: appState.points),
          const SizedBox(width: 8),
        ],
      ),
      body: ScrollablePositionedList.builder(
        itemCount: ayahs.length + (appState.highestSurahIndex >= surahIndex && appState.highestAyahIndex == ayahs.length - 1 && surahIndex < appState.quranData.length - 1 ? 1 : 0),
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        padding: const EdgeInsets.only(top: 8, bottom: 64),

        itemBuilder: (context, index) {
          if (index == ayahs.length) {
            return _buildNextSurahButton(context, appState, surahIndex);
          }

          final ayah = ayahs[index];
          final isRecording = _recordingAyahIdx == index;
          final isLastReadAyah = isLastReadSurah && index == lastReadAyahIdx;
          
          final bool isDone = appState.isAyahReached(surahIndex, index);
          final bool isNext = appState.isNextAyah(surahIndex, index);
          final bool isFuture = !isDone && !isNext;

          return RepaintBoundary(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDone ? Colors.teal.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isLastReadAyah
                    ? Border.all(color: Colors.teal.shade200, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Opacity(
                opacity: isFuture && !isNext && !isRecording ? 0.6 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ayah Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.teal.shade100.withOpacity(0.5)
                          : Colors.teal.shade50.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.teal.shade900
                                : Colors.teal.shade800,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isLastReadAyah)
                          Text(
                            lang == 'en' ? 'Last Read' : 'Terakhir Dibaca',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else if (isNext)
                          Text(
                            lang == 'en' ? 'Next' : 'Berikutnya',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const Spacer(),
                        _MicButton(
                          isRecording: isRecording,
                          onPressed: () =>
                              _onAyahMicPressed(index, ayah['arabic']),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TajweedText(
                          text: ayah['arabic'],
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: isDone
                                ? FontWeight.bold
                                : FontWeight.w500,
                            height: 2.2,
                            fontFamily: 'Amiri',
                            color: isDone
                                ? Colors.teal.shade900
                                : Colors.black,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ayah['latin'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDone
                                ? Colors.teal.shade800
                                : Colors.teal.shade700,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang == 'en'
                              ? (ayah['translation_en'] ?? '')
                              : (ayah['translation_id'] ?? ''),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDone
                                ? Colors.teal.shade800
                                : isFuture ? Colors.grey.shade500 : Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        if (isRecording) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _recognizedText.isEmpty
                                      ? Icons.mic_none_rounded
                                      : Icons.hearing_rounded,
                                  size: 16,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _recognizedText.isEmpty
                                        ? (lang == 'en'
                                              ? 'Listening...'
                                              : 'Mendengarkan...')
                                        : _recognizedText,
                                    style: TextStyle(
                                      color: Colors.teal.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: _recognizedText.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                    textDirection: TextDirection.rtl,
                                   ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
  }

  Widget _buildNextSurahButton(BuildContext context, AppState appState, int currentSurahIdx) {
    if (currentSurahIdx >= appState.quranData.length - 1) return const SizedBox.shrink();
    
    final nextSurah = appState.quranData[currentSurahIdx + 1];
    final lang = appState.languageCode;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.teal.withOpacity(0.3),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SurahDetailScreen(surah: nextSurah),
            ),
          );
        },
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          lang == 'en' 
            ? "Next Surah: ${nextSurah['surah_name']}"
            : "Surah Selanjutnya: ${nextSurah['surah_name']}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;

  const _MicButton({required this.isRecording, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isRecording ? Colors.red : Colors.teal.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRecording ? Icons.mic : Icons.mic_none,
          color: isRecording ? Colors.white : Colors.teal.shade800,
          size: 20,
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;
  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            points.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
