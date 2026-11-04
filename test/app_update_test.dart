import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kura_flutter/core/app_update.dart';

Map<String, dynamic> _whatsNew(List<(int, List<String>)> releases) => {
      'releases': [
        for (final (id, items) in releases) {'id': id, 'items': items},
      ],
    };

void main() {
  group('newReleaseNotes', () {
    test('mostra solo le release più recenti di quella installata, dalla più nuova', () {
      final remote = _whatsNew([(4, ['d1', 'd2']), (3, ['c']), (2, ['b']), (1, ['a'])]);
      expect(newReleaseNotes(2, remote), ['d1', 'd2', 'c']);
    });

    test('nessuna release nuova -> lista vuota', () {
      expect(newReleaseNotes(1, _whatsNew([(1, ['a'])])), isEmpty);
    });

    test('limita il numero di voci', () {
      final remote = _whatsNew([(1, List.generate(10, (i) => 'v$i'))]);
      expect(newReleaseNotes(0, remote, limit: 3), ['v0', 'v1', 'v2']);
    });

    test('ignora voci e release malformate', () {
      final remote = {
        'releases': [
          {'id': 2, 'items': ['ok', 3, null]},
          'non una release',
        ],
      };
      expect(newReleaseNotes(1, remote), ['ok']);
    });
  });

  test('assets/whats_new.json è valido e ha id univoci', () {
    final json = jsonDecode(File('assets/whats_new.json').readAsStringSync()) as Map<String, dynamic>;
    final ids = (json['releases'] as List).map((r) => r['id'] as int).toList();
    expect(ids, isNotEmpty);
    expect(ids.toSet(), hasLength(ids.length));
    for (final release in json['releases'] as List) {
      expect((release['items'] as List), isNotEmpty);
    }
  });
}
