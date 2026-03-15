class Translations {
  static const Map<String, Map<String, String>> data = {
    'id': {
      'language_selection': 'Pilih Bahasa',
      'indonesian': 'Bahasa Indonesia',
      'english': 'English',
      'next': 'Lanjut',
      'setup_title': 'Jadikan sebagai Launcher Utama',
      'setup_desc': 'Agar aplikasi ini dapat memblokir aplikasi non-produktif dengan maksimal, Anda wajib mengatur Muslim Launcher 2 sebagai aplikasi Beranda (Home App) bawaan.',
      'open_settings': 'Buka Pengaturan',
      'done': 'Selesai',
      'points': 'Poin',
      'productive': 'Produktif',
      'non_productive': 'Non-Produktif',
      'read_quran': 'Baca Al-Qur\'an',
    },
    'en': {
      'language_selection': 'Select Language',
      'indonesian': 'Bahasa Indonesia',
      'english': 'English',
      'next': 'Next',
      'setup_title': 'Set as Default Launcher',
      'setup_desc': 'To effectively block non-productive apps, you must set Muslim Launcher 2 as your default Home App.',
      'open_settings': 'Open Settings',
      'done': 'Done',
      'points': 'Points',
      'productive': 'Productive',
      'non_productive': 'Non-Productive',
      'read_quran': 'Read Qur\'an',
    }
  };

  static String get(String langCode, String key) {
    return data[langCode]?[key] ?? key;
  }
}
