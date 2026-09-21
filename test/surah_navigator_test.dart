import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_launcher_2/providers/app_state.dart';
import 'package:muslim_launcher_2/screens/quran/surah_list_screen.dart';

List<Map<String, dynamic>> createSampleQuranData() {
  return [
    {
      'surah_number': 1,
      'surah_name': 'Al-Fatihah',
      'total_ayah': 7,
      'ayahs': List.generate(7, (i) => {'arabic': 'بِسْمِ ٱللَّهِ'}),
    },
    {
      'surah_number': 2,
      'surah_name': 'Al-Baqarah',
      'total_ayah': 286,
      'ayahs': List.generate(286, (i) => {'arabic': 'الم'}),
    },
    {
      'surah_number': 7,
      'surah_name': "Al-A'raf",
      'total_ayah': 206,
      'ayahs': List.generate(206, (i) => {'arabic': 'المص'}),
    },
    {
      'surah_number': 18,
      'surah_name': 'Al-Kahf',
      'total_ayah': 110,
      'ayahs': List.generate(110, (i) => {'arabic': 'ٱلْحَمْدُ'}),
    },
    {
      'surah_number': 36,
      'surah_name': 'Ya-Sin',
      'total_ayah': 83,
      'ayahs': List.generate(83, (i) => {'arabic': 'يس'}),
    },
    {
      'surah_number': 56,
      'surah_name': "Al-Waqi'ah",
      'total_ayah': 96,
      'ayahs': List.generate(96, (i) => {'arabic': 'إِذَا'}),
    },
    {
      'surah_number': 58,
      'surah_name': 'Al-Mujadilah',
      'total_ayah': 22,
      'ayahs': List.generate(22, (i) => {'arabic': 'قَدْ'}),
    },
    {
      'surah_number': 67,
      'surah_name': 'Al-Mulk',
      'total_ayah': 30,
      'ayahs': List.generate(30, (i) => {'arabic': 'تَبَٰرَكَ'}),
    },
    {
      'surah_number': 78,
      'surah_name': "An-Naba'",
      'total_ayah': 40,
      'ayahs': List.generate(40, (i) => {'arabic': 'عَمَّ'}),
    },
    {
      'surah_number': 114,
      'surah_name': 'An-Nas',
      'total_ayah': 6,
      'ayahs': List.generate(6, (i) => {'arabic': 'قُلْ'}),
    },
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'languageCode': 'id'});

    const channelBlock = MethodChannel('com.muslimlauncher/block');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelBlock, (call) async => true);

    const channelApps = MethodChannel('com.muslimlauncher/apps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channelApps, (call) async {
      if (call.method == 'getApps') {
        return [];
      }
      return true;
    });
  });

  testWidgets('SurahListScreen renders Floating Pill and AppBar Jump Button',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final appState = AppState(prefs);
    await appState.setLanguage('id');

    // Populate sample quran data
    final sampleData = createSampleQuranData();
    appState.quranData.clear();
    appState.quranData.addAll(sampleData);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: SurahListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Floating Pill is displayed with Surah count
    expect(find.text('Surah 1 / 10'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);

    // Verify AppBar Near Me action button is present
    expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
  });

  testWidgets('Floating Pill opens Surah Navigator and In-App Keypad works',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final appState = AppState(prefs);
    await appState.setLanguage('id');

    final sampleData = createSampleQuranData();
    appState.quranData.clear();
    appState.quranData.addAll(sampleData);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: SurahListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Floating Pill
    await tester.tap(find.byIcon(Icons.explore_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Bottom sheet is now open
    expect(find.text('Lompat ke Surah'), findsOneWidget);
    expect(find.text('Pilih Surah 1 - 10'), findsOneWidget);

    // Verify Keypad Digits 1 to 9, 0, C, Backspace exist
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

    // Tap '2' on keypad
    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Number display shows 2 and live preview shows "Al-Baqarah • 286 Ayat"
    expect(find.text('2'), findsWidgets);
    expect(find.textContaining('Al-Baqarah'), findsWidgets);

    // Tap 'C' to clear
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Display reset
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('Quick Chips select and scroll to Surah properly',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final appState = AppState(prefs);
    await appState.setLanguage('id');

    final sampleData = createSampleQuranData();
    appState.quranData.clear();
    appState.quranData.addAll(sampleData);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: SurahListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Open Bottom Sheet
    await tester.tap(find.byIcon(Icons.explore_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Quick Chip "Surah 1 (Awal)"
    final chipFinder = find.text('Surah 1 (Awal)');
    expect(chipFinder, findsOneWidget);

    await tester.ensureVisible(chipFinder);
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();

    // Bottom sheet should be closed
    expect(find.text('Pilih Surah 1 - 10'), findsNothing);
  });

  testWidgets('Test Surah Navigator Bottom Sheet layout across 6 languages & screen widths without overflow',
      (tester) async {
    final sampleData = createSampleQuranData();
    final languages = ['id', 'en', 'ms', 'ar', 'af', 'sw'];
    final widths = [280.0, 320.0, 360.0, 400.0];

    for (final lang in languages) {
      for (final width in widths) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final prefs = await SharedPreferences.getInstance();
        final appState = AppState(prefs);
        await appState.setLanguage(lang);
        appState.quranData.clear();
        appState.quranData.addAll(sampleData);

        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: appState,
            child: MaterialApp(
              home: SurahListScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap AppBar Jump Button
        await tester.tap(find.byIcon(Icons.near_me_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on Surah Navigator in $lang at width $width',
        );

        // Close bottom sheet
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
  });
}
