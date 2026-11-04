// Installazione della webapp (PWA): sul web rileva dispositivo e prompt del
// browser, sulle app native non fa nulla.
export 'install_prompt_io.dart' if (dart.library.js_interop) 'install_prompt_web.dart';
