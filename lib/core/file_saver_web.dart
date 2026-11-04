import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> saveTextFile(String fileName, String content, {required String mimeType}) async {
  final bytes = utf8.encode(content);
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
