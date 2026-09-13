import 'package:flutter_test/flutter_test.dart';

// Standalone functions mimicking surah_detail_screen implementation for validation
String normalizeArabicText(String text) {
  if (text.isEmpty) return text;

  // 1. Strip Tajweed tags
  String clean = text.replaceAll(RegExp(r'\[[a-zA-Z0-9:]*\[|\]'), '');

  // 2. Remove Tashkeel, Quranic diacritics, Tatweel (ـ / \u0640), and Dagger Alif (\u0670)
  clean = clean.replaceAll(
    RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'),
    '',
  );

  // 3. Normalize all forms of Alif to standard bare Alif (ا - \u0627)
  clean = clean.replaceAll(RegExp(r'[أإآٱٲٳ]'), 'ا');

  // 4. Normalize Ta Marbuta (ة) to Ha (ه)
  clean = clean.replaceAll('ة', 'ه');

  // 5. Normalize Alif Maqsura (ى) to Ya (ي)
  clean = clean.replaceAll('ى', 'ي');

  // 6. Normalize Rasm Utsmani words
  clean = clean.replaceAll(RegExp(r'صل[واه]+ه'), 'صلاه');
  clean = clean.replaceAll(RegExp(r'زك[واه]+ه'), 'زكاه');
  clean = clean.replaceAll(RegExp(r'حي[واه]+ه'), 'حياه');
  clean = clean.replaceAll(RegExp(r'مشك[واه]+ه'), 'مشكاه');
  clean = clean.replaceAll(RegExp(r'رب[واه]+[ا]?'), 'ربا');

  // 7. Remove non-Arabic letters or punctuation
  clean = clean.replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), '');

  return clean.trim();
}

int levenshteinDistance(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
  List<int> v1 = List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < t.length; j++) {
      int cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = [
        v1[j] + 1,
        v0[j + 1] + 1,
        v0[j] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
    for (int j = 0; j <= t.length; j++) {
      v0[j] = v1[j];
    }
  }
  return v0[t.length];
}

bool isWordMatch(String targetWord, String recWord) {
  if (targetWord == recWord) return true;
  if (targetWord.isEmpty || recWord.isEmpty) return false;

  if (targetWord.length >= 3 && recWord.length >= 3) {
    if (targetWord.contains(recWord) || recWord.contains(targetWord)) {
      return true;
    }
  }

  final distance = levenshteinDistance(targetWord, recWord);
  if (targetWord.length <= 4) {
    return distance <= 1;
  } else {
    final maxLen = targetWord.length > recWord.length
        ? targetWord.length
        : recWord.length;
    final similarity = 1.0 - (distance / maxLen);
    return distance <= 2 || similarity >= 0.65;
  }
}

({
  int matchCount,
  int totalWords,
  double matchPercentage,
  bool isStartWordMatched,
  bool isEndWordMatched,
  int firstMatchedTargetIndex,
  int lastMatchedTargetIndex,
}) calculateMatchMetrics(String recognized, String target) {
  if (recognized.trim().isEmpty || target.trim().isEmpty) {
    return (
      matchCount: 0,
      totalWords: 0,
      matchPercentage: 0.0,
      isStartWordMatched: false,
      isEndWordMatched: false,
      firstMatchedTargetIndex: -1,
      lastMatchedTargetIndex: -1,
    );
  }

  final normRecognized = normalizeArabicText(recognized);
  final normTarget = normalizeArabicText(target);

  final recWords = normRecognized
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  final targetWords = normTarget
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  if (targetWords.isEmpty) {
    return (
      matchCount: 0,
      totalWords: 0,
      matchPercentage: 0.0,
      isStartWordMatched: false,
      isEndWordMatched: false,
      firstMatchedTargetIndex: -1,
      lastMatchedTargetIndex: -1,
    );
  }

  int matchCount = 0;
  int firstMatchedTargetIndex = -1;
  int lastMatchedTargetIndex = -1;
  List<String> remainingRecWords = List.from(recWords);

  for (int tIdx = 0; tIdx < targetWords.length; tIdx++) {
    final tWord = targetWords[tIdx];
    int foundIdx = -1;

    for (int rIdx = 0; rIdx < remainingRecWords.length; rIdx++) {
      if (isWordMatch(tWord, remainingRecWords[rIdx])) {
        foundIdx = rIdx;
        break;
      }
    }

    if (foundIdx != -1) {
      matchCount++;
      if (firstMatchedTargetIndex == -1) {
        firstMatchedTargetIndex = tIdx;
      }
      lastMatchedTargetIndex = tIdx;
      remainingRecWords.removeAt(foundIdx);
    }
  }

  final double matchPercentage = matchCount / targetWords.length;

  final int startThresholdIndex = targetWords.length <= 3
      ? (targetWords.length == 1 ? 0 : 1)
      : (targetWords.length <= 6 ? 1 : (targetWords.length * 0.35).floor());

  final int endThresholdIndex = targetWords.length <= 3
      ? (targetWords.length == 1 ? 0 : 1)
      : (targetWords.length <= 6
          ? targetWords.length - 2
          : (targetWords.length * 0.75).floor().clamp(0, targetWords.length - 2));

  final bool isStartWordMatched = firstMatchedTargetIndex != -1 &&
      firstMatchedTargetIndex <= startThresholdIndex;
  final bool isEndWordMatched = lastMatchedTargetIndex != -1 &&
      lastMatchedTargetIndex >= endThresholdIndex;

  return (
    matchCount: matchCount,
    totalWords: targetWords.length,
    matchPercentage: matchPercentage,
    isStartWordMatched: isStartWordMatched,
    isEndWordMatched: isEndWordMatched,
    firstMatchedTargetIndex: firstMatchedTargetIndex,
    lastMatchedTargetIndex: lastMatchedTargetIndex,
  );
}

bool checkMatch(
  String recognized,
  String target,
  double elapsedSeconds, {
  bool isFinalEvaluation = false,
}) {
  final metrics = calculateMatchMetrics(recognized, target);
  if (metrics.totalWords == 0) return false;

  final minDurationSeconds = (metrics.totalWords * 0.30).clamp(1.0, 120.0);
  if (elapsedSeconds < minDurationSeconds) {
    return false;
  }

  if (metrics.totalWords <= 3) {
    final requiredWords = metrics.totalWords == 1 ? 1 : 2;
    return metrics.matchCount >= requiredWords && metrics.isEndWordMatched;
  }

  final requiredMatches = (metrics.totalWords * 0.40).ceil().clamp(2, metrics.totalWords);
  return metrics.matchCount >= requiredMatches &&
      metrics.isStartWordMatched &&
      metrics.isEndWordMatched;
}

void main() {
  group('Quran Speech Matching & Anti-Gaming Tests', () {
    const rawTargetAyah3 =
        'ٱلَّذِينَ يُؤْمِنُونَ بِ[h:13[ٱ]لْغَيْبِ وَيُقِيمُونَ [h:14[ٱ][l[ل]صَّلَ[s[و][n[ٲ]ةَ وَمِ[g[مّ]َا رَزَ[q:15[قْ]نَ[n[ـٰ]هُمْ يُ[f:16[نف]ِق[p[ُو]نَ';

    test('Normalizes Uthmani text with tajweed tags to standard Arabic', () {
      final normalized = normalizeArabicText(rawTargetAyah3);
      expect(normalized.startsWith('الذin') || normalized.startsWith('الذين'), isTrue);
      expect(normalized.contains('الصلاه'), isTrue);
      expect(normalized.contains('بالغيب'), isTrue);
    });

    test('Fuzzy matching recognizes STT phonetically misheard words', () {
      expect(isWordMatch('ويقيمون', 'ويوكمون'), isTrue);
    });

    test('Screenshot scenario passes when full ayah is recited with adequate duration', () {
      const userScreenshotSTT =
          'الذين يؤمنون بالغيب ويوكمون الصلاه ومما رزقكم ولهم ينفقون';

      final metrics = calculateMatchMetrics(userScreenshotSTT, rawTargetAyah3);
      expect(metrics.totalWords, equals(8));
      expect(metrics.matchCount, greaterThanOrEqualTo(6));
      expect(metrics.isStartWordMatched, isTrue);
      expect(metrics.isEndWordMatched, isTrue);

      // Fails if user only read for 0.5 seconds (faster than realistic human)
      expect(checkMatch(userScreenshotSTT, rawTargetAyah3, 0.5), isFalse);

      // Passes when realistic reading duration is met
      expect(checkMatch(userScreenshotSTT, rawTargetAyah3, 5.0), isTrue);
    });

    test('Imperfect STT that reads through from start to end passes', () {
      // User read through, STT heard 4 words: "الذين ... بالغيب ... الصلاه ... ينفقون"
      const imperfectSTT = 'الذين بالغيب الصلاه ينفقون';

      final metrics = calculateMatchMetrics(imperfectSTT, rawTargetAyah3);
      expect(metrics.matchCount, equals(4));
      expect(metrics.isStartWordMatched, isTrue); // Matched word 0 "الذين"
      expect(metrics.isEndWordMatched, isTrue);   // Matched word 7 "ينفقون"
      expect(checkMatch(imperfectSTT, rawTargetAyah3, 3.5), isTrue);
    });

    test('Anti-cheat: Waiting and only reading the tail end is BLOCKED', () {
      // User waits 10s and only recites the last 3 words: "ومما رزقناهم ينفقون"
      const tailOnlySTT = 'ومما رزقناهم ينفقون';
      final metrics = calculateMatchMetrics(tailOnlySTT, rawTargetAyah3);
      expect(metrics.isStartWordMatched, isFalse); // First matched index is 5 > 2
      expect(metrics.isEndWordMatched, isTrue);
      expect(checkMatch(tailOnlySTT, rawTargetAyah3, 10.0), isFalse);
    });

    test('Anti-cheat: Only reading the first word and last word is BLOCKED', () {
      // User says word 0 "الذين", waits 10s, says word 7 "ينفقون" (skipping middle)
      const firstAndLastOnlySTT = 'الذين ينفقون';
      final metrics = calculateMatchMetrics(firstAndLastOnlySTT, rawTargetAyah3);
      expect(metrics.matchCount, equals(2)); // Only 2 words < required 4 words
      expect(checkMatch(firstAndLastOnlySTT, rawTargetAyah3, 10.0), isFalse);
    });

    test('Anti-cheat: Reading 50% to 62% is BLOCKED', () {
      const halfRecitedSTT = 'الذين يؤمنون بالغيب ويقيمون';
      final metrics4 = calculateMatchMetrics(halfRecitedSTT, rawTargetAyah3);
      expect(metrics4.isEndWordMatched, isFalse);
      expect(checkMatch(halfRecitedSTT, rawTargetAyah3, 15.0), isFalse);
    });

    test('Slow beginner reciter: full ayah with slow pace passes correctly', () {
      const slowRecitedSTT = 'الذين يؤمنون بالغيب ويقيمون الصلاه ومما رزقناهم ينفقون';
      expect(checkMatch(slowRecitedSTT, rawTargetAyah3, 20.0), isTrue);
    });

    test('Long Ayah detection accurately classifies short vs long ayahs', () {
      bool isLongAyah(String arabic) {
        final clean = arabic.replaceAll(RegExp(r'\[[a-zA-Z0-9:]*\[|\]'), '');
        final words = clean.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        return words >= 18 || clean.trim().length >= 130;
      }

      // Short: Al-Fatihah 1
      expect(isLongAyah('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), isFalse);

      // Short: Al-Baqarah 2
      expect(isLongAyah('ذَٰلِكَ الْكِتَابُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ'), isFalse);

      // Short: Al-Baqarah 3 (8 words)
      expect(isLongAyah(rawTargetAyah3), isFalse);

      // Moderately Long: Al-Baqarah 19 (25 words)
      const ayah19 = 'أَوْ كَصَيِّبٍ مِّنَ السَّمَاءِ فِيهِ ظُلُمَاتٌ وَرَعْدٌ وَبَرْقٌ يَجْعَلُونَ أَصَابِعَهُمْ فِي آذَانِهِم مِّنَ الصَّوَاعِقِ حَذَرَ الْمَوْتِ ۚ وَاللَّهُ مُحِيطٌ بِالْكَافِرِينَ';
      expect(isLongAyah(ayah19), isTrue);

      // Long: Ayat Kursi (Al-Baqarah 255) (50 words)
      const ayatKursi = 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ';
      expect(isLongAyah(ayatKursi), isTrue);
    });
  });
}
