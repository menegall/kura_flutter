String formatDuration(double hours) {
  final int h = hours.floor();
  // Arrotonda per prevenire problemi di precisione dei float (es. 0.25 * 60 = 15)
  final int m = ((hours - h) * 60).round();

  if (h == 0) {
    return '$m minuti';
  } else if (m == 0) {
    return '${h}h';
  } else {
    return '${h}h e $m minuti';
  }
}
