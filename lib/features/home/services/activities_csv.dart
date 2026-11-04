import '../../../core/utils.dart';
import '../models/activity_model.dart';

/// Genera un CSV delle attività pronto da aprire in Excel.
///
/// Separatore `;` (quello che Excel usa con le impostazioni svizzere e
/// italiane) e BOM UTF-8 iniziale, così le lettere accentate si vedono
/// correttamente. I numeri usano il punto come separatore decimale.
String buildActivitiesCsv(List<Activity> activities) {
  final rows = <List<String>>[
    [
      'Data',
      'Tipo',
      'Durata (ore)',
      'Durata',
      'Km',
      'Francobolli (CHF)',
      'Altre spese (CHF)',
      'Descrizione',
    ],
    for (final a in activities)
      [
        formatDate(a.activityDate),
        a.typeLabel,
        _number(a.duration),
        a.duration != null ? formatDuration(a.duration!) : '',
        _number(a.kilometers),
        _number(a.stamp),
        _number(a.otherExpenses),
        a.description ?? '',
      ],
  ];
  return '﻿${rows.map((r) => r.map(_escape).join(';')).join('\r\n')}\r\n';
}

String _number(double? value) {
  if (value == null) return '';
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toString();
}

String _escape(String field) {
  if (field.contains(';') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}
