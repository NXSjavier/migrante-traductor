import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:migrante_traductor/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // The app asks the native side for the installed models on startup. Without
    // a handler that call never resolves and the test binding fails with a
    // pending timer.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('migrante/models'),
      (MethodCall call) async => false,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('migrante/diagnostics'),
      (MethodCall call) async => null,
    );
  });

  Future<void> openLearningTab(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MigranteTraductorApp());
    await tester.pump();

    await tester.tap(find.byIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
  }

  Future<void> openGreetingsLesson(WidgetTester tester) async {
    await openLearningTab(tester);

    await tester.scrollUntilVisible(
      find.text('Primeros pasos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Primeros pasos'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Saludos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Saludos'));
    await tester.pumpAndSettle();
  }

  testWidgets('App renders the home shell', (WidgetTester tester) async {
    // Use a realistic phone viewport instead of the 800x600 test default.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MigranteTraductorApp());
    await tester.pump();

    expect(find.text('Migrante Traductor'), findsOneWidget);
  });

  testWidgets('Learning tab shows the levels and opens a lesson',
      (WidgetTester tester) async {
    await openLearningTab(tester);

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('Repaso general'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Primeros pasos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Primeros pasos'), findsOneWidget);

    await tester.tap(find.text('Primeros pasos'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Saludos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Saludos'));
    await tester.pumpAndSettle();

    expect(find.text('Rompecabezas 1 de 5'), findsOneWidget);
    expect(find.text('Hola.'), findsOneWidget);
    expect(find.text('Decilo en inglés'), findsOneWidget);
  });

  testWidgets('Lesson puzzles can be solved without help and score 100%',
      (WidgetTester tester) async {
    await openGreetingsLesson(tester);

    // 1. Multiple choice: "Hello."
    await tester.tap(find.text('Hello.'));
    await tester.pumpAndSettle();
    expect(find.text('¡Correcto!'), findsOneWidget);
    await tester.tap(find.text('Siguiente rompecabezas'));
    await tester.pumpAndSettle();

    // 2. Order the words: "How are you?"
    expect(find.text('Rompecabezas 2 de 5'), findsOneWidget);
    await tester.tap(find.text('How'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('are'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('you?'));
    await tester.pumpAndSettle();
    expect(find.text('¡Correcto!'), findsOneWidget);
    await tester.tap(find.text('Siguiente rompecabezas'));
    await tester.pumpAndSettle();

    // 3. Fill the gap: "Fine, thank you."
    expect(find.text('Rompecabezas 3 de 5'), findsOneWidget);
    await tester.tap(find.text('you.'));
    await tester.pumpAndSettle();
    expect(find.text('¡Correcto!'), findsOneWidget);
    await tester.tap(find.text('Siguiente rompecabezas'));
    await tester.pumpAndSettle();

    // 4. Multiple choice: "Good morning."
    await tester.tap(find.text('Good morning.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente rompecabezas'));
    await tester.pumpAndSettle();

    // 5. Multiple choice: "Good night."
    await tester.tap(find.text('Good night.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultado'));
    await tester.pumpAndSettle();

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Volver a los niveles'), findsOneWidget);
  });

  testWidgets('Revealing the answer still advances but does not score',
      (WidgetTester tester) async {
    await openGreetingsLesson(tester);

    await tester.tap(find.text('No me sale: ver la respuesta'));
    await tester.pumpAndSettle();

    expect(find.text('Así se dice'), findsOneWidget);
    expect(find.text('Hello.'), findsOneWidget);

    await tester.tap(find.text('Siguiente rompecabezas'));
    await tester.pumpAndSettle();

    expect(find.text('Rompecabezas 2 de 5'), findsOneWidget);
  });

  testWidgets('Review card opens a mixed lesson with phrases from every level',
      (WidgetTester tester) async {
    await openLearningTab(tester);

    await tester.tap(find.text('Practicar'));
    await tester.pumpAndSettle();

    expect(find.text('Rompecabezas 1 de 10'), findsOneWidget);
    expect(find.text('Repaso general'), findsOneWidget);
  });

  testWidgets('Phrase browser shows the whole course with audio',
      (WidgetTester tester) async {
    await openLearningTab(tester);

    await tester.tap(find.text('Ver todo'));
    await tester.pumpAndSettle();

    expect(
      find.text('160 frases con audio en español e inglés'),
      findsOneWidget,
    );
    expect(find.text('Todas las frases'), findsOneWidget);
  });
}
