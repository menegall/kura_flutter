import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'install_platform.dart';

// Evento `beforeinstallprompt` salvato da web/index.html prima che Flutter
// parta (Chrome/Edge su Android e PC). Safari non lo supporta.
extension type _InstallPromptEvent._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prompt();
  external JSPromise<_UserChoice> get userChoice;
}

extension type _UserChoice._(JSObject _) implements JSObject {
  external String get outcome;
}

@JS('kuraInstallPrompt')
external _InstallPromptEvent? get _deferredPrompt;

@JS('kuraInstallPrompt')
external set _deferredPrompt(_InstallPromptEvent? value);

const _dismissedKey = 'kura_install_banner_dismissed';

/// True quando il browser permette di installare l'app con un pulsante.
final ValueNotifier<bool> installPromptAvailable = ValueNotifier(false);
bool _listening = false;

void _ensureListening() {
  if (_listening) return;
  _listening = true;
  installPromptAvailable.value = _deferredPrompt != null;
  web.window.addEventListener(
    'beforeinstallprompt',
    ((web.Event _) => installPromptAvailable.value = true).toJS,
  );
  web.window.addEventListener(
    'appinstalled',
    ((web.Event _) {
      installPromptAvailable.value = false;
      dismissInstallBanner();
    }).toJS,
  );
}

bool _isStandalone() {
  if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
  // Safari su iPhone/iPad espone navigator.standalone per le app sulla Home.
  final standalone = (web.window.navigator as JSObject).getProperty<JSAny?>('standalone'.toJS);
  return standalone.dartify() == true;
}

/// Dispositivo per cui mostrare il banner, oppure null se l'app è già
/// aperta come app installata.
InstallPlatform? installPlatform() {
  _ensureListening();
  if (_isStandalone()) return null;
  final navigator = web.window.navigator;
  final ua = navigator.userAgent;
  // Gli iPad recenti si presentano come Mac: si distinguono dal touch.
  final isIOS = RegExp(r'iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && navigator.maxTouchPoints > 1);
  if (isIOS) return InstallPlatform.ios;
  if (ua.contains('Android')) return InstallPlatform.android;
  return InstallPlatform.desktop;
}

bool isInstallBannerDismissed() {
  try {
    return web.window.localStorage.getItem(_dismissedKey) != null;
  } catch (_) {
    return false;
  }
}

void dismissInstallBanner() {
  try {
    web.window.localStorage.setItem(_dismissedKey, '1');
  } catch (_) {}
}

/// Mostra il prompt di installazione del browser. True se l'utente accetta.
Future<bool> promptInstall() async {
  final event = _deferredPrompt;
  if (event == null) return false;
  await event.prompt().toDart;
  final choice = await event.userChoice.toDart;
  // L'evento si può usare una sola volta.
  _deferredPrompt = null;
  installPromptAvailable.value = false;
  return choice.outcome == 'accepted';
}
