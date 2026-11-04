import 'dart:convert';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveTextFile(String fileName, String content, {required String mimeType}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(utf8.encode(content));
  await OpenFilex.open(file.path, type: mimeType);
}
