import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/pupil_model.dart';
import '../services/pupils_service.dart';
import '../widgets/activity_form.dart';

class AddActivityPage extends StatefulWidget {
  final Pupil pupil;
  const AddActivityPage({super.key, required this.pupil});
  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _pupilsService = PupilsService();

  Future<void> _save(ActivityFormData data) async {
    try {
      await _pupilsService.addActivity(
        pupilId: widget.pupil.id,
        activityDate: data.date,
        type: data.type,
        duration: data.duration,
        description: data.description,
        kilometers: data.kilometers,
        stamp: data.stamp,
        otherExpenses: data.otherExpenses,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Errore salvataggio attività: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Non è stato possibile salvare l\'attività. Controlla la connessione e riprova.'),
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
        title: const Text('Registra Attività'),
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
                widget.pupil.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                ),
              ),
              const SizedBox(height: 24),
              ActivityForm(
                submitLabel: 'Salva Attività',
                onSubmit: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
