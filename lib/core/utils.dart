import 'package:intl/intl.dart';

final DateFormat _dayMonthYear = DateFormat('dd/MM/yyyy');

const List<String> italianMonths = [
  'Gennaio',
  'Febbraio',
  'Marzo',
  'Aprile',
  'Maggio',
  'Giugno',
  'Luglio',
  'Agosto',
  'Settembre',
  'Ottobre',
  'Novembre',
  'Dicembre',
];

/// Formatta una data come `gg/MM/aaaa`.
String formatDate(DateTime date) => _dayMonthYear.format(date);

/// Converte un numero inserito dall'utente accettando sia la virgola sia il
/// punto come separatore decimale ("15,5" e "15.5"). Restituisce null se il
/// testo è vuoto o non è un numero.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

String formatDuration(double hours) {
  int h = hours.floor();
  // Arrotonda per prevenire problemi di precisione dei float (es. 0.25 * 60 = 15)
  int m = ((hours - h) * 60).round();
  // L'arrotondamento puo' spingere i minuti a 60 (es. 1.999h): riporta l'ora.
  if (m == 60) {
    h += 1;
    m = 0;
  }

  if (h == 0) {
    return '$m minuti';
  } else if (m == 0) {
    return '${h}h';
  } else {
    return '${h}h e $m minuti';
  }
}
