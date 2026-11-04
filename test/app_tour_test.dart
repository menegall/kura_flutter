import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/core/app_navigation.dart';
import 'package:kura_flutter/features/home/widgets/app_tour.dart';

void main() {
  // Pagina finta con gli stessi elementi (chiavi) che il tour evidenzia.
  Widget fakeShell({bool withSettingsTab = true}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            key: TourKeys.addPupil,
            onPressed: () {},
            child: const Text('Aggiungi pupillo'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: TourKeys.addActivity,
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: NavigationBar(
          destinations: [
            const NavigationDestination(icon: Icon(Icons.people), label: 'Pupilli'),
            NavigationDestination(key: TourKeys.statsTab, icon: const Icon(Icons.bar_chart), label: 'Statistiche'),
            NavigationDestination(
              key: withSettingsTab ? TourKeys.settingsTab : null,
              icon: const Icon(Icons.settings),
              label: 'Impostazioni',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> start(WidgetTester tester, VoidCallback onFinished) async {
    startAppTour(tester.element(find.byType(Scaffold)), onFinished: onFinished);
    await tester.pumpAndSettle();
  }

  testWidgets('percorre tutti i passi fino a Fine', (tester) async {
    await tester.pumpWidget(fakeShell());
    var finished = 0;
    await start(tester, () => finished++);

    expect(find.text('Benvenuto in Kura!'), findsOneWidget);
    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi i tuoi pupilli'), findsOneWidget);
    expect(find.text('2 di 5'), findsOneWidget);

    for (final title in ['Registra le attività', 'Statistiche']) {
      await tester.tap(find.text('Avanti'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets);
    }
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    expect(find.text('5 di 5'), findsOneWidget);
    expect(find.text('Salta'), findsNothing);

    await tester.tap(find.text('Fine'));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(find.text('5 di 5'), findsNothing);
  });

  testWidgets('Salta chiude subito il tour', (tester) async {
    await tester.pumpWidget(fakeShell());
    var finished = 0;
    await start(tester, () => finished++);

    await tester.tap(find.text('Salta'));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(find.text('Benvenuto in Kura!'), findsNothing);
  });

  testWidgets('un elemento assente viene saltato', (tester) async {
    await tester.pumpWidget(fakeShell(withSettingsTab: false));
    var finished = 0;
    await start(tester, () => finished++);

    await tester.tap(find.text('Inizia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    expect(find.text('4 di 5'), findsOneWidget);
    // Manca la scheda Impostazioni: "Avanti" chiude il tour.
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();
    expect(finished, 1);
  });
}
