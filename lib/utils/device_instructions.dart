import 'dart:ui' as ui;

/// Utility that generates device setup instructions where:
/// 1. Instructional verbs and phrasing follow the user's in-app language choice (id, en, ms, ar, af, sw).
/// 2. Target Android system menu and button names dynamically adapt to the device's system language.
class DeviceInstructions {
  static String get systemLang =>
      ui.PlatformDispatcher.instance.locale.languageCode;

  static bool get isSystemIndonesian => systemLang == 'id';
  static bool get isSystemMalay => systemLang == 'ms';
  static bool get isSystemArabic => systemLang == 'ar';

  /// Helper to get the translated target system menu name based on the phone's actual OS language
  static String _getTargetMenu({
    required String id,
    required String en,
    String? ms,
    String? ar,
  }) {
    if (systemLang == 'id') return id;
    if (systemLang == 'ms') return ms ?? id;
    if (systemLang == 'ar') return ar ?? en;
    return en; // Default to standard Android English
  }

  /// Formats target menu dynamically:
  /// If phone system language differs from app language, shows phone's actual label with translation hint.
  static String formatMenuName({
    required String idName,
    required String enName,
    String? msName,
    String? arName,
    required String appLang,
  }) {
    final targetInPhone = _getTargetMenu(
      id: idName,
      en: enName,
      ms: msName,
      ar: arName,
    );

    // If app language matches phone language, just return the exact name
    if (appLang == systemLang) {
      return '"$targetInPhone"';
    }

    // Otherwise, show target followed by translated hint if different
    String localizedHint = enName;
    if (appLang == 'id') localizedHint = idName;
    if (appLang == 'ms') localizedHint = msName ?? idName;
    if (appLang == 'ar') localizedHint = arName ?? enName;

    if (targetInPhone.toLowerCase() == localizedHint.toLowerCase()) {
      return '"$targetInPhone"';
    }
    return '"$targetInPhone" ($localizedHint)';
  }

  // ── 1. ACCESSIBILITY INSTRUCTIONS ───────────────────────────────────────────

  static List<String> getAccessibilityInstructions(
    String manufacturer,
    String appLang,
  ) {
    final m = manufacturer.toLowerCase();

    // ── A. XIAOMI / POCO / REDMI (MIUI / HYPEROS) ──
    if (m.contains('xiaomi') ||
        m.contains('poco') ||
        m.contains('redmi') ||
        m.contains('blackshark')) {
      final menu = formatMenuName(
        idName: 'Aplikasi yang didownload',
        enName: 'Downloaded Apps',
        msName: 'Aplikasi Dimuat Turun',
        arName: 'التطبيقات التي تم تنزيلها',
        appLang: appLang,
      );
      final altMenu = systemLang == 'id'
          ? 'Aplikasi terunduh'
          : (systemLang == 'ar' ? 'الخدمات التي تم تنزيلها' : 'Downloaded Services');

      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan" di bawah.',
            'Cari menu $menu (atau "$altMenu").',
            'Pilih "Muslim Launcher 2".',
            'Aktifkan sakelar "Gunakan Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan" di bawah.',
            'Cari menu $menu (atau "$altMenu").',
            'Pilih "Muslim Launcher 2".',
            'Aktifkan suis "Gunakan Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'ابحث عن قائمة $menu (أو "$altMenu").',
            'اختر "Muslim Launcher 2".',
            'قم بتفعيل "استخدام Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Soek vir $menu (of "$altMenu").',
            'Kies "Muslim Launcher 2".',
            'Skakel "Gebruik Muslim Launcher 2" AAN.',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Tafuta menyu ya $menu (au "$altMenu").',
            'Chagua "Muslim Launcher 2".',
            'Washa "Tumia Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Look for $menu (or "$altMenu").',
            'Select "Muslim Launcher 2".',
            'Turn ON "Use Muslim Launcher 2".',
          ];
      }
    }

    // ── B. SAMSUNG (ONE UI) ──
    else if (m.contains('samsung')) {
      final menu = formatMenuName(
        idName: 'Aplikasi Terinstal',
        enName: 'Installed Apps',
        msName: 'Aplikasi Dipasang',
        arName: 'التطبيقات المثبتة',
        appLang: appLang,
      );
      final altMenu = systemLang == 'id'
          ? 'Layanan Terinstal'
          : (systemLang == 'ar' ? 'الخدمات المثبتة' : 'Installed Services');

      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan" di bawah.',
            'Cari menu $menu (atau "$altMenu").',
            'Pilih "Muslim Launcher 2".',
            'Geser tombol ke posisi AKTIF.',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan" di bawah.',
            'Cari menu $menu (atau "$altMenu").',
            'Pilih "Muslim Launcher 2".',
            'Togol suis ke HIDUP.',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'ابحث عن قائمة $menu (أو "$altMenu").',
            'اختر "Muslim Launcher 2".',
            'قم بتفعيل المفتاح.',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Soek vir $menu (of "$altMenu").',
            'Kies "Muslim Launcher 2".',
            'Skakel die skakelaar na AAN.',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Tafuta menyu ya $menu (au "$altMenu").',
            'Chagua "Muslim Launcher 2".',
            'Washa swichi iwe WAZI.',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Look for $menu (or "$altMenu").',
            'Select "Muslim Launcher 2".',
            'Turn the switch to ON.',
          ];
      }
    }

    // ── C. OPPO / REALME / ONEPLUS / VIVO / IQOO ──
    else if (m.contains('oppo') ||
        m.contains('oneplus') ||
        m.contains('realme') ||
        m.contains('vivo') ||
        m.contains('iqoo')) {
      final menu = formatMenuName(
        idName: 'Layanan Terinstal / Aksesibilitas',
        enName: 'Installed Services / Accessibility',
        msName: 'Perkhidmatan Dipasang / Kebolehcapaian',
        arName: 'الخدمات المثبتة / إمكانية الوصول',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan" di bawah.',
            'Cari "Muslim Launcher 2" di daftar $menu.',
            'Aktifkan sakelar dan izinkan akses.',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan" di bawah.',
            'Cari "Muslim Launcher 2" di senarai $menu.',
            'Aktifkan suis dan berikan kebenaran.',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'ابحث عن "Muslim Launcher 2" تحت $menu.',
            'قم بتفعيل المفتاح ومنح الأذونات.',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Vind "Muslim Launcher 2" onder $menu.',
            'Skakel die skakelaar aan en verleen toestemming.',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Pata "Muslim Launcher 2" chini ya $menu.',
            'Washa swichi na uruhusu ufikiaji.',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Find "Muslim Launcher 2" under $menu.',
            'Turn ON the switch and grant permissions.',
          ];
      }
    }

    // ── D. INFINIX / TECNO / ITEL ──
    else if (m.contains('infinix') ||
        m.contains('tecno') ||
        m.contains('itel') ||
        m.contains('transsion')) {
      final menu = formatMenuName(
        idName: 'Aplikasi yang Didownload',
        enName: 'Downloaded Apps',
        msName: 'Aplikasi Dimuat Turun',
        arName: 'التطبيقات التي تم تنزيلها',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan" di bawah.',
            'Cari menu $menu (atau "Layanan Terinstal").',
            'Pilih "Muslim Launcher 2" dan aktifkan izin.',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan" di bawah.',
            'Cari menu $menu (atau "Perkhidmatan Dipasang").',
            'Pilih "Muslim Launcher 2" dan aktifkan kebenaran.',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'ابحث عن $menu (أو "الخدمات المثبتة").',
            'اختر "Muslim Launcher 2" وقم بتفعيل الإذن.',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Soek vir $menu (of "Geïnstalleerde Dienste").',
            'Kies "Muslim Launcher 2" en aktiveer toestemming.',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Tafuta $menu (au "Huduma Zilizosakinishwa").',
            'Chagua "Muslim Launcher 2" na uwashe ruhusa.',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Look for $menu (or "Installed Services").',
            'Select "Muslim Launcher 2" and enable permission.',
          ];
      }
    }

    // ── E. HUAWEI / HONOR ──
    else if (m.contains('huawei') || m.contains('honor')) {
      final menu = formatMenuName(
        idName: 'Layanan Terinstal',
        enName: 'Installed Services',
        msName: 'Perkhidmatan Dipasang',
        arName: 'الخدمات المثبتة',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan" di bawah.',
            'Masuk ke Aksesibilitas -> $menu.',
            'Aktifkan "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan" di bawah.',
            'Pergi ke Kebolehcapaian -> $menu.',
            'Aktifkan "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'انتقل إلى إمكانية الوصول -> $menu.',
            'قم بتفعيل "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Gaan na Toeganklikheid -> $menu.',
            'Aktiveer "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Nenda kwenye Ufikiaji -> $menu.',
            'Washa "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Go to Accessibility -> $menu.',
            'Enable "Muslim Launcher 2".',
          ];
      }
    }

    // ── F. GENERIC / LAINNYA ──
    else {
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan" di bawah.',
            'Cari "Muslim Launcher 2" di daftar.',
            'Pilih aplikasinya dan aktifkan sakelar.',
            'Klik "OK" atau "Izinkan" jika ada peringatan.',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan" di bawah.',
            'Cari "Muslim Launcher 2" dalam senarai.',
            'Pilih aplikasi dan aktifkan suis.',
            'Ketik "OK" atau "Benarkan" jika diminta.',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'ابحث عن "Muslim Launcher 2" في القائمة.',
            'اختر التطبيق وقم بتفعيل المفتاح.',
            'وافق على تحذيرات النظام.',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Vind "Muslim Launcher 2" in die lys.',
            'Kies dit en skakel die wisselaar AAN.',
            'Bevestig enige stelselwaarskuwings.',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Pata "Muslim Launcher 2" kwenye orodha.',
            'Chagua na uwashe swichi.',
            'Thibitisha maonyo yoyote ya mfumo.',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Find "Muslim Launcher 2" in the list.',
            'Select it and turn ON the toggle.',
            'Confirm any system warnings.',
          ];
      }
    }
  }

  // ── 2. DEFAULT HOME / LAUNCHER INSTRUCTIONS ─────────────────────────────────

  static List<String> getHomeInstructions(
    String manufacturer,
    String appLang,
  ) {
    final m = manufacturer.toLowerCase();

    // ── A. XIAOMI / POCO / REDMI (MIUI / HYPEROS) ──
    if (m.contains('xiaomi') ||
        m.contains('poco') ||
        m.contains('redmi') ||
        m.contains('blackshark')) {
      final menu = formatMenuName(
        idName: 'Peluncur Utama / Beranda',
        enName: 'Default launcher / Home screen',
        msName: 'Pelancar Lalai / Skrin Utama',
        arName: 'المشغل الافتراضي / الشاشة الرئيسية',
        appLang: appLang,
      );
      final alwaysBtn = formatMenuName(
        idName: 'Selalu',
        enName: 'Always',
        msName: 'Sentiasa',
        arName: 'دائماً',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Pilih menu $menu.',
            'Pilih "Muslim Launcher 2".',
            'Konfirmasi dan pilih $alwaysBtn jika diminta sistem.',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Pilih menu $menu.',
            'Pilih "Muslim Launcher 2".',
            'Ketik $alwaysBtn jika diminta oleh sistem.',
          ];
        case 'ar':
          return [
            'اضغط على "فتح إعدادات الشاشة الرئيسية" أدناه.',
            'اختر قائمة $menu.',
            'اختر "Muslim Launcher 2".',
            'اضغط على $alwaysBtn إذا طلب منك النظام.',
          ];
        case 'af':
          return [
            'Tik op "Maak Tuisskerm-instellings Oop" hieronder.',
            'Kies $menu.',
            'Kies "Muslim Launcher 2".',
            'Tik $alwaysBtn as die stelsel vra.',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio ya Nyumbani" hapa chini.',
            'Chagua $menu.',
            'Chagua "Muslim Launcher 2".',
            'Gusa $alwaysBtn ukiombwa na mfumo.',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Select $menu.',
            'Choose "Muslim Launcher 2".',
            'Tap $alwaysBtn if prompted.',
          ];
      }
    }

    // ── B. SAMSUNG (ONE UI) ──
    else if (m.contains('samsung')) {
      final menu = formatMenuName(
        idName: 'Aplikasi Beranda',
        enName: 'Home app',
        msName: 'Aplikasi Utama',
        arName: 'تطبيق الشاشة الرئيسية',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Pilih menu $menu dari daftar.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Pilih menu $menu dalam senarai.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'اختر قائمة $menu من القائمة.',
            'اختر "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Kies $menu uit die lys.',
            'Kies "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Chagua $menu kutoka kwenye orodha.',
            'Chagua "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Select $menu from the list.',
            'Choose "Muslim Launcher 2".',
          ];
      }
    }

    // ── C. OPPO / REALME / ONEPLUS ──
    else if (m.contains('oppo') || m.contains('oneplus') || m.contains('realme')) {
      final defaultApp = formatMenuName(
        idName: 'Aplikasi Default',
        enName: 'Default Apps',
        msName: 'Aplikasi Lalai',
        arName: 'التطبيقات الافتراضية',
        appLang: appLang,
      );
      final homeApp = formatMenuName(
        idName: 'Aplikasi Beranda',
        enName: 'Home App',
        msName: 'Aplikasi Utama',
        arName: 'تطبيق الشاشة الرئيسية',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Masuk ke $defaultApp -> $homeApp.',
            'Setel ke "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Pergi ke $defaultApp -> $homeApp.',
            'Tetapkan ke "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'انتقل إلى $defaultApp -> $homeApp.',
            'اختر "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Gaan na $defaultApp -> $homeApp.',
            'Stel op "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Nenda kwenye $defaultApp -> $homeApp.',
            'Weka kuwa "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Go to $defaultApp -> $homeApp.',
            'Set to "Muslim Launcher 2".',
          ];
      }
    }

    // ── D. VIVO / IQOO ──
    else if (m.contains('vivo') || m.contains('iqoo')) {
      final menu = formatMenuName(
        idName: 'Pengaturan Aplikasi Default -> Layar Beranda',
        enName: 'Default App Settings -> Home app',
        msName: 'Tetapan Aplikasi Lalai -> Skrin Utama',
        arName: 'إعدادات التطبيقات الافتراضية -> الشاشة الرئيسية',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Pilih $menu.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Pilih $menu.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'اختر $menu.',
            'اختر "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Kies $menu.',
            'Kies "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Chagua $menu.',
            'Chagua "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Select $menu.',
            'Choose "Muslim Launcher 2".',
          ];
      }
    }

    // ── E. INFINIX / TECNO / ITEL ──
    else if (m.contains('infinix') ||
        m.contains('tecno') ||
        m.contains('itel') ||
        m.contains('transsion')) {
      final menu = formatMenuName(
        idName: 'Aplikasi Beranda / Desktop',
        enName: 'Home app / Desktop',
        msName: 'Aplikasi Utama / Desktop',
        arName: 'تطبيق الشاشة الرئيسية / سطح المكتب',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Pilih menu $menu.',
            'Ubah launcher default ke "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Pilih menu $menu.',
            'Tukar pelancar lalai ke "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'اختر قائمة $menu.',
            'قم بتغيير المشغل الافتراضي إلى "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Kies $menu.',
            'Verander na "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Chagua $menu.',
            'Badilisha kizindua kiwe "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Select $menu.',
            'Change default to "Muslim Launcher 2".',
          ];
      }
    }

    // ── F. HUAWEI / HONOR ──
    else if (m.contains('huawei') || m.contains('honor')) {
      final defaultApp = formatMenuName(
        idName: 'Aplikasi Default',
        enName: 'Default Apps',
        msName: 'Aplikasi Lalai',
        arName: 'التطبيقات الافتراضية',
        appLang: appLang,
      );
      final launcher = formatMenuName(
        idName: 'Peluncur',
        enName: 'Launcher',
        msName: 'Pelancar',
        arName: 'المشغل',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Masuk ke $defaultApp -> $launcher.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Pergi ke $defaultApp -> $launcher.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'انتقل إلى $defaultApp -> $launcher.',
            'اختر "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Gaan na $defaultApp -> $launcher.',
            'Kies "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Nenda kwenye $defaultApp -> $launcher.',
            'Chagua "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Go to $defaultApp -> $launcher.',
            'Select "Muslim Launcher 2".',
          ];
      }
    }

    // ── G. GENERIC / LAINNYA ──
    else {
      final menu = formatMenuName(
        idName: 'Aplikasi Beranda / Default',
        enName: 'Home app / Default apps',
        msName: 'Aplikasi Utama / Lalai',
        arName: 'تطبيق الشاشة الرئيسية / الافتراضي',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Buka Pengaturan Beranda" di bawah.',
            'Cari menu $menu.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ms':
          return [
            'Ketik "Buka Tetapan Utama" di bawah.',
            'Cari menu $menu.',
            'Pilih "Muslim Launcher 2".',
          ];
        case 'ar':
          return [
            'اضغط على "فتح الإعدادات" أدناه.',
            'ابحث عن $menu.',
            'اختر "Muslim Launcher 2".',
          ];
        case 'af':
          return [
            'Tik op "Maak Instellings Oop" hieronder.',
            'Vind $menu.',
            'Kies "Muslim Launcher 2".',
          ];
        case 'sw':
          return [
            'Gusa "Fungua Mipangilio" hapa chini.',
            'Pata $menu.',
            'Chagua "Muslim Launcher 2".',
          ];
        default:
          return [
            'Click "Open Settings" below.',
            'Find $menu.',
            'Select "Muslim Launcher 2".',
          ];
      }
    }
  }

  // ── 3. AUTOSTART & BATTERY INSTRUCTIONS ─────────────────────────────────────

  static List<String> getAutostartInstructions(
    String manufacturer,
    String appLang,
  ) {
    final m = manufacturer.toLowerCase();

    // ── A. XIAOMI / POCO / REDMI (MIUI / HYPEROS) ──
    if (m.contains('xiaomi') ||
        m.contains('poco') ||
        m.contains('redmi') ||
        m.contains('blackshark')) {
      final autostart = formatMenuName(
        idName: 'Mulai Otomatis',
        enName: 'Autostart',
        msName: 'Mula Automatik',
        arName: 'التشغيل التلقائي',
        appLang: appLang,
      );
      final noRestrict = formatMenuName(
        idName: 'Tanpa Pembatasan',
        enName: 'No restrictions',
        msName: 'Tiada Sekatan',
        arName: 'بلا قيود',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Cari "Muslim Launcher 2" & aktifkan $autostart.',
            'Ketuk aplikasinya -> Penghemat Baterai -> pilih $noRestrict.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Cari "Muslim Launcher 2" & aktifkan $autostart.',
            'Ketik aplikasi -> Penjimat Bateri -> pilih $noRestrict.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'ابحث عن "Muslim Launcher 2" وقم بتفعيل $autostart.',
            'اضغط على التطبيق -> موفر البطارية -> اختر $noRestrict.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Vind "Muslim Launcher 2" & aktiveer $autostart.',
            'Tik die toepassing -> Batterybespaarder -> kies $noRestrict.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Pata "Muslim Launcher 2" na uwashe $autostart.',
            'Gusa programu -> Kiokoa Betri -> chagua $noRestrict.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Find "Muslim Launcher 2" & enable $autostart.',
            'Tap the app -> Battery Saver -> select $noRestrict.',
          ];
      }
    }

    // ── B. SAMSUNG (ONE UI) ──
    else if (m.contains('samsung')) {
      final neverSleep = formatMenuName(
        idName: 'Aplikasi yang tidak pernah tidur',
        enName: 'Never sleeping apps',
        msName: 'Aplikasi yang tidak pernah tidur',
        arName: 'التطبيقات التي لا تنام أبداً',
        appLang: appLang,
      );
      final bgLimits = formatMenuName(
        idName: 'Batas penggunaan latar belakang',
        enName: 'Background usage limits',
        msName: 'Had penggunaan latar belakang',
        arName: 'حدود استخدام الخلفية',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Masuk ke Baterai -> $bgLimits.',
            'Tambahkan Muslim Launcher 2 ke $neverSleep.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Pergi ke Bateri -> $bgLimits.',
            'Tambah Muslim Launcher 2 ke $neverSleep.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'انتقل إلى البطارية -> $bgLimits.',
            'أضف Muslim Launcher 2 إلى $neverSleep.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Gaan na Battery -> $bgLimits.',
            'Voeg Muslim Launcher 2 by $neverSleep.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Nenda kwenye Betri -> $bgLimits.',
            'Ongeza Muslim Launcher 2 kwenye $neverSleep.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Go to Battery -> $bgLimits.',
            'Add Muslim Launcher 2 to $neverSleep.',
          ];
      }
    }

    // ── C. OPPO / REALME / ONEPLUS ──
    else if (m.contains('oppo') || m.contains('oneplus') || m.contains('realme')) {
      final autoLaunch = formatMenuName(
        idName: 'Izinkan Mulai Otomatis',
        enName: 'Allow auto-launch',
        msName: 'Benarkan mula automatik',
        arName: 'السماح بالتشغيل التلقائي',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Cari "Muslim Launcher 2" & aktifkan $autoLaunch.',
            'Izinkan aktivitas latar belakang.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Cari "Muslim Launcher 2" & aktifkan $autoLaunch.',
            'Benarkan aktiviti latar belakang.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'ابحث عن "Muslim Launcher 2" وقم بتفعيل $autoLaunch.',
            'اسمح بالنشاط في الخلفية.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Vind "Muslim Launcher 2" & aktiveer $autoLaunch.',
            'Laat agtergrondaktiwiteit toe.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Pata "Muslim Launcher 2" na uwashe $autoLaunch.',
            'Ruhusu ufanyaji kazi nyuma ya pazia.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Find "Muslim Launcher 2" & enable $autoLaunch.',
            'Allow background activity.',
          ];
      }
    }

    // ── D. VIVO / IQOO ──
    else if (m.contains('vivo') || m.contains('iqoo')) {
      final autostart = formatMenuName(
        idName: 'Mulai Otomatis',
        enName: 'Autostart',
        msName: 'Mula Automatik',
        arName: 'التشغيل التلقائي',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Cari "Muslim Launcher 2" & aktifkan $autostart.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Cari "Muslim Launcher 2" & aktifkan $autostart.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'ابحث عن "Muslim Launcher 2" وقم بتفعيل $autostart.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Vind "Muslim Launcher 2" & aktiveer $autostart.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Pata "Muslim Launcher 2" na uwashe $autostart.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Find "Muslim Launcher 2" & enable $autostart.',
          ];
      }
    }

    // ── E. INFINIX / TECNO / ITEL ──
    else if (m.contains('infinix') ||
        m.contains('tecno') ||
        m.contains('itel') ||
        m.contains('transsion')) {
      final phoneMgr = formatMenuName(
        idName: 'Pengelola Telepon',
        enName: 'Phone Manager',
        msName: 'Pengurus Telefon',
        arName: 'مدير الهاتف',
        appLang: appLang,
      );
      final autoStartMgr = formatMenuName(
        idName: 'Manajemen Mulai Otomatis',
        enName: 'Auto-start management',
        msName: 'Pengurusan Mula Automatik',
        arName: 'إدارة التشغيل التلقائي',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Buka $phoneMgr -> $autoStartMgr.',
            'Aktifkan sakelar mulai otomatis Muslim Launcher 2.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Buka $phoneMgr -> $autoStartMgr.',
            'Aktifkan suis mula automatik Muslim Launcher 2.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'افتح $phoneMgr -> $autoStartMgr.',
            'قم بتفعيل مفتاح التشغيل التلقائي لـ Muslim Launcher 2.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Maak $phoneMgr -> $autoStartMgr oop.',
            'Aktiveer Muslim Launcher 2 outobegin.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Fungua $phoneMgr -> $autoStartMgr.',
            'Washa swichi ya kuanza kiotomatiki kwa Muslim Launcher 2.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Open $phoneMgr -> $autoStartMgr.',
            'Enable Muslim Launcher 2 auto-start switch.',
          ];
      }
    }

    // ── F. HUAWEI / HONOR ──
    else if (m.contains('huawei') || m.contains('honor')) {
      final autoLaunch = formatMenuName(
        idName: 'Peluncuran Otomatis',
        enName: 'Auto-launch',
        msName: 'Pelancaran Automatik',
        arName: 'التشغيل التلقائي',
        appLang: appLang,
      );
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Masuk ke Peluncuran Aplikasi -> Matikan Otomatis untuk "Muslim Launcher 2".',
            'Aktifkan $autoLaunch & Jalankan di latar belakang.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Pergi ke Pelancaran Aplikasi -> Matikan Automatik untuk "Muslim Launcher 2".',
            'Aktifkan $autoLaunch & Jalankan di latar belakang.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'انتقل إلى تشغيل التطبيقات -> أوقف التلقائي لـ "Muslim Launcher 2".',
            'قم بتفعيل $autoLaunch والتشغيل في الخلفية.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Gaan na Toepassing Begin -> Skakel Outomaties af vir "Muslim Launcher 2".',
            'Aktiveer $autoLaunch & Laat agtergrondaktiwiteit toe.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Nenda kwenye Uzinduzi wa Programu -> Zima Kiotomatiki kwa "Muslim Launcher 2".',
            'Washa $autoLaunch & Ruhusu kufanya kazi nyuma ya pazia.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Go to App Launch -> Turn off Automatic for "Muslim Launcher 2".',
            'Enable $autoLaunch & Run in background.',
          ];
      }
    }

    // ── G. GENERIC / LAINNYA ──
    else {
      switch (appLang) {
        case 'id':
          return [
            'Ketuk "Atur Autostart & Baterai" di bawah.',
            'Cari "Muslim Launcher 2" di pengaturan baterai.',
            'Matikan pembatasan baterai / izinkan berjalan di latar belakang.',
          ];
        case 'ms':
          return [
            'Ketik "Konfigurasi Mula Automatik & Bateri" di bawah.',
            'Cari "Muslim Launcher 2" dalam tetapan bateri.',
            'Nyahaktifkan sekatan bateri / benarkan aktiviti latar belakang.',
          ];
        case 'ar':
          return [
            'اضغط على "إعداد التشغيل التلقائي والبطارية" أدناه.',
            'ابحث عن "Muslim Launcher 2" في إعدادات البطارية.',
            'عطّل قيود البطارية / اسمح بالنشاط في الخلفية.',
          ];
        case 'af':
          return [
            'Tik op "Stel Outobegin & Battery op" hieronder.',
            'Vind "Muslim Launcher 2" in battery-instellings.',
            'Deaktiveer batterybeperkings / laat agtergrondaktiwiteit toe.',
          ];
        case 'sw':
          return [
            'Gusa "Weka Kuanza Kiotomatiki & Betri" hapa chini.',
            'Pata "Muslim Launcher 2" kwenye mipangilio ya betri.',
            'Zima vizuizi vya betri / ruhusu ufanyaji kazi nyuma ya pazia.',
          ];
        default:
          return [
            'Tap "Configure Autostart & Battery" below.',
            'Find "Muslim Launcher 2" in battery settings.',
            'Disable battery optimizations / allow background activity.',
          ];
      }
    }
  }

  // ── 4. ACCESSIBILITY TIP ───────────────────────────────────────────────────

  static String getAccessibilityTip(String appLang) {
    switch (appLang) {
      case 'id':
        return systemLang == 'id'
            ? 'Tips: Biasanya ada di bagian "Aplikasi yang didownload", "Aplikasi Terinstal", atau "Layanan".'
            : 'Tips: Cari bagian "Downloaded Apps", "Installed Apps", atau "Services" di pengaturan HP Anda.';
      case 'ms':
        return 'Tips: Cari bahagian "Aplikasi Dimuat Turun", "Aplikasi Dipasang", atau "Layanan" dalam tetapan peranti anda.';
      case 'ar':
        return 'نصيحة: ابحث عن قسم "التطبيقات التي تم تنزيلها" أو "التطبيقات المثبتة" أو "الخدمات".';
      case 'af':
        return 'Wenk: Soek vir die afdeling "Downloaded Apps", "Installed Apps" of "Services".';
      case 'sw':
        return 'Dokezo: Tafuta sehemu ya "Downloaded Apps", "Installed Apps", au "Services".';
      default:
        return systemLang == 'id'
            ? 'Tip: Look for the "Aplikasi yang didownload", "Aplikasi Terinstal", or "Layanan" section.'
            : 'Tip: Look for the "Downloaded Apps", "Installed Apps", or "Services" section.';
    }
  }
}
