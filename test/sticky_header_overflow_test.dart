import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String getTestAyahLabel(String lang) {
  switch (lang) {
    case 'ar':
      return 'آية';
    case 'af':
      return 'Vers';
    case 'sw':
      return 'Aya';
    case 'en':
      return 'Ayah';
    case 'ms':
    case 'id':
    default:
      return 'Ayat';
  }
}

String getTestVoiceLabel(String lang, {required bool isCompact, required bool isPreparing}) {
  if (isPreparing) {
    if (isCompact) {
      switch (lang) {
        case 'en':
          return 'Wait...';
        case 'ar':
          return 'انتظر...';
        case 'af':
          return 'Wag...';
        case 'sw':
          return 'Subiri...';
        case 'ms':
        case 'id':
        default:
          return 'Tunggu...';
      }
    } else {
      switch (lang) {
        case 'en':
          return 'Preparing...';
        case 'ar':
          return 'جارٍ الإعداد...';
        case 'af':
          return 'Berei voor...';
        case 'sw':
          return 'Inaandaa...';
        case 'ms':
        case 'id':
        default:
          return 'Menyiapkan...';
      }
    }
  }

  if (isCompact) {
    switch (lang) {
      case 'en':
        return 'Voice';
      case 'ar':
        return 'صوت';
      case 'af':
        return 'Stem';
      case 'sw':
        return 'Sauti';
      case 'ms':
      case 'id':
      default:
        return 'Suara';
    }
  } else {
    return 'Voice';
  }
}

String getTestSilentLabel(String lang, {required bool isCompact}) {
  if (isCompact) {
    switch (lang) {
      case 'en':
        return 'Silent';
      case 'ar':
        return 'قلب';
      case 'af':
        return 'Stil';
      case 'sw':
        return 'Moyoni';
      case 'ms':
      case 'id':
      default:
        return 'Hati';
    }
  } else {
    switch (lang) {
      case 'en':
        return 'Silent';
      case 'ar':
        return 'في القلب';
      case 'af':
        return 'Stil Lees';
      case 'sw':
        return 'Moyoni';
      case 'ms':
      case 'id':
      default:
        return 'Dalam Hati';
    }
  }
}

Widget buildTestStickyHeader({
  required double width,
  required double textScale,
  required bool isRecording,
  required bool isEyeReading,
  required bool isMicReady,
  required bool isEyeFocused,
  required String recognizedText,
  required int ayahIndex,
  required String lang,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      textScaler: TextScaler.linear(textScale),
    ),
    child: Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        child: Container(
          width: width,
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.teal, width: 1.2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final effectiveWidth =
                  constraints.maxWidth / (textScale > 0 ? textScale : 1.0);
              final isVeryNarrow = effectiveWidth < 250;
              final ayahLabel = getTestAyahLabel(lang);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Ayah badge
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark_outline_rounded,
                                  size: 13,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$ayahLabel ${ayahIndex + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVeryNarrow ? 7 : 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isRecording
                                      ? Colors.red
                                      : Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (isRecording && !isMicReady)
                                          ? Icons.hourglass_top_rounded
                                          : (isRecording ? Icons.mic : Icons.mic_none),
                                      size: 14,
                                    ),
                                    if (!isVeryNarrow) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        getTestVoiceLabel(
                                          lang,
                                          isCompact: true,
                                          isPreparing: isRecording && !isMicReady,
                                        ),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVeryNarrow ? 7 : 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isEyeReading
                                      ? (isEyeFocused ? Colors.green : Colors.orange)
                                      : Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isEyeReading
                                          ? (isEyeFocused
                                              ? Icons.visibility
                                              : Icons.visibility_off)
                                          : Icons.remove_red_eye_rounded,
                                      size: 14,
                                    ),
                                    if (!isVeryNarrow) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        getTestSilentLabel(lang, isCompact: true),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // If listening / recording info content:
                  if (isRecording)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !isMicReady
                              ? Colors.amber.shade50
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isMicReady
                                ? Colors.amber.shade300
                                : Colors.teal.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  !isMicReady
                                      ? Icons.hourglass_top_rounded
                                      : (recognizedText.isEmpty
                                          ? Icons.mic_rounded
                                          : Icons.hearing_rounded),
                                  size: 16,
                                  color: !isMicReady
                                      ? Colors.amber.shade800
                                      : Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    !isMicReady
                                        ? "Microphone is preparing, please wait..."
                                        : (recognizedText.isEmpty
                                            ? "Listening... (Please recite now)"
                                            : recognizedText),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: !isMicReady
                                          ? Colors.amber.shade900
                                          : Colors.teal.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (isMicReady && recognizedText.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.teal.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      "Verifying recitation...",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.teal.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  // If eye tracking info content:
                  if (isEyeReading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isEyeFocused
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isEyeFocused
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEyeFocused
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 14,
                              color: isEyeFocused
                                  ? Colors.green.shade800
                                  : Colors.red.shade700,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isEyeFocused
                                    ? "Eye Detected: Reading..."
                                    : "NOT FOCUSED: Look at Ayah to read",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isEyeFocused
                                      ? Colors.green.shade800
                                      : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Test sticky header across 6 languages, widths, and font scales',
      (tester) async {
    final widths = [
      240.0,
      260.0,
      280.0,
      300.0,
      320.0,
      340.0,
      360.0,
      375.0,
      390.0,
      412.0
    ];
    final textScales = [1.0, 1.15, 1.3, 1.5, 1.8];
    final languages = ['id', 'en', 'ms', 'ar', 'af', 'sw'];
    final states = [
      {'rec': false, 'eye': false, 'micReady': false, 'recText': ''},
      {'rec': true, 'eye': false, 'micReady': false, 'recText': ''}, // Preparing mic
      {'rec': true, 'eye': false, 'micReady': true, 'recText': 'الذين يؤمنون بالغيب'}, // Listening
      {'rec': false, 'eye': true, 'micReady': false, 'recText': '', 'eyeFocused': true},
      {'rec': false, 'eye': true, 'micReady': false, 'recText': '', 'eyeFocused': false},
    ];

    for (final lang in languages) {
      for (final w in widths) {
        for (final s in textScales) {
          for (final state in states) {
            await tester.pumpWidget(
              buildTestStickyHeader(
                width: w,
                textScale: s,
                isRecording: state['rec'] as bool,
                isEyeReading: state['eye'] as bool,
                isMicReady: state['micReady'] as bool,
                isEyeFocused: (state['eyeFocused'] as bool?) ?? false,
                recognizedText: state['recText'] as String,
                ayahIndex: 281, // Ayah 282 (longest ayah)
                lang: lang,
              ),
            );
            expect(
              tester.takeException(),
              isNull,
              reason: 'Failed in lang $lang at width $w, scale $s, state $state',
            );
          }
        }
      }
    }
  });
}
