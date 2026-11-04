import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/pupil_model.dart';

/// Chiede conferma prima di archiviare un pupillo. Restituisce true se
/// l'utente conferma.
Future<bool> confirmArchivePupil(BuildContext context, Pupil pupil) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Archiviare ${pupil.name}?'),
      content: const Text(
        'Il pupillo non comparirà più nella Home, ma tutte le sue attività '
        'restano salvate e disponibili nelle statistiche. Puoi ripristinarlo '
        'quando vuoi dalle Impostazioni.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla', style: TextStyle(color: AppColors.blueGrey)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Archivia'),
        ),
      ],
    ),
  );
  return confirm == true;
}
