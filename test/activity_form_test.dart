import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/features/home/models/activity_model.dart';
import 'package:kura_flutter/features/home/widgets/activity_form.dart';

void main() {
  Future<List<ActivityFormData>> pumpForm(
    WidgetTester tester, {
    Activity? initial,
    bool requireDuration = true,
  }) async {
    final submitted = <ActivityFormData>[];
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActivityForm(
              initial: initial,
              requireDuration: requireDuration,
              submitLabel: 'Salva',
              onSubmit: (data) async => submitted.add(data),
            ),
          ),
        ),
      ),
    );
    return submitted;
  }

  testWidgets('la scelta rapida imposta la durata', (tester) async {
    final submitted = await pumpForm(tester);
    await tester.tap(find.text('1 h 30'));
    await tester.pump();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(submitted, hasLength(1));
    expect(submitted.single.duration, 1.5);
    expect(submitted.single.type, 'call');
  });

  testWidgets('senza durata non salva e mostra l\'errore', (tester) async {
    final submitted = await pumpForm(tester);
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(submitted, isEmpty);
    expect(find.text('Indica quanto tempo hai impiegato.'), findsOneWidget);
  });

  testWidgets('trasferta: km visibili e accettano la virgola', (tester) async {
    final submitted = await pumpForm(tester);
    expect(find.text('Km percorsi'), findsNothing);

    await tester.tap(find.text('Trasferta'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'Km percorsi'), '15,5');
    await tester.tap(find.text('30 min'));
    await tester.pump();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(submitted.single.kilometers, 15.5);
    expect(submitted.single.duration, 0.5);
  });

  testWidgets('in modifica la durata è facoltativa e i valori sono precompilati', (tester) async {
    final activity = Activity(
      id: '1',
      pupilId: 'p',
      activityDate: DateTime(2026, 3, 10),
      type: 'mail',
      stamp: 1.2,
      otherExpenses: 4,
      createdAt: DateTime(2026, 3, 10),
    );
    final submitted = await pumpForm(tester, initial: activity, requireDuration: false);
    expect(find.text('Altre spese (CHF)'), findsOneWidget);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    final data = submitted.single;
    expect(data.duration, isNull);
    expect(data.type, 'mail');
    expect(data.stamp, 1.2);
    expect(data.otherExpenses, 4);
    expect(data.date, DateTime(2026, 3, 10));
  });
}
