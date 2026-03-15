import 'dart:convert';
import 'dart:io';

void main() async {
  print("Loading datasets...");
  
  List<String> loadLines(String filepath) {
    var file = File(filepath);
    if (!file.existsSync()) {
      print("File not found: $filepath");
      return [];
    }
    return file.readAsLinesSync().where((line) {
      var t = line.trim();
      return t.isNotEmpty && !t.startsWith('#') && !t.startsWith('=');
    }).toList();
  }

  var arabicLines = loadLines('d:/Coding/Flutter/Muslim Launcher 2/data_temp/quran-tajweed.txt');
  var latinLines = loadLines('d:/Coding/Flutter/Muslim Launcher 2/data_temp/en.transliteration.txt');
  var idTransLines = loadLines('d:/Coding/Flutter/Muslim Launcher 2/data_temp/id.indonesian.txt');
  var enTransLines = loadLines('d:/Coding/Flutter/Muslim Launcher 2/data_temp/en.sahih.txt');

  print("Lines found: Arabic(${arabicLines.length}), Latin(${latinLines.length}), ID Trans(${idTransLines.length}), EN Trans(${enTransLines.length})");

  print("Extracting metadata from existing quran.json...");
  var surahMeta = <int, Map<String, dynamic>>{};
  var quranFile = File('d:/Coding/Flutter/Muslim Launcher 2/assets/quran.json');
  if (quranFile.existsSync()) {
    var content = quranFile.readAsStringSync();
    var existingQuran = json.decode(content) as List;
    for (var surah in existingQuran) {
      var num = surah['surah_number'] as int;
      surahMeta[num] = {
        'surah_name': surah['surah_name'],
        'total_ayah': surah['total_ayah'],
      };
    }
  }

  print("Merging data into new structure...");
  var newQuran = [];
  
  int lineIndex = 0;

  for (var surahNum = 1; surahNum <= 114; surahNum++) {
    var surahInfo = {
      "surah_number": surahNum,
      "surah_name": surahMeta[surahNum]?['surah_name'] ?? "Surah $surahNum",
      "total_ayah": surahMeta[surahNum]?['total_ayah'] ?? 0,
      "ayahs": []
    };

    var totalAyah = surahInfo["total_ayah"] as int;
    for (var ayahNum = 1; ayahNum <= totalAyah; ayahNum++) {
      String arabic = (lineIndex < arabicLines.length) ? arabicLines[lineIndex] : "";
      
      surahInfo["ayahs"].add({
        "ayah_number": ayahNum,
        "arabic": arabic,
        "latin": (lineIndex < latinLines.length) ? latinLines[lineIndex] : "",
        "translation_id": (lineIndex < idTransLines.length) ? idTransLines[lineIndex] : "",
        "translation_en": (lineIndex < enTransLines.length) ? enTransLines[lineIndex] : ""
      });
      lineIndex++;
    }
    newQuran.add(surahInfo);
  }

  print("Total processed lines: $lineIndex");

  print("Writing to assets/quran.json...");
  var encoder = JsonEncoder.withIndent(null); // Compact formatting
  var encodedJson = encoder.convert(newQuran);
  quranFile.writeAsStringSync(encodedJson);
  
  print("Done! File size: ${quranFile.lengthSync()} bytes.");
}

