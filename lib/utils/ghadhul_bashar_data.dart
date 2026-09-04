import 'dart:math';

class GhadhulBasharVerse {
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final Map<String, String> translations;

  const GhadhulBasharVerse({
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.translations,
  });

  String getReference() => 'QS. $surahName ($surahNumber:$ayahNumber)';

  String getTranslation(String lang) {
    return translations[lang] ??
        translations['en'] ??
        translations['id'] ??
        '';
  }
}

class GhadhulBasharData {
  static const List<GhadhulBasharVerse> verses = [
    // 1. QS. An-Nur: 30 (Menundukkan pandangan bagi laki-laki)
    GhadhulBasharVerse(
      surahName: 'An-Nur',
      surahNumber: 24,
      ayahNumber: 30,
      arabic:
          'قُلْ لِّلْمُؤْمِنِينَ يَغُضُّوا مِنْ أَبْصَارِهِمْ وَيَحْفَظُوا فُرُوجَهُمْ ۚ ذَٰلِكَ أَزْكَىٰ لَهُمْ ۗ إِنَّ اللَّهَ خَبِيرٌ بِمَا يَصْنَعُونَ',
      translations: {
        'id':
            'Katakanlah kepada laki-laki yang beriman, agar mereka menjaga pandangannya, dan memelihara kemaluannya; yang demikian itu lebih suci bagi mereka. Sungguh, Allah Maha Mengetahui apa yang mereka perbuat.',
        'en':
            'Tell the believing men to lower their gaze and guard their modesty. That is purer for them. Indeed, Allah is All-Aware of what they do.',
        'ms':
            'Katakanlah kepada orang-orang lelaki yang beriman, hendaklah mereka menundukkan pandangan mereka dan memelihara kehormatan mereka; yang demikian itu lebih suci bagi mereka. Sesungguhnya Allah Maha Mengetahui apa yang mereka kerjakan.',
        'ar':
            'قُل لِّلْمُؤْمِنِينَ يَغُضُّوا مِنْ أَبْصَارِهِمْ وَيَحْفَظُوا فُرُوجَهُمْ ۚ ذَٰلِكَ أَزْكَىٰ لَهُمْ ۗ إِنَّ اللَّهَ خَبِيرٌ بِمَا يَصْنَعُونَ',
        'af':
            'Sê vir die gelowige mans om hul oë neer te slaan en hul kuisheid te bewaar; dit is reiner vir hulle. Voorwaar, Allah is deurborend bewus van wat hulle doen.',
        'sw':
            'Waambie Waumini wanaume wainamishe macho yao, na wazilinde tupu zao. Hili ni takaso zaidi kwao. Hakika Mwenyezi Mungu anazo habari za wanayo yafanya.',
      },
    ),
    // 2. QS. An-Nur: 31 (Menundukkan pandangan bagi perempuan)
    GhadhulBasharVerse(
      surahName: 'An-Nur',
      surahNumber: 24,
      ayahNumber: 31,
      arabic:
          'وَقُلْ لِّلْمُؤْمِنَاتِ يَغْضُضْنَ مِنْ أَبْصَارِهِنَّ وَيَحْفَظْنَ فُرُوجَهُنَّ',
      translations: {
        'id':
            'Dan katakanlah kepada para perempuan yang beriman, agar mereka menjaga pandangannya, dan memelihara kemaluannya...',
        'en':
            'And tell the believing women to lower their gaze and guard their modesty...',
        'ms':
            'Dan katakanlah kepada perempuan-perempuan yang beriman, hendaklah mereka menundukkan pandangan mereka dan memelihara kehormatan mereka...',
        'ar':
            'وَقُل لِّلْمُؤْمِنَاتِ يَغْضُضْنَ مِنْ أَبْصَارِهِنَّ وَيَحْفَظْنَ فُرُوجَهُنَّ',
        'af':
            'En sê vir die gelowige vroue om hul oë neer te slaan en hul kuisheid te bewaar...',
        'sw':
            'Na waambie Waumini wanawake wainamishe macho yao, na wazilinde tupu zao...',
      },
    ),
    // 3. QS. Al-Isra': 32 (Jangan mendekati zina)
    GhadhulBasharVerse(
      surahName: 'Al-Isra\'',
      surahNumber: 17,
      ayahNumber: 32,
      arabic:
          'وَلَا تَقْرَبُوا الزِّنَىٰ ۖ إِنَّهُ كَانَ فَاحِشَةً وَسَاءَ سَبِيلًا',
      translations: {
        'id':
            'Dan janganlah kamu mendekati zina; sesungguhnya (zina) itu adalah suatu perbuatan yang keji dan suatu jalan yang buruk.',
        'en':
            'And do not approach unlawful sexual intercourse. Indeed, it is ever an immorality and is an evil way.',
        'ms':
            'Dan janganlah kamu menghampiri zina; sesungguhnya zina itu adalah satu perbuatan yang keji dan satu jalan yang jahat.',
        'ar':
            'وَلَا تَقْرَبُوا الزِّنَىٰ ۖ إِنَّهُ كَانَ فَاحِشَةً وَسَاءَ سَبِيلًا',
        'af':
            'En nader nie onwettige gemeenskap nie; voorwaar, dit is \'n skandelikheid en \'n bose weg.',
        'sw':
            'Wala msikaribie uzinzi. Hakika huo ni uchafu na njia mbaya.',
      },
    ),
    // 4. QS. Al-Isra': 36 (Pertanggungjawaban pendengaran, penglihatan, dan hati)
    GhadhulBasharVerse(
      surahName: 'Al-Isra\'',
      surahNumber: 17,
      ayahNumber: 36,
      arabic:
          'إِنَّ السَّمْعَ وَالْبَصَرَ وَالْفُؤَادَ كُلُّ أُولَٰئِكَ كَانَ عَنْهُ مَسْئُولًا',
      translations: {
        'id':
            'Sesungguhnya pendengaran, penglihatan, dan hati, semuanya itu akan diminta pertanggungjawabannya.',
        'en':
            'Indeed, the hearing, the sight and the heart - about all those one will be questioned.',
        'ms':
            'Sesungguhnya pendengaran dan penglihatan serta hati nurani, tiap-tiap satu daripadanya akan ditanya (dipertanggungjawabkan).',
        'ar':
            'إِنَّ السَّمْعَ وَالْبَصَرَ وَالْفُؤَادَ كُلُّ أُولَٰئِكَ كَانَ عَنْهُ مَسْئُولًا',
        'af':
            'Voorwaar, die gehoor, die gesig en die hart - oor almal sal gevra word.',
        'sw':
            'Hakika masikio, na macho, na mtima - hivyo vyote vitasailiwa.',
      },
    ),
    // 5. QS. Ghafir: 19 (Allah mengetahui pandangan mata yang khianat)
    GhadhulBasharVerse(
      surahName: 'Ghafir',
      surahNumber: 40,
      ayahNumber: 19,
      arabic: 'يَعْلَمُ خَائِنَةَ الْأَعْيُنِ وَمَا تُخْفِي الصُّدُورُ',
      translations: {
        'id':
            'Dia (Allah) mengetahui (pandangan) mata yang khianat dan apa yang tersembunyi di dalam dada.',
        'en':
            'He knows that which deceives the eyes and what the breasts conceal.',
        'ms':
            'Allah mengetahui khianat mata (pandangan yang curi-curi) dan apa yang disembunyikan oleh hati.',
        'ar': 'يَعْلَمُ خَائِنَةَ الْأَعْيُنِ وَمَا تُخْفِي الصُّدُورُ',
        'af': 'Hy weet wat die oë bedrieg en wat die borskas verberg.',
        'sw': 'Anajua khiana ya macho na yanayo ficha vifua.',
      },
    ),
    // 6. QS. Al-A'raf: 33 (Pengharaman perbuatan keji yang tampak maupun tersembunyi)
    GhadhulBasharVerse(
      surahName: 'Al-A\'raf',
      surahNumber: 7,
      ayahNumber: 33,
      arabic:
          'قُلْ إِنَّمَا حَرَّمَ رَبِّيَ الْفَوَاحِشَ مَا ظَهَرَ مِنْهَا وَمَا بَطَنَ',
      translations: {
        'id':
            'Katakanlah (Muhammad), \'Tuhanku hanya mengharamkan segala perbuatan keji, baik yang terlihat maupun yang tersembunyi...\'',
        'en':
            'Say, \'My Lord has only forbidden immoralities - what is apparent of them and what is concealed...\'',
        'ms':
            'Katakanlah: \'Tuhanku hanya mengharamkan perbuatan-perbuatan yang keji, sama ada yang nyata daripadanya atau yang tersembunyi...\'',
        'ar':
            'قُلْ إِنَّمَا حَرَّمَ رَبِّيَ الْفَوَاحِشَ مَا ظَهَرَ مِنْهَا وَمَا بَطَنَ',
        'af':
            'Sê: \'My Here het slegs onsedelikhede verbied - wat daarvan sigbaar is en wat verborge is...\'',
        'sw':
            'Sema: \'Mola wangu amekataza mambo maovu, yaliyo dhihiri na yaliyo fichika...\'',
      },
    ),
  ];

  static GhadhulBasharVerse getRandomVerse() {
    final random = Random();
    return verses[random.nextInt(verses.length)];
  }
}
