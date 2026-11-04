import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/features/home/models/activity_model.dart';
import 'package:kura_flutter/features/home/services/activities_csv.dart';

Activity _activity({
  required DateTime date,
  String type = 'call',
  double? duration,
  double? km,
  double? stamp,
  double? other,
  String? description,
}) {
  return Activity(
    id: '${date.millisecondsSinceEpoch}',
    pupilId: 'p',
    activityDate: date,
    type: type,
    duration: duration,
    kilometers: km,
    stamp: stamp,
    otherExpenses: other,
    description: description,
    createdAt: date,
  );
}

void main() {
  group('buildActivitiesCsv', () {
    test('intestazione, BOM e una riga per attività', () {
      final csv = buildActivitiesCsv([
        _activity(date: DateTime(2026, 3, 5), type: 'transfert', duration: 1.5, km: 12.25, other: 4),
        _activity(date: DateTime(2026, 3, 6), type: 'mail', duration: 0.25, stamp: 1.2),
      ]);
      expect(csv.startsWith('﻿'), isTrue);
      final lines = csv.substring(1).trim().split('\r\n');
      expect(lines, hasLength(3));
      expect(lines[0], 'Data;Tipo;Durata (ore);Durata;Km;Francobolli (CHF);Altre spese (CHF);Descrizione');
      expect(lines[1], '05/03/2026;Trasferta;1.5;1h e 30 minuti;12.25;;4;');
      expect(lines[2], '06/03/2026;Email/Lettera;0.25;15 minuti;;1.2;;');
    });

    test('le descrizioni con ; virgolette o a capo vengono racchiuse', () {
      final csv = buildActivitiesCsv([
        _activity(date: DateTime(2026, 1, 2), duration: 1, description: 'Banca; "conto"\nnuovo'),
      ]);
      expect(csv, contains('"Banca; ""conto""\nnuovo"'));
    });
  });

  group('groupActivitiesByMonth', () {
    test('raggruppa mantenendo l\'ordine e somma le ore', () {
      final groups = groupActivitiesByMonth([
        _activity(date: DateTime(2026, 10, 20), duration: 1),
        _activity(date: DateTime(2026, 10, 3), duration: 0.5),
        _activity(date: DateTime(2026, 9, 30), duration: 2),
        _activity(date: DateTime(2025, 9, 1)),
      ]);
      expect(groups.map((g) => '${g.year}-${g.month}'), ['2026-10', '2026-9', '2025-9']);
      expect(groups[0].activities, hasLength(2));
      expect(groups[0].totalHours, 1.5);
      expect(groups[2].totalHours, 0);
    });

    test('lista vuota -> nessun gruppo', () {
      expect(groupActivitiesByMonth([]), isEmpty);
    });
  });
}
