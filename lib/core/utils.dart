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
