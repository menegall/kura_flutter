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

/// Ogni scheda ha il proprio navigatore: le pagine di dettaglio (pupillo,
/// attività) si aprono dentro la scheda e il menu in basso resta visibile.
/// I form si aprono invece sul navigatore principale, a schermo intero.
final List<GlobalKey<NavigatorState>> tabNavigatorKeys = [
  GlobalKey(debugLabel: 'tab-pupils'),
  GlobalKey(debugLabel: 'tab-stats'),
  GlobalKey(debugLabel: 'tab-settings'),
];

/// Riporta una scheda alla sua pagina principale.
void resetTabToRoot(int tab) =>
    tabNavigatorKeys[tab].currentState?.popUntil((route) => route.isFirst);

/// Pupillo da selezionare nella scheda Statistiche (letto e azzerato dalla
/// pagina Statistiche).
final ValueNotifier<String?> requestedStatsPupilId = ValueNotifier(null);

/// Passa alla scheda Statistiche mostrando il pupillo indicato.
void openStatsForPupil(String pupilId) {
  requestedStatsPupilId.value = pupilId;
  resetTabToRoot(AppTab.stats);
  currentAppTab.value = AppTab.stats;
}

/// Chiavi degli elementi evidenziati dal tutorial guidato.
class TourKeys {
  static final addPupil = GlobalKey(debugLabel: 'tour-add-pupil');
  static final addActivity = GlobalKey(debugLabel: 'tour-add-activity');
  static final statsTab = GlobalKey(debugLabel: 'tour-stats-tab');
  static final settingsTab = GlobalKey(debugLabel: 'tour-settings-tab');
}
