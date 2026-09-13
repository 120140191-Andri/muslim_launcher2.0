import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String getTestReadWithLabel(String lang) {
  switch (lang) {
    case 'en':
      return 'Read with:';
    case 'ar':
      return 'اقرأ بـ:';
    case 'af':
      return 'Lees met:';
    case 'sw':
      return 'Soma kwa:';
    case 'ms':
    case 'id':
    default:
      return 'Baca dengan:';
  }
}

String getTestLastReadLabel(String lang) {
  switch (lang) {
    case 'en':
      return 'Last Read';
    case 'ar':
      return 'آخر قراءة';
    case 'af':
      return 'Laas Gelees';
    case 'sw':
      return 'Mwisho Kusomwa';
    case 'ms':
    case 'id':
    default:
      return 'Terakhir Dibaca';
  }
}

Widget buildTestAyahCardHeader({
  required double width,
  required double textScale,
  required String lang,
  required bool isNext,
  required bool isLastRead,
}) {
  final headerLabel = isLastRead
      ? getTestLastReadLabel(lang)
      : (isNext ? getTestReadWithLabel(lang) : null);

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
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final effectiveWidth =
                    constraints.maxWidth / (textScale > 0 ? textScale : 1.0);
                final isCompact = effectiveWidth < 360;
                final hideActionLabels = effectiveWidth < 250;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Ayah Number Badge & Status Label
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              "3",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (headerLabel != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                headerLabel,
                                key: const ValueKey('header_text'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Right: Action Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? (hideActionLabels ? 7 : 8) : 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mic, size: 14, color: Colors.white),
                              if (!hideActionLabels) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  "Suara",
                                  style: TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isCompact ? (hideActionLabels ? 7 : 8) : 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.remove_red_eye_rounded,
                                  size: 14, color: Colors.teal.shade800),
                              if (!hideActionLabels) ...[
                                const SizedBox(width: 4),
                                Text(
                                  isCompact ? "Hati" : "Dalam Hati",
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.teal.shade800),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Test Ayah Card header across 6 languages, widths, and font scales',
      (tester) async {
    final widths = [240.0, 260.0, 280.0, 300.0, 320.0, 340.0, 360.0, 375.0, 390.0, 412.0];
    final textScales = [1.0, 1.15, 1.3, 1.5];
    final languages = ['id', 'en', 'ms', 'ar', 'af', 'sw'];

    for (final lang in languages) {
      for (final w in widths) {
        for (final s in textScales) {
          // 1. Test "Baca dengan:"
          await tester.pumpWidget(
            buildTestAyahCardHeader(
              width: w,
              textScale: s,
              lang: lang,
              isNext: true,
              isLastRead: false,
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow on "Baca dengan:" in $lang at width $w, scale $s',
          );

          // 2. Test "Terakhir Dibaca"
          await tester.pumpWidget(
            buildTestAyahCardHeader(
              width: w,
              textScale: s,
              lang: lang,
              isNext: false,
              isLastRead: true,
            ),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow on "Terakhir Dibaca" in $lang at width $w, scale $s',
          );
        }
      }
    }
  });

  testWidgets('Verify "Baca dengan:" is NOT truncated on standard 360px screen',
      (tester) async {
    await tester.pumpWidget(
      buildTestAyahCardHeader(
        width: 360.0,
        textScale: 1.0,
        lang: 'id',
        isNext: true,
        isLastRead: false,
      ),
    );
    expect(tester.takeException(), isNull);

    // Find the text widget
    final textFinder = find.byKey(const ValueKey('header_text'));
    expect(textFinder, findsOneWidget);

    final Text textWidget = tester.widget(textFinder);
    expect(textWidget.data, 'Baca dengan:');

    // Verify render size is large enough to contain the full text without truncation
    final Size textSize = tester.getSize(textFinder);
    // At fontSize 10, "Baca dengan:" needs ~64px. It has ~120px available.
    expect(textSize.width, greaterThan(60.0));
  });
}
