import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/core/app_navigation.dart';
import 'package:kura_flutter/features/home/widgets/app_tour.dart';

void main() {
  // Riproduce la struttura vera dell'app: Home dentro le schede
  // (IndexedStack) con uno Scaffold annidato, e su schermi larghi l'app
  // centrata come in main.dart.
  for (final size in [const Size(390, 844), const Size(1280, 800)]) {
    testWidgets('il tour evidenzia gli elementi della Home ($size)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext homeContext;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) {
          if (MediaQuery.of(context).size.width <= 600) return child!;
          return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1050), child: child));
        },
        home: Scaffold(
          body: IndexedStack(index: 0, children: [
            Scaffold(
              appBar: AppBar(title: const Text('Ciao')),
              body: Builder(builder: (c) {
                homeContext = c;
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView(children: [
                    const SizedBox(height: 100),
                    OutlinedButton(key: TourKeys.addPupil, onPressed: () {}, child: const Text('Aggiungi pupillo')),
                  ]),
                );
              }),
              floatingActionButton: FloatingActionButton.extended(
                key: TourKeys.addActivity, onPressed: () {}, label: const Text('Registra')),
            ),
            const SizedBox(),
            const SizedBox(),
          ]),
          bottomNavigationBar: NavigationBar(destinations: [
            const NavigationDestination(icon: Icon(Icons.people), label: 'Pupilli'),
            NavigationDestination(key: TourKeys.statsTab, icon: const Icon(Icons.bar_chart), label: 'S'),
            NavigationDestination(key: TourKeys.settingsTab, icon: const Icon(Icons.settings), label: 'I'),
          ]),
        ),
      ));
      startAppTour(homeContext, onFinished: () {});
      await tester.pumpAndSettle();
      for (final key in [TourKeys.addPupil, TourKeys.addActivity, TourKeys.statsTab, TourKeys.settingsTab]) {
        await tester.tap(find.byType(ElevatedButton).last);
        await tester.pumpAndSettle();
        final painters = tester.widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .where((p) => p.runtimeType.toString() == '_HolePainter');
        final hole = (painters.single as dynamic).hole as Rect?;
        expect(hole, isNotNull, reason: '$key');
        // Il velo è disegnato nelle coordinate dell'Overlay (centrato su
        // schermi larghi): si riporta il buco in coordinate dello schermo.
        final overlayOrigin = tester.getTopLeft(find.byType(Overlay).first);
        final target = tester.getRect(find.byKey(key));
        expect(hole!.shift(overlayOrigin).contains(target.center), isTrue, reason: '$key');
      }
    });
  }
}
