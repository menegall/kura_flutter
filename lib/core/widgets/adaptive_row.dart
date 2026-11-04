import 'package:flutter/material.dart';

/// Testo ingrandito (accessibilità) oltre il quale gli elementi affiancati
/// vanno messi uno sotto l'altro.
const double largeTextScale = 1.3;

/// True se l'utente ha ingrandito il testo oltre [largeTextScale].
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > largeTextScale;

/// Una [Row] (es. due campi tariffa affiancati) che con il testo ingrandito
/// diventa una colonna, così le etichette restano leggibili. Accetta gli
/// stessi figli di una Row: in colonna gli [Expanded]/[Flexible] vengono
/// tolti e gli spaziatori orizzontali diventano verticali.
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const AdaptiveRow({super.key, required this.children, this.spacing = 16});

  @override
  Widget build(BuildContext context) {
    if (!isLargeText(context)) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final child in children)
          if (child is SizedBox && child.child == null)
            SizedBox(height: spacing)
          else if (child is Flexible)
            child.child
          else
            child,
      ],
    );
  }
}
