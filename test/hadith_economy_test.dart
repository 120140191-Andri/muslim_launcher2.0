import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/hadith/hadith_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'id',
      'hasSelectedLanguage': true,
      'hasCompletedOnboarding': true,
    });
    prefs = await SharedPreferences.getInstance();

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async => true);
  });

  group('Hadith Points Economy (Option 1) Tests', () {
    test('First 3 distinct hadiths award full points (2-4 pts based on length)', () async {
      final appState = AppState(prefs);
      expect(appState.readHadithIds, isEmpty);
      expect(appState.points, 0);

      // Hadith 1 (Base 3 pts) -> awards 3
      final pts1 = await appState.saveHadithProgress(1, 'Hadits #1: Niat', 3);
      expect(pts1, 3);
      expect(appState.points, 3);
      expect(appState.readHadithIds.contains(1), true);
      expect(appState.readHadithIds.length, 1);

      // Hadith 2 (Base 4 pts) -> awards 4
      final pts2 = await appState.saveHadithProgress(2, 'Hadits #2: Iman', 4);
      expect(pts2, 4);
      expect(appState.points, 7);
      expect(appState.readHadithIds.contains(2), true);
      expect(appState.readHadithIds.length, 2);

      // Hadith 3 (Base 2 pts) -> awards 2
      final pts3 = await appState.saveHadithProgress(3, 'Hadits #3: Islam', 2);
      expect(pts3, 2);
      expect(appState.points, 9);
      expect(appState.readHadithIds.contains(3), true);
      expect(appState.readHadithIds.length, 3);
    });

    test('4th hadith onwards awards 1 point (daily full reward cap reached)', () async {
      final appState = AppState(prefs);

      // Complete first 3 hadiths
      await appState.saveHadithProgress(1, 'Hadits #1', 3);
      await appState.saveHadithProgress(2, 'Hadits #2', 4);
      await appState.saveHadithProgress(3, 'Hadits #3', 2);
      expect(appState.points, 9);
      expect(appState.readHadithIds.length, 3);

      // 4th hadith (even if base is 4) -> awards 1 point
      final pts4 = await appState.saveHadithProgress(4, 'Hadits #4', 4);
      expect(pts4, 1);
      expect(appState.points, 10);
      expect(appState.readHadithIds.length, 4);

      // 5th hadith -> awards 1 point
      final pts5 = await appState.saveHadithProgress(5, 'Hadits #5', 3);
      expect(pts5, 1);
      expect(appState.points, 11);
      expect(appState.readHadithIds.length, 5);
    });

    test('Re-reading an already completed hadith awards 1 point (diminishing return, not 0)', () async {
      final appState = AppState(prefs);

      // Read Hadith #1 for the first time -> full 3 points
      final pts1 = await appState.saveHadithProgress(1, 'Hadits #1', 3);
      expect(pts1, 3);
      expect(appState.points, 3);

      // Re-read Hadith #1 on the same day -> awards 1 point
      final pts1Repeat = await appState.saveHadithProgress(1, 'Hadits #1', 3);
      expect(pts1Repeat, 1);
      expect(appState.points, 4);
    });

    test('getHadithPointsToAward reflects dynamic points accurately', () {
      final appState = AppState(prefs);

      // Initially empty -> full points
      expect(appState.getHadithPointsToAward(1, 3), 3);
      expect(appState.getHadithPointsToAward(2, 4), 4);
      expect(appState.getHadithPointsToAward(3, 2), 2);

      // After 3 hadiths completed
      appState.setHadithStateForTesting(readIds: {1, 2, 3});
      // Any new hadith -> 1 point
      expect(appState.getHadithPointsToAward(4, 4), 1);
      // Any existing hadith -> 1 point
      expect(appState.getHadithPointsToAward(1, 3), 1);
    });

    test('Midnight date reset restores full reward for first 3 hadiths', () async {
      final appState = AppState(prefs);

      await appState.saveHadithProgress(1, 'Hadits #1', 3);
      await appState.saveHadithProgress(2, 'Hadits #2', 3);
      await appState.saveHadithProgress(3, 'Hadits #3', 3);
      expect(appState.readHadithIds.length, 3);

      // 4th hadith today gives 1
      expect(appState.getHadithPointsToAward(4, 4), 1);

      // Simulate next day
      await appState.setHadithStateForTesting(lastDate: '2026-09-01');

      // Next day, hadith gives full reward again!
      final ptsNewDay = await appState.saveHadithProgress(1, 'Hadits #1', 3);
      expect(ptsNewDay, 3);
      expect(appState.readHadithIds.length, 1);
    });

    testWidgets('HadithListScreen displays dynamic points badges (+2-4 Poin or +1 Poin when limit reached)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final appState = AppState(prefs);
      // Populate hadith data mock
      appState.setHadithDataForTesting([
        {
          'id': 1,
          'theme': 'Ikhlas & Niat',
          'arabic': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
          'translations': {'id': 'Sesungguhnya setiap amal tergantung pada niatnya.'},
          'narrators': {'id': 'HR. Bukhari & Muslim'},
        },
        {
          'id': 2,
          'theme': 'Menuntut Ilmu',
          'arabic': 'طَلَبُ الْعِلْمِ فَرِيضَةٌ عَلَى كُلِّ مُسْلِمٍ',
          'translations': {'id': 'Menuntut ilmu itu wajib atas setiap muslim.'},
          'narrators': {'id': 'HR. Ibnu Majah'},
        },
        {
          'id': 3,
          'theme': 'Akhlak Mulia',
          'arabic': 'أَكْمَلُ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا',
          'translations': {'id': 'Orang mukmin yang paling sempurna imannya adalah yang paling baik akhlaknya.'},
          'narrators': {'id': 'HR. Tirmidzi'},
        },
        {
          'id': 4,
          'theme': 'Senyum Shadaqah',
          'arabic': 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
          'translations': {'id': 'Senyummu di hadapan saudaramu adalah sedekah bagimu.'},
          'narrators': {'id': 'HR. Tirmidzi'},
        },
      ]);
      appState.setReadyForTesting();

      // Case 1: Fresh state, all hadiths show full 2-4 points
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: HadithListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show points badges (+2 Poin)
      expect(find.text('+2 Poin'), findsWidgets);

      // Case 2: User completes 3 hadiths
      await appState.setHadithStateForTesting(readIds: {1, 2, 3});
      await tester.pumpAndSettle();

      // Hadith 1, 2, 3 show "Selesai"
      expect(find.text('Selesai'), findsNWidgets(3));

      // Unread Hadith 4 shows +1 Poin (daily limit reached)
      expect(find.text('+1 Poin'), findsOneWidget);
    });
  });
}
