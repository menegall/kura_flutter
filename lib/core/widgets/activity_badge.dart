import 'package:flutter/material.dart';
import '../theme.dart';

/// Piccola "pillola" icona + testo usata sotto le attività
/// (durata, km, francobolli, spese). `dense` per la variante compatta
/// usata nelle liste delle statistiche.
class ActivityBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dense;

  const ActivityBadge(this.icon, this.text, {super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(dense ? 4 : 6),
        border: Border.all(color: AppColors.beige, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 10 : 12, color: AppColors.blueGrey),
          SizedBox(width: dense ? 3 : 4),
          Text(
            text,
            style: TextStyle(
              fontSize: dense ? 9 : 11,
              color: AppColors.blueGrey,
              fontWeight: dense ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
