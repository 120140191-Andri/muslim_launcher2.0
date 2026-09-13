import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../screens/quran/surah_detail_screen.dart';
import 'page_transitions.dart';
import 'translations.dart';

enum SunnahMissionType {
  fridayKahf,
  nightMulk,
  nightAyatKursi,
  nightBaqarahEnd,
  fajrReading,
}

class SunnahMission {
  final String id;
  final SunnahMissionType type;
  final int targetSurahNumber;
  final int? targetAyahStart;
  final int? targetAyahEnd;
  final int pointsReward;
  final IconData icon;
  final Color primaryColor;
  final Color gradientStart;
  final Color gradientEnd;

  const SunnahMission({
    required this.id,
    required this.type,
    required this.targetSurahNumber,
    this.targetAyahStart,
    this.targetAyahEnd,
    required this.pointsReward,
    required this.icon,
    required this.primaryColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  String getTitle(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return 'Friday Light: Surah Al-Kahf';
          case 'ar':
            return 'نور الجمعة: سورة الكهف';
          case 'af':
            return 'Vrydaglig: Soera Al-Kahf';
          case 'sw':
            return 'Nuru ya Ijumaa: Sura Al-Kahf';
          case 'ms':
          case 'id':
          default:
            return 'Cahaya Jum\'at: Surah Al-Kahf';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'en':
            return 'Night Protector: Surah Al-Mulk';
          case 'ar':
            return 'المنجية من عذاب القبر: سورة الملك';
          case 'af':
            return 'Nagbeskermer: Soera Al-Mulk';
          case 'sw':
            return 'Mlinzi wa Usiku: Sura Al-Mulk';
          case 'ms':
          case 'id':
          default:
            return 'Pelindung Kubur: Surah Al-Mulk';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'en':
            return 'Sleep Guardian: Ayat al-Kursi';
          case 'ar':
            return 'حرز النوم: آية الكرسي';
          case 'af':
            return 'Slaapwagter: Ayat al-Kursi';
          case 'sw':
            return 'Mlinzi wa Usingizi: Ayat al-Kursi';
          case 'ms':
          case 'id':
          default:
            return 'Penjaga Tidur: Ayat Kursi';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return 'Night Sufficient: Last 2 Verses of Al-Baqarah';
          case 'ar':
            return 'خواتيم سورة البقرة';
          case 'af':
            return 'Laaste 2 Verse van Al-Baqarah';
          case 'sw':
            return 'Aya 2 za Mwisho za Al-Baqarah';
          case 'ms':
          case 'id':
          default:
            return 'Pencukup Malam: 2 Ayat Terakhir Al-Baqarah';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return 'Witnessed Dawn: Qur\'an of Fajr';
          case 'ar':
            return 'قرآن الفجر المشهود';
          case 'af':
            return 'Getuie van die Dagbreek: Soebah-lees';
          case 'sw':
            return 'Qur\'ani ya Alfajiri';
          case 'ms':
          case 'id':
          default:
            return 'Al-Qur\'anul Fajri: Tilawah Subuh';
        }
    }
  }

  String getSubtitle(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return '110 Ayahs • Light between two Fridays';
          case 'ar':
            return '١١٠ آيات • نور ما بين الجمعتين';
          case 'af':
            return '110 Verse • Lig tussen twee Vrydae';
          case 'sw':
            return 'Aya 110 • Nuru baina ya Ijumaa mbili';
          case 'ms':
            return '110 Ayat • Cahaya antara dua Jumaat';
          case 'id':
          default:
            return '110 Ayat • Cahaya antara dua Jum\'at';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'en':
            return '30 Ayahs • Savior from punishment of the grave';
          case 'ar':
            return '٣٠ آية • المانعة من عذاب القبر';
          case 'af':
            return '30 Verse • Redder van die grafstraf';
          case 'sw':
            return 'Aya 30 • Mwokozi kutokana na adhabu ya kaburi';
          case 'ms':
            return '30 Ayat • Penyelamat daripada seksa kubur';
          case 'id':
          default:
            return '30 Ayat • Penyelamat dari siksa kubur';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'en':
            return 'Surah Al-Baqarah: Ayah 255 • Protected till dawn';
          case 'ar':
            return 'سورة البقرة: آية ٢٥٥ • حرز وحفظ حتى الصباح';
          case 'af':
            return 'Soera Al-Baqarah: Vers 255 • Bewaak tot dagbreek';
          case 'sw':
            return 'Sura Al-Baqarah: Aya 255 • Ulinzi hadi alfajiri';
          case 'ms':
            return 'Al-Baqarah: Ayat 255 • Kawalan malaikat hingga fajar';
          case 'id':
          default:
            return 'Al-Baqarah: Ayat 255 • Penjagaan malaikat hingga fajar';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return 'Ayahs 285-286 • Sufficient against every evil';
          case 'ar':
            return 'آيتان ٢٨٥-٢٨٦ • كفتاه من كل سوء';
          case 'af':
            return 'Verse 285-286 • Voldoende teen alle kwaad';
          case 'sw':
            return 'Aya 285-286 • Zatosheleza dhidi ya kila shari';
          case 'ms':
            return 'Ayat 285-286 • Mencukupi daripada segala keburukan';
          case 'id':
          default:
            return 'Ayat 285-286 • Mencukupi dari segala keburukan';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return 'Recite at dawn • Witnessed by gathering angels';
          case 'ar':
            return 'تلاوة الفجر • تشهدها ملائكة الليل والنهار';
          case 'af':
            return 'Lees teen dagbreek • Aanskou deur engele';
          case 'sw':
            return 'Usomaji alfajiri • Hudhuriwa na malaika';
          case 'ms':
            return 'Tilawah pada waktu fajar • Disaksikan para malaikat';
          case 'id':
          default:
            return 'Tilawah di waktu fajar • Disaksikan para malaikat';
        }
    }
  }

  String getTimeBadge(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return 'Every Friday';
          case 'ar':
            return 'يوم وليلة الجمعة';
          case 'af':
            return 'Elke Vrydag';
          case 'sw':
            return 'Kila Ijumaa';
          case 'ms':
            return 'Hari & Malam Jumaat';
          case 'id':
          default:
            return 'Hari & Malam Jum\'at';
        }
      case 'almulk_malam':
      case 'ayat_kursi_malam':
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return 'Tonight (19:00 - 23:59)';
          case 'ar':
            return 'الليلة (١٩:٠٠ - ٢٣:٥٩)';
          case 'af':
            return 'Vanaand (19:00 - 23:59)';
          case 'sw':
            return 'Usiku Huu (19:00 - 23:59)';
          case 'ms':
          case 'id':
          default:
            return 'Malam Ini (19:00 - 23:59)';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return 'Dawn (04:00 - 06:30)';
          case 'ar':
            return 'وقت الفجر (٠٤:٠٠ - ٠٦:٣٠)';
          case 'af':
            return 'Dagbreek (04:00 - 06:30)';
          case 'sw':
            return 'Wakati wa Alfajiri (04:00 - 06:30)';
          case 'ms':
          case 'id':
          default:
            return 'Waktu Subuh (04:00 - 06:30)';
        }
    }
  }

  String getAyahRangeText(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return 'Ayah 1 - 110';
          case 'ar':
            return 'الآيات ١ - ١١٠';
          case 'af':
            return 'Vers 1 - 110';
          case 'sw':
            return 'Aya 1 - 110';
          case 'ms':
          case 'id':
          default:
            return 'Ayat 1 - 110';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'en':
            return 'Ayah 1 - 30';
          case 'ar':
            return 'الآيات ١ - ٣٠';
          case 'af':
            return 'Vers 1 - 30';
          case 'sw':
            return 'Aya 1 - 30';
          case 'ms':
          case 'id':
          default:
            return 'Ayat 1 - 30';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'en':
            return 'Ayah 255';
          case 'ar':
            return 'الآية ٢٥٥';
          case 'af':
            return 'Vers 255';
          case 'sw':
            return 'Aya 255';
          case 'ms':
          case 'id':
          default:
            return 'Ayat 255';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return 'Ayah 285 - 286';
          case 'ar':
            return 'الآيات ٢٨٥ - ٢٨٦';
          case 'af':
            return 'Vers 285 - 286';
          case 'sw':
            return 'Aya 285 - 286';
          case 'ms':
          case 'id':
          default:
            return 'Ayat 285 - 286';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return 'Min. 3 Ayahs';
          case 'ar':
            return '٣ آيات فأكثر';
          case 'af':
            return 'Min. 3 Verse';
          case 'sw':
            return 'Aya 3 au zaidi';
          case 'ms':
          case 'id':
          default:
            return 'Min. 3 Ayat';
        }
    }
  }

  String getPillLabel(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'ar':
            return 'الكهف';
          default:
            return 'Al-Kahf';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'ar':
            return 'الملك';
          default:
            return 'Al-Mulk';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'ar':
            return 'آية الكرسي';
          case 'en':
          case 'af':
          case 'sw':
            return 'Ayat al-Kursi';
          case 'ms':
          case 'id':
          default:
            return 'Ayat Kursi';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return '2 Verses Baqarah';
          case 'ar':
            return 'آيتا البقرة';
          case 'af':
            return '2 Verse Baqarah';
          case 'sw':
            return 'Aya 2 Baqarah';
          case 'ms':
          case 'id':
          default:
            return '2 Ayat Baqarah';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'ar':
            return 'قرآن الفجر';
          case 'en':
            return 'Dawn Qur\'an';
          case 'af':
            return 'Dagbreek-Koran';
          case 'sw':
            return 'Qur\'an Alfajiri';
          case 'ms':
          case 'id':
          default:
            return 'Qur\'an Subuh';
        }
    }
  }

  String getBadgeTitle(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return 'Light of Friday (Al-Kahf)';
          case 'ar':
            return 'نور الجمعة (سورة الكهف)';
          case 'af':
            return 'Vrydaglig (Soera Al-Kahf)';
          case 'sw':
            return 'Nuru ya Ijumaa (Sura Al-Kahf)';
          case 'ms':
            return 'Cahaya Jumaat (Surah Al-Kahfi)';
          case 'id':
          default:
            return 'Cahaya Jum\'at (Surah Al-Kahf)';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'en':
            return 'Night Protector (Al-Mulk)';
          case 'ar':
            return 'المنجية من عذاب القبر (سورة الملك)';
          case 'af':
            return 'Nagbeskermer (Soera Al-Mulk)';
          case 'sw':
            return 'Mlinzi wa Usiku (Sura Al-Mulk)';
          case 'ms':
            return 'Pelindung Kubur (Surah Al-Mulk)';
          case 'id':
          default:
            return 'Pelindung Kubur (Surah Al-Mulk)';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'en':
            return 'Sleep Guardian (Ayat al-Kursi)';
          case 'ar':
            return 'حرز النوم (آية الكرسي)';
          case 'af':
            return 'Slaapwagter (Ayat al-Kursi)';
          case 'sw':
            return 'Mlinzi wa Usingizi (Ayat al-Kursi)';
          case 'ms':
            return 'Penjaga Tidur (Ayat Kursi)';
          case 'id':
          default:
            return 'Penjaga Tidur (Ayat Kursi)';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return 'Night Sufficiency (End of Baqarah)';
          case 'ar':
            return 'كفايتا الليل (خواتيم سورة البقرة)';
          case 'af':
            return 'Nag Genoegsaamheid (Laaste 2 Verse van Al-Baqarah)';
          case 'sw':
            return 'Yatoshelezayo Usiku (Aya 2 za Mwisho za Al-Baqarah)';
          case 'ms':
            return 'Pencukup Malam (2 Ayat Terakhir Al-Baqarah)';
          case 'id':
          default:
            return 'Pencukup Malam (2 Ayat Terakhir Al-Baqarah)';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return 'Dawn Witness (Al-Qur\'anul Fajri)';
          case 'ar':
            return 'قرآن الفجر المشهود';
          case 'af':
            return 'Getuie van Dagbreek (Al-Qur\'anul Fajri)';
          case 'sw':
            return 'Shahidi wa Alfajiri (Al-Qur\'anul Fajri)';
          case 'ms':
            return 'Saksi Subuh (Al-Qur\'anul Fajri)';
          case 'id':
          default:
            return 'Saksi Subuh (Al-Qur\'anul Fajri)';
        }
    }
  }

  String getBadgeDesc(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return 'Recite Surah Al-Kahf during the blessed Friday window.';
          case 'ar':
            return 'قراءة سورة الكهف في يوم وليلة الجمعة المباركة.';
          case 'af':
            return 'Lees Soera Al-Kahf tydens die geseënde Vrydag.';
          case 'sw':
            return 'Soma Sura Al-Kahf katika siku ya Ijumaa yenye baraka.';
          case 'ms':
            return 'Membaca Surah Al-Kahfi pada hari Jumaat.';
          case 'id':
          default:
            return 'Membaca Surah Al-Kahf pada hari Jum\'at.';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'en':
            return 'Recite Surah Al-Mulk at night before sleep.';
          case 'ar':
            return 'قراءة سورة الملك ليلاً قبل النوم.';
          case 'af':
            return 'Lees Soera Al-Mulk snags voor slaaptyd.';
          case 'sw':
            return 'Soma Sura Al-Mulk usiku kabla ya kulala.';
          case 'ms':
            return 'Membaca Surah Al-Mulk pada waktu malam sebelum tidur.';
          case 'id':
          default:
            return 'Membaca Surah Al-Mulk di malam hari sebelum tidur.';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'en':
            return 'Recite Ayat al-Kursi (Al-Baqarah 255) at night.';
          case 'ar':
            return 'قراءة آية الكرسي (البقرة: ٢٥٥) ليلاً عند النوم.';
          case 'af':
            return 'Lees Ayat al-Kursi (Al-Baqarah 255) snags.';
          case 'sw':
            return 'Soma Ayat al-Kursi (Al-Baqarah 255) usiku.';
          case 'ms':
            return 'Membaca Ayat Kursi (Al-Baqarah 255) pada waktu malam.';
          case 'id':
          default:
            return 'Membaca Ayat Kursi (Al-Baqarah 255) di malam hari.';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return 'Recite the last 2 verses of Al-Baqarah (285-286) at night.';
          case 'ar':
            return 'قراءة الآيتين الأخيرتين من سورة البقرة (٢٨٥-٢٨٦) في ليلة.';
          case 'af':
            return 'Lees die laaste 2 verse van Soera Al-Baqarah (285-286) snags.';
          case 'sw':
            return 'Soma aya 2 za mwisho za Sura Al-Baqarah (285-286) usiku.';
          case 'ms':
            return 'Membaca 2 ayat terakhir Surah Al-Baqarah (285-286) pada waktu malam.';
          case 'id':
          default:
            return 'Membaca 2 ayat terakhir Surah Al-Baqarah (285-286) di malam hari.';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return 'Recite the Qur\'an during Fajr / Dawn prayer window.';
          case 'ar':
            return 'تلاوة القرآن الكريم في وقت الفجر الذي تشهده الملائكة.';
          case 'af':
            return 'Lees die Koran tydens die dagbreek-tydvenster.';
          case 'sw':
            return 'Usomaji wa Qur\'ani wakati wa alfajiri unaoshuhudiwa na malaika.';
          case 'ms':
            return 'Tilawah Al-Qur\'an pada waktu Subuh/Fajar yang disaksikan para malaikat.';
          case 'id':
          default:
            return 'Tilawah Al-Qur\'an di waktu Subuh/Fajar yang disaksikan para malaikat.';
        }
    }
  }

  String getFadhilahHadith(String lang) {
    switch (id) {
      case 'alkahf_jumat':
        switch (lang) {
          case 'en':
            return '"Whoever recites Surah Al-Kahf on Friday will have light illuminating him between the two Fridays."\n\n(Narrated by An-Nasa\'i, Al-Bayhaqi, authenticated by Al-Albani)';
          case 'ar':
            return '«مَنْ قَرَأَ سُورَةَ الْكَهْفِ فِي يَوْمِ الْجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَيْنَ الْجُمُعَتَيْنِ»\n\n(رواه النسائي والبيهقي وصححه الألباني)';
          case 'af':
            return '"Wie Soera Al-Kahf op Vrydag lees, sal \'n lig hê wat hom tussen die twee Vrydae verlig."\n\n(Oorgelewer deur An-Nasa\'i en Al-Bayhaqi)';
          case 'sw':
            return '"Mwenye kusoma Sura Al-Kahf siku ya Ijumaa ataangaziwa nuru baina ya Ijumaa mbili."\n\n(Imepokelewa na An-Nasa\'i na Al-Bayhaqi)';
          case 'ms':
          case 'id':
          default:
            return '"Barangsiapa membaca Surah Al-Kahfi pada hari Jum\'at, maka akan dipancarkan baginya cahaya di antara dua Jum\'at."\n\n(HR. An-Nasa\'i, Al-Baihaqi; Shahih Al-Albani)';
        }
      case 'almulk_malam':
        switch (lang) {
          case 'en':
            return '"Indeed, there is a surah in the Qur\'an of thirty verses which intercedes for a person until he is forgiven: Tabarakallazi biyadihil mulk (Surah Al-Mulk)."\n\n(Narrated by At-Tirmidhi no. 2891, Abu Dawud no. 1400; Hasan)';
          case 'ar':
            return '«إِنَّ سُورَةً مِنَ الْقُرْآنِ ثَلَاثُونَ آيَةً شَفَعَتْ لِرَجُلٍ حَتَّى غُفِرَ لَهُ: تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ»\n\n(رواه الترمذي وحسنه وأبو داود)';
          case 'af':
            return '"Waarlik, daar is \'n soera van dertig verse wat vir \'n mens voorspraak doen totdat hy vergewe is: Soera Al-Mulk."\n\n(Oorgelewer deur At-Tirmidhi en Abu Dawud)';
          case 'sw':
            return '"Hakika kuna sura katika Qur\'ani yenye aya thelathini iliyomuombea mtu mpaka akasamehewa: Sura Al-Mulk."\n\n(Imepokelewa na At-Tirmidhi na Abu Dawud)';
          case 'ms':
          case 'id':
          default:
            return '"Sesungguhnya ada satu surah dalam Al-Qur\'an yang terdiri dari tiga puluh ayat, dapat memberi syafaat bagi pembacanya hingga diampuni dosanya, yaitu: Tabaarakalladzii biyadihil mulk (Surah Al-Mulk)."\n\n(HR. At-Tirmidzi no. 2891, Abu Daud no. 1400; Hasan)';
        }
      case 'ayat_kursi_malam':
        switch (lang) {
          case 'en':
            return '"When you go to bed, recite Ayat al-Kursi to the end. Allah will appoint a guardian over you, and no devil will come near you until morning."\n\n(Narrated by Al-Bukhari no. 2311)';
          case 'ar':
            return '«إِذَا أَوَيْتَ إِلَى فِرَاشِكَ فَاقْرَأْ آيَةَ الْكُرْسِيِّ... لَنْ يَزَالَ عَلَيْكَ مِنَ اللَّهِ حَافِظٌ، وَلَا يَقْرَبُكَ شَيْطَانٌ حَتَّى تُصْبِحَ»\n\n(رواه البخاري رقم ٢٣١١)';
          case 'af':
            return '"Wanneer jy gaan slaap, lees Ayat al-Kursi tot die einde. Allah sal \'n bewaker oor jou aanstel en geen duiwel sal jou nader tot die oggend nie."\n\n(Oorgelewer deur Al-Bukhari)';
          case 'sw':
            return '"Unapokwenda kulala, soma Ayat al-Kursi hadi mwisho. Allah ataweka mlinzi juu yako, na shetani hatakukaribia hadi asubuhi."\n\n(Imepokelewa na Al-Bukhari)';
          case 'ms':
          case 'id':
          default:
            return '"Jika engkau hendak pergi ke tempat tidurmu, bacalah Ayat Kursi hingga selesai. Niscaya Allah akan senantiasa mengutus penjaga bagimu dan setan tidak akan mendekatimu hingga waktu subuh."\n\n(HR. Al-Bukhari no. 2311)';
        }
      case 'albaqarah_akhir_malam':
        switch (lang) {
          case 'en':
            return '"Whoever recites the last two verses of Surah Al-Baqarah at night, they will suffice him (against every harm)."\n\n(Narrated by Al-Bukhari no. 5009, Muslim no. 808)';
          case 'ar':
            return '«مَنْ قَرَأَ بِالْآيَتَيْنِ مِنْ آخِرِ سُورَةِ الْبَقَرَةِ فِي لَيْلَةٍ كَفَتَاهُ»\n\n(رواه البخاري رقم ٥٠٠٩ ومسلم رقم ٨٠٨)';
          case 'af':
            return '"Wie die laaste twee verse van Soera Al-Baqarah snags lees, sal dit vir hom voldoende wees."\n\n(Oorgelewer deur Al-Bukhari en Muslim)';
          case 'sw':
            return '"Mwenye kusoma aya mbili za mwisho za Sura Al-Baqarah usiku, zitamtosheleza na kila shari."\n\n(Imepokelewa na Al-Bukhari na Muslim)';
          case 'ms':
          case 'id':
          default:
            return '"Barangsiapa membaca dua ayat terakhir dari surah Al-Baqarah pada suatu malam, maka kedua ayat itu telah mencukupinya (dari segala marabahaya dan keburukan)."\n\n(HR. Al-Bukhari no. 5009, Muslim no. 808)';
        }
      case 'quran_fajar':
      default:
        switch (lang) {
          case 'en':
            return '"And recite the Qur\'an at dawn. Indeed, the recitation at dawn is witnessed (by the angels of the night and the day)."\n\n(Surah Al-Isra: 78; Sahih Al-Bukhari no. 648)';
          case 'ar':
            return '﴿وَقُرْآنَ الْفَجْرِ إِنَّ قُرْآنَ الْفَجْرِ كَانَ مَشْهُودًا﴾\n\n«تَجْتَمِعُ مَلَائِكَةُ اللَّيْلِ وَمَلَائِكَةُ النَّهَارِ فِي صَلَاةِ الْفَجْرِ»\n(سورة الإسراء: ٧٨؛ رواه البخاري رقم ٦٤٨ ومسلم رقم ٦٤٩)';
          case 'af':
            return '"En lees die Koran teen dagbreek. Waarlik, die resitasie teen dagbreek word aanskou."\n\n(Soera Al-Isra: 78; Sahih Al-Bukhari)';
          case 'sw':
            return '"Na soma Qur\'ani wakati wa alfajiri. Hakika usomaji wa alfajiri unashuhudiwa na malaika."\n\n(Sura Al-Isra: 78; Sahih Al-Bukhari)';
          case 'ms':
          case 'id':
          default:
            return '"Dan dirikanlah shalat Subuh. Sesungguhnya bacaan Al-Qur\'an di waktu fajar itu disaksikan (oleh para malaikat malam dan malaikat siang berkumpul bersama)."\n\n(QS. Al-Isra: 78; HR. Al-Bukhari no. 648, Muslim no. 649)';
        }
    }
  }
}

class SunnahMissionHelper {
  static const SunnahMission fridayKahf = SunnahMission(
    id: 'alkahf_jumat',
    type: SunnahMissionType.fridayKahf,
    targetSurahNumber: 18,
    targetAyahStart: 1,
    targetAyahEnd: 110,
    pointsReward: 150,
    icon: Icons.light_mode_rounded,
    primaryColor: Color(0xFF0D5C3A),
    gradientStart: Color(0xFF0F5E3B),
    gradientEnd: Color(0xFF06331E),
  );

  static const SunnahMission nightMulk = SunnahMission(
    id: 'almulk_malam',
    type: SunnahMissionType.nightMulk,
    targetSurahNumber: 67,
    targetAyahStart: 1,
    targetAyahEnd: 30,
    pointsReward: 60,
    icon: Icons.shield_moon_rounded,
    primaryColor: Color(0xFF1E1B4B),
    gradientStart: Color(0xFF2E1065),
    gradientEnd: Color(0xFF0F172A),
  );

  static const SunnahMission nightAyatKursi = SunnahMission(
    id: 'ayat_kursi_malam',
    type: SunnahMissionType.nightAyatKursi,
    targetSurahNumber: 2,
    targetAyahStart: 255,
    targetAyahEnd: 255,
    pointsReward: 15,
    icon: Icons.security_rounded,
    primaryColor: Color(0xFF1E293B),
    gradientStart: Color(0xFF0F766E),
    gradientEnd: Color(0xFF111827),
  );

  static const SunnahMission nightBaqarahEnd = SunnahMission(
    id: 'albaqarah_akhir_malam',
    type: SunnahMissionType.nightBaqarahEnd,
    targetSurahNumber: 2,
    targetAyahStart: 285,
    targetAyahEnd: 286,
    pointsReward: 20,
    icon: Icons.auto_stories_rounded,
    primaryColor: Color(0xFF1E293B),
    gradientStart: Color(0xFF065F46),
    gradientEnd: Color(0xFF0F172A),
  );

  static const SunnahMission fajrReading = SunnahMission(
    id: 'quran_fajar',
    type: SunnahMissionType.fajrReading,
    targetSurahNumber: 1, // Any reading during dawn
    pointsReward: 35,
    icon: Icons.wb_twilight_rounded,
    primaryColor: Color(0xFFB45309),
    gradientStart: Color(0xFFD97706),
    gradientEnd: Color(0xFF78350F),
  );

  static const List<SunnahMission> allMissions = [
    fridayKahf,
    nightMulk,
    nightAyatKursi,
    nightBaqarahEnd,
    fajrReading,
  ];

  /// Optional simulated time for testing/debugging without having to wait for real hours/days
  static DateTime? debugSimulatedTime;

  /// Returns current simulated or real time
  static DateTime getEffectiveTime([DateTime? dateTime]) {
    return dateTime ?? debugSimulatedTime ?? DateTime.now();
  }

  /// Checks if time simulation is currently active
  static bool get isSimulationActive => debugSimulatedTime != null;

  /// Label of currently simulated state for UI badges
  static String getSimulationLabel(String lang) {
    if (debugSimulatedTime == null) return '';
    final now = debugSimulatedTime!;
    if (isFridayKahfActive(now)) {
      switch (lang) {
        case 'en':
          return 'Simulated: Friday';
        case 'ar':
          return 'محاكاة: الجمعة';
        case 'af':
          return 'Gesimuleer: Vrydag';
        case 'sw':
          return 'Iliyoigwa: Ijumaa';
        case 'ms':
        case 'id':
        default:
          return 'Simulasi: Jum\'at';
      }
    }
    if (isFajrActive(now)) {
      switch (lang) {
        case 'en':
          return 'Simulated: Fajr';
        case 'ar':
          return 'محاكاة: الفجر';
        case 'af':
          return 'Gesimuleer: Dagbreek';
        case 'sw':
          return 'Iliyoigwa: Alfajiri';
        case 'ms':
        case 'id':
        default:
          return 'Simulasi: Subuh';
      }
    }
    if (isNightActive(now)) {
      switch (lang) {
        case 'en':
          return 'Simulated: Night';
        case 'ar':
          return 'محاكاة: الليل';
        case 'af':
          return 'Gesimuleer: Nag';
        case 'sw':
          return 'Iliyoigwa: Usiku';
        case 'ms':
        case 'id':
        default:
          return 'Simulasi: Malam';
      }
    }
    switch (lang) {
      case 'en':
        return 'Simulated: Daytime';
      case 'ar':
        return 'محاكاة: النهار';
      case 'af':
        return 'Gesimuleer: Dag';
      case 'sw':
        return 'Iliyoigwa: Mchana';
      case 'ms':
      case 'id':
      default:
        return 'Simulasi: Siang';
    }
  }

  /// Checks if Friday Sunnah window is active (Thursday 18:00 to Friday 18:30)
  static bool isFridayKahfActive([DateTime? dateTime]) {
    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();
    if (now.weekday == DateTime.thursday && now.hour >= 18) {
      return true;
    }
    if (now.weekday == DateTime.friday) {
      if (now.hour < 18 || (now.hour == 18 && now.minute <= 30)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if night reading window is active (19:00 - 23:59, sebelum pergantian hari)
  static bool isNightActive([DateTime? dateTime]) {
    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();
    return now.hour >= 19;
  }

  /// Checks if Fajr/Subuh window is active (04:00 - 06:30)
  static bool isFajrActive([DateTime? dateTime]) {
    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();
    if (now.hour == 4 && now.minute >= 0) return true;
    if (now.hour == 5) return true;
    if (now.hour == 6 && now.minute <= 30) return true;
    return false;
  }

  /// Evaluates whether a specific mission is active at the given time
  static bool isMissionActiveNow(String missionId, [DateTime? dateTime]) {
    switch (missionId) {
      case 'alkahf_jumat':
        return isFridayKahfActive(dateTime);
      case 'almulk_malam':
      case 'ayat_kursi_malam':
      case 'albaqarah_akhir_malam':
        return isNightActive(dateTime);
      case 'quran_fajar':
        return isFajrActive(dateTime);
      default:
        return false;
    }
  }

  /// Returns currently active missions for the given time.
  /// On Friday window, Friday Kahf is placed first as weekly priority.
  static List<SunnahMission> getCurrentlyActiveMissions([DateTime? dateTime]) {
    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();
    final list = <SunnahMission>[];

    if (isFridayKahfActive(now)) {
      list.add(fridayKahf);
    }

    if (isFajrActive(now)) {
      list.add(fajrReading);
    } else if (isNightActive(now)) {
      list.add(nightMulk);
      list.add(nightAyatKursi);
      list.add(nightBaqarahEnd);
    }

    return list;
  }

  /// Checks whether a surah should visually appear alive/active (bypassing future dimmed state).
  /// - Ya-Sin (Surah 36): always active.
  /// - Al-Kahf (Surah 18): active during Friday window.
  /// - Al-Mulk (Surah 67): active during Night window.
  /// - Al-Baqarah (Surah 2): active during Night window (contains Ayat Kursi & 2 last verses).
  static bool isSurahAlwaysActive(int surahNumber, [DateTime? dateTime]) {
    // 1. Ya-Sin (Surah 36) is always active
    if (surahNumber == 36) return true;

    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();

    // 2. Surah Al-Kahf (Surah 18) active during Friday window
    if (surahNumber == 18 && isFridayKahfActive(now)) {
      return true;
    }

    // 3. Surah Al-Mulk (Surah 67) active during Night window
    if (surahNumber == 67 && isNightActive(now)) {
      return true;
    }

    // 4. Surah Al-Baqarah (Surah 2) active during Night window
    if (surahNumber == 2 && isNightActive(now)) {
      return true;
    }

    return false;
  }

  /// Checks whether a specific ayah in a surah should visually appear alive/active (bypassing future dimmed state).
  /// - Ya-Sin (Surah 36): all ayahs always active.
  /// - Al-Kahf (Surah 18): all ayahs active during Friday window.
  /// - Al-Mulk (Surah 67): all ayahs active during Night window.
  /// - Al-Baqarah (Surah 2): Ayat Kursi (255) and last 2 verses (285, 286) active during Night window.
  static bool isAyahAlwaysActive(
    int surahNumber,
    int ayahIndex, [
    DateTime? dateTime,
    int? explicitAyahNumber,
  ]) {
    // 1. Ya-Sin (Surah 36): all ayahs always active
    if (surahNumber == 36) return true;

    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();

    // 2. Surah Al-Kahf (Surah 18): all ayahs active during Friday window
    if (surahNumber == 18 && isFridayKahfActive(now)) {
      return true;
    }

    // 3. Surah Al-Mulk (Surah 67): all ayahs active during Night window
    if (surahNumber == 67 && isNightActive(now)) {
      return true;
    }

    // 4. Surah Al-Baqarah (Surah 2): Ayat Kursi (255) and last 2 verses (285, 286) active during Night window
    if (surahNumber == 2 && isNightActive(now)) {
      final ayahNum = explicitAyahNumber ?? (ayahIndex + 1);
      if (ayahNum == 255 || ayahNum == 285 || ayahNum == 286) {
        return true;
      }
    }

    return false;
  }

  /// Returns the active SunnahMission matching this surah and ayah (if any) at the given time.
  static SunnahMission? getActiveMissionForAyah(
    int surahNumber,
    int ayahNumber, [
    DateTime? dateTime,
  ]) {
    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();

    // 1. Surah Al-Kahf (18), ayahs 1..110 during Friday window
    if (surahNumber == 18 && isFridayKahfActive(now)) {
      if (ayahNumber >= 1 && ayahNumber <= 110) {
        return fridayKahf;
      }
    }

    // 2. Surah Al-Mulk (67), ayahs 1..30 during Night window
    if (surahNumber == 67 && isNightActive(now)) {
      if (ayahNumber >= 1 && ayahNumber <= 30) {
        return nightMulk;
      }
    }

    // 3. Ayat Kursi (Surah 2, Ayah 255) during Night window
    if (surahNumber == 2 && ayahNumber == 255 && isNightActive(now)) {
      return nightAyatKursi;
    }

    // 4. Last 2 Verses of Al-Baqarah (Surah 2, Ayahs 285-286) during Night window
    if (surahNumber == 2 && (ayahNumber == 285 || ayahNumber == 286) && isNightActive(now)) {
      return nightBaqarahEnd;
    }

    return null;
  }

  /// Generates a bulletproof anti-gaming date key to prevent farming.
  /// For night sessions (19:00 - 23:59), the key uses the date of that night.
  static String getAntiGamingClaimKey(String missionId, [DateTime? dateTime]) {
    final now = dateTime ?? debugSimulatedTime ?? DateTime.now();

    if (missionId == 'alkahf_jumat') {
      DateTime fridayDate;
      if (now.weekday == DateTime.thursday) {
        fridayDate = now.add(const Duration(days: 1));
      } else {
        fridayDate = now;
      }
      final dateStr =
          "${fridayDate.year}-${fridayDate.month.toString().padLeft(2, '0')}-${fridayDate.day.toString().padLeft(2, '0')}";
      return "sunnah_claim_alkahf_$dateStr";
    }

    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return "sunnah_claim_${missionId}_$dateStr";
  }

  /// Displays the interactive debug simulation modal so developer/user can instantly test.
  static void showDebugSimulationModal({
    required BuildContext context,
    required AppState appState,
    required VoidCallback onRefresh,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final activeSim = debugSimulatedTime;

            Widget buildOption({
              required IconData icon,
              required Color color,
              required String title,
              required String subtitle,
              required bool isSelected,
              required VoidCallback onTap,
            }) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: color)
                      : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    onTap();
                    setModalState(() {});
                    onRefresh();
                  },
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.build_circle_rounded,
                            color: Colors.teal, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Test & Simulasi Waktu Misi Sunnah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Text(
                      'Pilih skenario waktu di bawah ini untuk langsung melihat perubahan card di Home Screen tanpa menunggu jam/hari aslinya:',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 14),

                    // 1. Real time (Default)
                    buildOption(
                      icon: Icons.access_time_filled_rounded,
                      color: Colors.blueGrey,
                      title: 'Waktu Nyata Otomatis (Default)',
                      subtitle: 'Mengikuti jam dan hari perangkat saat ini',
                      isSelected: activeSim == null,
                      onTap: () {
                        debugSimulatedTime = null;
                        Navigator.pop(ctx);
                      },
                    ),

                    // 2. Friday Window (Al-Kahf)
                    buildOption(
                      icon: Icons.light_mode_rounded,
                      color: const Color(0xFF0F766E),
                      title: 'Simulasi Hari Jum\'at (Al-Kahf)',
                      subtitle: 'Menampilkan Misi Cahaya Jum\'at: Surah Al-Kahf (+75 Poin)',
                      isSelected: activeSim != null && isFridayKahfActive(activeSim),
                      onTap: () {
                        // Simulate Friday 10:00 AM (2026-09-11 is Friday)
                        debugSimulatedTime = DateTime(2026, 9, 11, 10, 0);
                        Navigator.pop(ctx);
                      },
                    ),

                    // 3. Night Window (Al-Mulk, Ayat Kursi, Baqarah)
                    buildOption(
                      icon: Icons.nightlight_round,
                      color: const Color(0xFF1E293B),
                      title: 'Simulasi Malam Hari (19:00 - 23:59)',
                      subtitle: 'Menampilkan Al-Mulk (+50), Ayat Kursi (+25), & 2 Ayat Baqarah (+25)',
                      isSelected: activeSim != null && isNightActive(activeSim),
                      onTap: () {
                        // Simulate Saturday Night 21:00 PM
                        debugSimulatedTime = DateTime(2026, 9, 12, 21, 0);
                        Navigator.pop(ctx);
                      },
                    ),

                    // 4. Fajr Window (Al-Qur'anul Fajri)
                    buildOption(
                      icon: Icons.wb_twilight_rounded,
                      color: const Color(0xFFB45309),
                      title: 'Simulasi Waktu Subuh (04:00 - 06:30)',
                      subtitle: 'Menampilkan Al-Qur\'anul Fajri: Tilawah Subuh (+40 Poin)',
                      isSelected: activeSim != null && isFajrActive(activeSim),
                      onTap: () {
                        // Simulate Dawn 05:00 AM
                        debugSimulatedTime = DateTime(2026, 9, 13, 5, 0);
                        Navigator.pop(ctx);
                      },
                    ),

                    // 5. Daytime Window (Card Biasa)
                    buildOption(
                      icon: Icons.wb_sunny_rounded,
                      color: Colors.amber.shade800,
                      title: 'Simulasi Siang Hari (Di Luar Misi)',
                      subtitle: 'Menampilkan Card Lanjutkan Bacaan 30 Juz biasa',
                      isSelected: activeSim != null &&
                          !isFridayKahfActive(activeSim) &&
                          !isNightActive(activeSim) &&
                          !isFajrActive(activeSim),
                      onTap: () {
                        // Simulate Wednesday 13:00 PM
                        debugSimulatedTime = DateTime(2026, 9, 16, 13, 0);
                        Navigator.pop(ctx);
                      },
                    ),

                    const Divider(height: 20),

                    // 6. Action buttons: Reset claims & Test Energy Beam
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text(
                              'Reset Klaim Hari Ini',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final keys = appState.prefs
                                  .getKeys()
                                  .where((k) => k.startsWith('sunnah_claim_'))
                                  .toList();
                              for (final k in keys) {
                                await appState.prefs.remove(k);
                              }
                              setModalState(() {});
                              onRefresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Semua status klaim misi hari ini berhasil di-reset!'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 16),
                            label: const Text(
                              'Test Sinar Energi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              appState.triggerSpiritualEnergy(
                                previousProgress: 0.25,
                                targetProgress: 0.65,
                                source: 'quran',
                                itemsCount: 6,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Displays the rich Fadhilah & Keutamaan BottomSheet Modal when tapping a Sunnah Mission.
  static void showMissionDetailModal({
    required BuildContext context,
    required SunnahMission mission,
    required AppState appState,
    required String lang,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = appState.isSunnahMissionCompletedToday(mission.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Badge: SUNNAH NABI ﷺ
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: mission.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: mission.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded,
                                size: 14, color: mission.primaryColor),
                            const SizedBox(width: 5),
                            Text(
                              Translations.get(lang, 'sunnah_event_badge'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: mission.primaryColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.amber.shade600.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 13, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              Translations.get(lang, 'pts_bonus_label')
                                  .replaceAll('{pts}', '${mission.pointsReward}'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mission Title & Time Window
                  Text(
                    mission.getTitle(lang),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_filled_rounded,
                              size: 13.5, color: Colors.teal.shade700),
                          const SizedBox(width: 5),
                          Text(
                            mission.getTimeBadge(lang),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "•",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700.withValues(alpha: 0.5),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 13.5, color: Colors.teal.shade700),
                          const SizedBox(width: 5),
                          Text(
                            mission.getAyahRangeText(lang),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fadhilah Card (Hadith Quote)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote_rounded,
                                size: 20, color: mission.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              Translations.get(lang, 'virtue_and_hadith'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: mission.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mission.getFadhilahHadith(lang),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Point & Energy Rules Note
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            Translations.get(lang, 'sunnah_outside_sequence_note')
                                .replaceAll('{pts}', '${mission.pointsReward}'),
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.4,
                              color: isDark
                                  ? Colors.teal.shade200
                                  : Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!isCompleted &&
                      mission.targetAyahStart != null &&
                      mission.targetAyahEnd != null) () {
                    final readAyahs = appState.getSunnahReadAyahs(mission.id);
                    final totalAyahs =
                        mission.targetAyahEnd! - mission.targetAyahStart! + 1;
                    if (readAyahs.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: mission.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: mission.primaryColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Translations.get(lang, 'progress_ayah_count')
                                    .replaceAll('{read}', '${readAyahs.length}')
                                    .replaceAll('{total}', '$totalAyahs'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.teal.shade200
                                      : mission.primaryColor,
                                ),
                              ),
                              Text(
                                '${((readAyahs.length / totalAyahs) * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.teal.shade200
                                      : mission.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalAyahs > 0
                                  ? (readAyahs.length / totalAyahs)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              backgroundColor: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                mission.primaryColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }(),

                  // Action Button
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.shade400,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            Translations.get(lang, 'sunnah_completed_today_claimed')
                                .replaceAll('{pts}', '${mission.pointsReward}'),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else () {
                    final readAyahs = appState.getSunnahReadAyahs(mission.id);
                    int? nextUnreadAyah;
                    if (mission.targetAyahStart != null &&
                        mission.targetAyahEnd != null) {
                      for (int a = mission.targetAyahStart!;
                          a <= mission.targetAyahEnd!;
                          a++) {
                        if (!readAyahs.contains(a)) {
                          nextUnreadAyah = a;
                          break;
                        }
                      }
                    }
                    final String buttonLabel = (readAyahs.isNotEmpty &&
                            nextUnreadAyah != null)
                        ? Translations.get(lang, 'continue_reading_ayah')
                            .replaceAll('{ayah}', '$nextUnreadAyah')
                        : Translations.get(lang, 'start_recitation_now');

                    return FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: mission.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateToMission(context, appState, mission);
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _navigateToMission(
    BuildContext context,
    AppState appState,
    SunnahMission mission,
  ) {
    if (appState.quranData.isEmpty) return;
    final surahIndex = mission.targetSurahNumber - 1;
    if (surahIndex < 0 || surahIndex >= appState.quranData.length) return;

    final surah = appState.quranData[surahIndex];
    int initialAyah = mission.targetAyahStart != null
        ? mission.targetAyahStart! - 1
        : 0;

    final readAyahs = appState.getSunnahReadAyahs(mission.id);
    if (mission.targetAyahStart != null && mission.targetAyahEnd != null) {
      for (int a = mission.targetAyahStart!; a <= mission.targetAyahEnd!; a++) {
        if (!readAyahs.contains(a)) {
          initialAyah = a - 1;
          break;
        }
      }
    }

    Navigator.of(context).push(
      AppPageRoute(
        child: SurahDetailScreen(
          surah: surah,
          initialAyahIndex: initialAyah,
        ),
      ),
    );
  }
}
