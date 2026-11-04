import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/activity_model.dart';
import '../services/pupils_service.dart';
import '../widgets/activity_form.dart';

class EditActivityPage extends StatefulWidget {
  final Activity activity;
  final String pupilName;
  const EditActivityPage({
    super.key,
    required this.activity,
    required this.pupilName,
  });
  @override
  State<EditActivityPage> createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage> {
  final _pupilsService = PupilsService();

  Future<void> _save(ActivityFormData data) async {
    try {
      await _pupilsService.updateActivity(
        id: widget.activity.id,
        activityDate: data.date,
        type: data.type,
        duration: data.duration,
        description: data.description,
        kilometers: data.kilometers,
        stamp: data.stamp,
        otherExpenses: data.otherExpenses,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attività aggiornata con successo!'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // Ritorna true per indicare che c'è stata una modifica
      }
    } catch (e) {
      debugPrint('Errore aggiornamento attività: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Non è stato possibile salvare le modifiche. Controlla la connessione e riprova.'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Attività'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.pupilName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 24),
              // La durata resta facoltativa in modifica: alcune attività
              // registrate in passato non ce l'hanno.
              ActivityForm(
                initial: widget.activity,
                requireDuration: false,
                submitLabel: 'Salva Modifiche',
                onSubmit: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
