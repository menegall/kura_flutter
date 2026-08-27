import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/core/billing.dart';
import 'package:kura_flutter/features/home/models/activity_model.dart';

Activity _act({
  String type = 'call',
  double? duration,
  double? kilometers,
  double? stamp,
  double? otherExpenses,
}) {
  return Activity(
    id: 'x',
    pupilId: 'p',
    activityDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    type: type,
    duration: duration,
    kilometers: kilometers,
    stamp: stamp,
    otherExpenses: otherExpenses,
  );
}

void main() {
  group('computeBilling', () {
    test('lista vuota -> tutto a zero', () {
      final b = computeBilling([], tarif: 50, kmTarif: 0.7);
      expect(b.grandTotal, 0);
      expect(b.workedHours, 0);
    });

    test('somma ore, km, francobolli e altre spese da tutte le attività', () {
      final b = computeBilling(
        [
          _act(type: 'call', duration: 1.5),
          _act(type: 'transfert', duration: 0.5, kilometers: 20),
          _act(type: 'mail', duration: 0.25, stamp: 1.2),
          _act(type: 'other', duration: 1, otherExpenses: 15),
        ],
        tarif: 40,
        kmTarif: 0.7,
      );
      expect(b.workedHours, 3.25);
      expect(b.totalKm, 20);
      expect(b.totalStamps, 1.2);
      expect(b.totalOtherExpenses, 15);
      expect(b.hoursCost, closeTo(130, 1e-9)); // 3.25 * 40
      expect(b.kmCost, closeTo(14, 1e-9)); // 20 * 0.7
      expect(b.grandTotal, closeTo(130 + 14 + 1.2 + 15, 1e-9));
    });

    test('i km contano anche fuori dalle trasferte', () {
      final b = computeBilling(
        [_act(type: 'meeting_pupils', duration: 1, kilometers: 10)],
        tarif: 0,
        kmTarif: 1,
      );
      expect(b.kmCost, 10);
    });
  });
}
