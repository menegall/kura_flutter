import 'package:flutter/widgets.dart';

/// Schede del menu principale.
class AppTab {
  static const pupils = 0;
  static const stats = 1;
  static const settings = 2;
}

/// Scheda attiva del menu principale. Le pagine la cambiano per portare
/// l'utente in un'altra sezione (es. "Rivedi il tutorial" torna ai Pupilli).
final ValueNotifier<int> currentAppTab = ValueNotifier(AppTab.pupils);

/// Incrementato a ogni cambio di scheda: Pupilli, Statistiche e Impostazioni
/// restano in vita in background e lo ascoltano per ricaricare i dati che
/// potrebbero essere cambiati nelle altre schede.
final ValueNotifier<int> appDataRefresh = ValueNotifier(0);

/// Chiavi degli elementi evidenziati dal tutorial guidato.
class TourKeys {
  static final addPupil = GlobalKey(debugLabel: 'tour-add-pupil');
  static final addActivity = GlobalKey(debugLabel: 'tour-add-activity');
  static final statsTab = GlobalKey(debugLabel: 'tour-stats-tab');
  static final settingsTab = GlobalKey(debugLabel: 'tour-settings-tab');
}
