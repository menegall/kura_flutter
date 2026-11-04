import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils.dart';

/// Barra delle ore svolte rispetto al monte ore annuale, con l'etichetta
/// delle ore rimanenti. Oltre l'80% passa al colore di avviso, al 100% al
/// colore di errore.
class HoursProgress extends StatelessWidget {
  final double workedHours;
  final double maxHours;
  final Widget? trailing;

  const HoursProgress({
    super.key,
    required this.workedHours,
    required this.maxHours,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxHours > 0 ? workedHours / maxHours : 0.0;
    final remaining = maxHours - workedHours;

    final Color color;
    final String label;
    if (ratio >= 1.0) {
      color = AppColors.terraCotta;
      label = 'Ore esaurite!';
    } else if (ratio >= 0.8) {
      color = AppColors.amber;
      label = 'Attenzione: restano ${formatDuration(remaining)}';
    } else {
      color = AppColors.darkGreen;
      label = '${formatDuration(remaining)} rimanenti';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: AppColors.beige,
            color: color,
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ratio >= 0.8 ? FontWeight.bold : FontWeight.w500,
                  color: ratio >= 0.8 ? color : AppColors.blueGrey,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ],
    );
  }
}
