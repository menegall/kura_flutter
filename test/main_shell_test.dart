import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/core/app_navigation.dart';
import 'package:kura_flutter/features/home/pages/main_shell.dart';

// Pagina principale finta di una scheda, con un dettaglio (dentro la
// scheda) e un form (a schermo intero) da aprire.
class _FakeTab extends StatelessWidget {
  final String name;
  const _FakeTab(this.name);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Scaffold(appBar: AppBar(title: Text('Dettaglio $name'))),
            )),
            child: Text('apri dettaglio $name'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (_) => Scaffold(appBar: AppBar(title: const Text('Form'))),
            )),
            child: Text('apri form $name'),
          ),
        ],
      ),
    );
  }
}

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MainShell(tabRoots: [_FakeTab('Pupilli'), _FakeTab('Statistiche'), _FakeTab('Impostazioni')]),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('il dettaglio si apre dentro la scheda e il menu resta visibile', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('apri dettaglio Pupilli'));
    await tester.pumpAndSettle();

    expect(find.text('Dettaglio Pupilli'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('il form si apre a schermo intero, senza menu', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('apri form Pupilli'));
    await tester.pumpAndSettle();

    expect(find.text('Form'), findsOneWidget);
    expect(find.byType(NavigationBar).hitTestable(), findsNothing);
  });

  testWidgets('ogni scheda ricorda la sua pagina e ritoccarla riporta all\'inizio', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('apri dettaglio Pupilli'));
    await tester.pumpAndSettle();

    // Cambio scheda e ritorno: il dettaglio è ancora aperto.
    await tester.tap(find.text('Statistiche').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pupilli').last);
    await tester.pumpAndSettle();
    expect(find.text('Dettaglio Pupilli'), findsOneWidget);

    // Toccare di nuovo la scheda attiva torna alla pagina principale.
    await tester.tap(find.text('Pupilli').last);
    await tester.pumpAndSettle();
    expect(find.text('Dettaglio Pupilli'), findsNothing);
    expect(find.text('apri dettaglio Pupilli'), findsOneWidget);
  });

  testWidgets('indietro chiude il dettaglio della scheda visibile', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('apri dettaglio Pupilli'));
    await tester.pumpAndSettle();

    // Come il tasto indietro di Android o del browser.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Dettaglio Pupilli'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('openStatsForPupil passa alla scheda Statistiche', (tester) async {
    await pumpShell(tester);
    openStatsForPupil('p1');
    await tester.pumpAndSettle();

    expect(currentAppTab.value, AppTab.stats);
    expect(requestedStatsPupilId.value, 'p1');
    expect(find.text('apri dettaglio Statistiche'), findsOneWidget);
    requestedStatsPupilId.value = null;
  });
}
