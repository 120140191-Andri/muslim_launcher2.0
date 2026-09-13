import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/quran/surah_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
      'points': 100,
      'highestSurahIndex': 0,
      'highestAyahIndex': 2,
    });
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => []);
  });

  group('Two-Phase Eye Reading & Animated Dots Tests', () {
    test('Animated dots string cycles correctly (1 -> 2 -> 3 -> 1)', () {
      final text1 = SurahDetailScreen.getEyeTrackingText(
        'id',
        isFocused: true,
        phase: EyeReadingPhase.arabic,
        dotCount: 1,
      );
      final text2 = SurahDetailScreen.getEyeTrackingText(
        'id',
        isFocused: true,
        phase: EyeReadingPhase.arabic,
        dotCount: 2,
      );
      final text3 = SurahDetailScreen.getEyeTrackingText(
        'id',
        isFocused: true,
        phase: EyeReadingPhase.arabic,
        dotCount: 3,
      );

      expect(text1, 'Membaca Arab.');
      expect(text2, 'Membaca Arab..');
      expect(text3, 'Membaca Arab...');

      // Translation phase also has animated dots
      final transText1 = SurahDetailScreen.getEyeTrackingText(
        'id',
        isFocused: true,
        phase: EyeReadingPhase.translation,
        dotCount: 1,
      );
      final transText2 = SurahDetailScreen.getEyeTrackingText(
        'id',
        isFocused: true,
        phase: EyeReadingPhase.translation,
        dotCount: 2,
      );
      final transText3 = SurahDetailScreen.getEyeTrackingText(
        'id',
        isFocused: true,
        phase: EyeReadingPhase.translation,
        dotCount: 3,
      );

      expect(transText1, 'Membaca Arti.');
      expect(transText2, 'Membaca Arti..');
      expect(transText3, 'Membaca Arti...');
    });

    test('6-Language Parity: Arabic phase text across all languages', () {
      final expectedByLang = {
        'id': 'Membaca Arab...',
        'ms': 'Membaca Teks Arab...',
        'en': 'Reading Arabic...',
        'ar': 'قراءة النص العربي...',
        'af': 'Lees Arabiese Teks...',
        'sw': 'Kusoma Maandishi ya Kiarabu...',
      };

      for (final entry in expectedByLang.entries) {
        final text = SurahDetailScreen.getEyeTrackingText(
          entry.key,
          isFocused: true,
          phase: EyeReadingPhase.arabic,
          dotCount: 3,
        );
        expect(text, entry.value, reason: 'Failed for language: ${entry.key}');
        expect(text.contains('...'), true);
      }
    });

    test('6-Language Parity: Translation/Meaning phase text across all languages', () {
      final expectedByLang = {
        'id': 'Membaca Arti...',
        'ms': 'Membaca Terjemahan...',
        'en': 'Reading Meaning...',
        'ar': 'قراءة المعنى...',
        'af': 'Lees Betekenis...',
        'sw': 'Kusoma Maana...',
      };

      for (final entry in expectedByLang.entries) {
        final text = SurahDetailScreen.getEyeTrackingText(
          entry.key,
          isFocused: true,
          phase: EyeReadingPhase.translation,
          dotCount: 3,
        );
        expect(text, entry.value, reason: 'Failed for language: ${entry.key}');
        expect(text.contains('...'), true);
      }
    });

    test('6-Language Parity: Unfocused text prompt across all languages', () {
      final expectedByLang = {
        'id': 'TIDAK FOKUS: Tatap Ayat untuk Membaca',
        'ms': 'TIDAK FOKUS: Pandang Ayat untuk Membaca',
        'en': 'NOT FOCUSED: Look at Ayah to read',
        'ar': 'غير مركز: انظر إلى الآية للقراءة',
        'af': 'NIE GEFOKUS: Kyk na Vers om te lees',
        'sw': 'HAIJALENGA: Tazama Aya ili kusoma',
      };

      for (final entry in expectedByLang.entries) {
        final text = SurahDetailScreen.getEyeTrackingText(
          entry.key,
          isFocused: false,
        );
        expect(text, entry.value, reason: 'Failed for language: ${entry.key}');
      }
    });

    testWidgets('SurahDetailScreen renders _EyeButton on Ayah card', (tester) async {
      final appState = AppState(prefs);

      final dummySurah = {
        'surah_number': 1,
        'surah_name': 'Al-Fatihah',
        'ayahs': [
          {
            'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            'latin': 'Bismillahir-rahmanir-rahim',
            'translation_id': 'Dengan nama Allah Yang Maha Pengasih, Maha Penyayang',
            'translation_en': 'In the name of Allah, the Entirely Merciful, the Especially Merciful',
          },
        ],
      };

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: SurahDetailScreen(surah: dummySurah),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find eye icon or "Dalam Hati" text on the Ayah card
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsWidgets);
      expect(find.text('Dalam Hati'), findsOneWidget);
    });
  });
}
