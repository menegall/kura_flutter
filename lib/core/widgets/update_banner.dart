import 'package:flutter/material.dart';
import '../app_reload.dart';
import '../app_update.dart';
import '../theme.dart';

/// Avviso "È disponibile un aggiornamento" con le principali novità.
///
/// Controlla all'apertura e ogni volta che l'app torna in primo piano (al
/// massimo ogni 15 minuti): sul telefono l'app installata resta aperta in
/// background anche per giorni. «Aggiorna più tardi» lo nasconde fino alla
/// prossima apertura dell'app.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});
  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  static const _minInterval = Duration(minutes: 15);
  // Valida per tutta la sessione, anche se la pagina viene ricreata.
  static bool _postponed = false;

  UpdateInfo? _update;
  DateTime? _lastCheck;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < _minInterval) return;
    _lastCheck = now;
    final update = await checkForUpdate();
    if (mounted) setState(() => _update = update);
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    if (update == null || _postponed) return const SizedBox.shrink();
    final notes = update.notes.isEmpty ? ['Miglioramenti e correzioni.'] : update.notes;

    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.terraCotta, width: 4),
            bottom: BorderSide(color: AppColors.beige),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.system_update_alt, color: AppColors.terraCotta),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'È disponibile un aggiornamento',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final note in notes)
              Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 4),
                child: Text(
                  '• $note',
                  style: const TextStyle(fontSize: 14, color: AppColors.darkGreen),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _postponed = true),
                  child: const Text('Aggiorna più tardi', style: TextStyle(color: AppColors.blueGrey)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: reloadApp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Aggiorna'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
