import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../services/pupils_service.dart';
class AddPupilPage extends StatefulWidget {
  const AddPupilPage({super.key});
  @override
  State<AddPupilPage> createState() => _AddPupilPageState();
}
class _AddPupilPageState extends State<AddPupilPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hoursController = TextEditingController();
  final _tarifController = TextEditingController();
  final _kmTarifController = TextEditingController();
  final _pupilsService = PupilsService();
  bool _isLoading = false;
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final maxHours = double.parse(_hoursController.text.trim());
      final tarif = double.parse(_tarifController.text.trim());
      final kmTarif = double.parse(_kmTarifController.text.trim());
      await _pupilsService.addPupil(
        name: name,
        maxHours: maxHours,
        tarif: tarif,
        kmTarif: kmTarif,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante il salvataggio del pupillo.'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Pupillo'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Aggiungi un Pupillo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Imposta i dati principali, le tariffe e il budget di ore massimo.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.blueGrey,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome e Cognome',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.blueGrey),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci un nome valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Numero Massimo Ore (all\'anno)',
                    prefixIcon: Icon(Icons.av_timer_outlined, color: AppColors.blueGrey),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci le ore massime';
                    }
                    final hours = double.tryParse(value.trim());
                    if (hours == null || hours <= 0) {
                      return 'Inserisci un numero maggiore di 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tarifController,
                        decoration: const InputDecoration(
                          labelText: 'Tariffa Oraria (CHF/h)',
                          prefixIcon: Icon(Icons.attach_money, color: AppColors.blueGrey),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci tariffa';
                          }
                          final rate = double.tryParse(value.trim());
                          if (rate == null || rate < 0) {
                            return 'Minimo 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _kmTarifController,
                        decoration: const InputDecoration(
                          labelText: 'Tariffa Km (CHF/km)',
                          prefixIcon: Icon(Icons.directions_car_outlined, color: AppColors.blueGrey),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci tariffa km';
                          }
                          final rate = double.tryParse(value.trim());
                          if (rate == null || rate < 0) {
                            return 'Minimo 0';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
                    : ElevatedButton(
                        onPressed: _save,
                        child: const Text('Salva Pupillo'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
