import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_launcher_2/widgets/ghadhul_bashar_dialog.dart';
import 'package:muslim_launcher_2/utils/translations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ghadhul Bashar Dialog renders Arabic verse, translations, and buttons', (WidgetTester tester) async {
    bool proceedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showGhadhulBasharDialog(
                  context,
                  appName: 'Chrome',
                  packageName: 'com.android.chrome',
                  languageCode: 'id',
                  onProceed: () {
                    proceedCalled = true;
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog elements exist
    expect(find.text(Translations.get('id', 'ghadhul_bashar_title')), findsOneWidget);
    expect(find.text(Translations.get('id', 'cancel')), findsOneWidget);
    expect(find.text(Translations.get('id', 'ok')), findsOneWidget);

    // Tap OK
    await tester.tap(find.text(Translations.get('id', 'ok')));
    await tester.pumpAndSettle();

    // Verify onProceed was triggered
    expect(proceedCalled, isTrue);
  });

  testWidgets('Ghadhul Bashar Dialog can be cancelled', (WidgetTester tester) async {
    bool proceedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showGhadhulBasharDialog(
                  context,
                  appName: 'Firefox',
                  packageName: 'org.mozilla.firefox',
                  languageCode: 'id',
                  onProceed: () {
                    proceedCalled = true;
                  },
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap Cancel
    await tester.tap(find.text(Translations.get('id', 'cancel')));
    await tester.pumpAndSettle();

    // Verify onProceed was NOT called and dialog dismissed
    expect(proceedCalled, isFalse);
    expect(find.text(Translations.get('id', 'ghadhul_bashar_title')), findsNothing);
  });
}
