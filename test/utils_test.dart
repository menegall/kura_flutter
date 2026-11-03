import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/core/utils.dart';

void main() {
  group('formatDuration', () {
    test('zero -> minuti', () {
      expect(formatDuration(0), '0 minuti');
    });

    test('meno di un\'ora -> solo minuti', () {
      expect(formatDuration(0.25), '15 minuti');
      expect(formatDuration(0.5), '30 minuti');
    });

    test('ora esatta -> senza minuti', () {
      expect(formatDuration(1), '1h');
      expect(formatDuration(3), '3h');
    });

    test('ore e minuti', () {
      expect(formatDuration(2.5), '2h e 30 minuti');
      expect(formatDuration(1 + 16 / 60), '1h e 16 minuti');
    });

    test('l\'arrotondamento float non produce "60 minuti"', () {
      expect(formatDuration(1.999), '2h');
      expect(formatDuration(0.99999), '1h');
    });
  });
}
