import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Valori inseriti dal workflow di deploy con --dart-define. In una build
// locale restano vuoti.
const String appCommit = String.fromEnvironment('APP_COMMIT');
const String appBuildDate = String.fromEnvironment('APP_BUILD_DATE');
const String appChannel = String.fromEnvironment('APP_CHANNEL');

/// Testo della versione da mostrare all'utente, es. "a1b2c3d del 04/11/2026".
String get appVersionLabel {
  if (appCommit.isEmpty) return 'Build locale (sviluppo)';
  final date = appBuildDate.isEmpty ? '' : ' del ${_formatIsoDate(appBuildDate)}';
  final channel = appChannel == 'develop' ? ' · anteprima' : '';
  return '$appCommit$date$channel';
}

String _formatIsoDate(String iso) {
  final parts = iso.split('-');
  return parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : iso;
}

/// Il controllo aggiornamenti ha senso solo per la webapp pubblicata.
bool get canCheckForUpdates => kIsWeb && appCommit.isNotEmpty;

/// Commit dell'ultima versione pubblicata sul sito, letto da
/// `build_info.json` (scritto dal deploy e mai messo in cache).
/// Restituisce null fuori dal web, in una build locale o se il file non è
/// raggiungibile.
Future<String?> fetchLatestCommit() async {
  if (!canCheckForUpdates) return null;
  try {
    final url = Uri.base.resolve('build_info.json').replace(
      queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
    );
    final response = await http.get(url);
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['commit'] as String?;
  } catch (_) {
    return null;
  }
}
