import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_version.dart';

/// Aggiornamento disponibile, con le novità da mostrare all'utente.
class UpdateInfo {
  final String commit;
  final List<String> notes;
  const UpdateInfo(this.commit, this.notes);
}

/// Voci delle release di [remote] (il contenuto di `assets/whats_new.json`
/// dell'ultima versione pubblicata) con id maggiore di [installedReleaseId],
/// dalla più recente, al massimo [limit].
List<String> newReleaseNotes(
  int installedReleaseId,
  Map<String, dynamic> remote, {
  int limit = 6,
}) {
  final installed = installedReleaseId;
  final newer = _releases(remote)
      .where((r) => ((r['id'] as num?)?.toInt() ?? 0) > installed)
      .toList()
    ..sort((a, b) => ((b['id'] as num?) ?? 0).compareTo((a['id'] as num?) ?? 0));
  return [
    for (final release in newer)
      for (final item in (release['items'] as List<dynamic>? ?? const []))
        if (item is String) item,
  ].take(limit).toList();
}

List<Map<String, dynamic>> _releases(Map<String, dynamic> json) =>
    (json['releases'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

/// Controlla se sul sito c'è una versione più recente di quella in uso.
/// Null se l'app è aggiornata, se non è la webapp pubblicata o se la rete
/// non risponde.
Future<UpdateInfo?> checkForUpdate() async {
  final latest = await fetchLatestCommit();
  if (latest == null || latest == appCommit) return null;
  var notes = <String>[];
  try {
    // Sul web anche gli asset si scaricano dal sito, quindi questo è sempre
    // il file della versione pubblicata; quella in uso è appReleaseId,
    // inserito nell'app al momento della build.
    final url = Uri.base.resolve('assets/assets/whats_new.json').replace(
      queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final remote = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      notes = newReleaseNotes(appReleaseId, remote);
    }
  } catch (_) {
    // Senza novità il banner mostra un testo generico.
  }
  return UpdateInfo(latest, notes);
}
