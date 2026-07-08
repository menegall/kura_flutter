import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/pupil_model.dart';
import '../services/pupils_service.dart';

class AddActivityPage extends StatefulWidget {
  final Pupil pupil;
  const AddActivityPage({super.key, required this.pupil});
  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _kilometersController = TextEditingController();
  final _stampController = TextEditingController();
  final _pupilsService = PupilsService();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'call';
  bool _isLoading = false;
  // Tipi di attività per il database e relative etichette per l'utente in italiano
  final List<Map<String, String>> _activityTypes = [
    {'value': 'call', 'label': 'Telefonata'},
    {'value': 'transfert', 'label': 'Trasferta'},
    {'value': 'mail', 'label': 'Email/Lettera'},
    {'value': 'meeting_various', 'label': 'Incontro Varie'},
    {'value': 'meeting_pupils', 'label': 'Incontro con Pupillo'},
    {'value': 'other', 'label': 'Altro'},
  ];
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.darkGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final hoursText = _hoursController.text.trim();
      final minutesText = _minutesController.text.trim();
      final int hours = hoursText.isNotEmpty
          ? (int.tryParse(hoursText) ?? 0)
          : 0;
      final int minutes = minutesText.isNotEmpty
          ? (int.tryParse(minutesText) ?? 0)
          : 0;
      if (hours == 0 && minutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inserisci la durata dell\'attività (ore o minuti).'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      final double duration = hours + (minutes / 60.0);

      final double? kilometers =
          _selectedType == 'transfert' && _kilometersController.text.isNotEmpty
          ? double.tryParse(_kilometersController.text.trim())
          : null;
      final double? stamp =
          _selectedType == 'mail' && _stampController.text.isNotEmpty
          ? double.tryParse(_stampController.text.trim())
          : null;
      await _pupilsService.addActivity(
        pupilId: widget.pupil.id,
        activityDate: _selectedDate,
        type: _selectedType,
        duration: duration,
        description: _descriptionController.text.trim(),
        kilometers: kilometers,
        stamp: stamp,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante il salvataggio dell\'attività.'),
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
    final formattedDate =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registra Attività'),
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
                Text(
                  widget.pupil.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Compila i campi sottostanti per registrare la prestazione lavorativa.',
                  style: TextStyle(fontSize: 14, color: AppColors.blueGrey),
                ),
                const SizedBox(height: 32),
                // Selettore Data
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blueGrey, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.blueGrey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Dropdown Tipo Attività
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo Attività',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                      color: AppColors.blueGrey,
                    ),
                  ),
                  items: _activityTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type['value'],
                      child: Text(type['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                // Campo Descrizione
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione / Dettagli',
                    prefixIcon: Icon(
                      Icons.description_outlined,
                      color: AppColors.blueGrey,
                    ),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                // Campi Condizionali
                // 1. Campo Tempo
                if (_selectedType != 'transfert') ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _hoursController,
                          decoration: const InputDecoration(
                            labelText: 'Ore impiegate',
                            prefixIcon: Icon(
                              Icons.access_time,
                              color: AppColors.blueGrey,
                            ),
                            hintText: 'Es: 2',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed < 0) {
                                return 'Non valido';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: _minutesController,
                          decoration: const InputDecoration(
                            labelText: 'Minuti impiegati',
                            prefixIcon: Icon(
                              Icons.timer_outlined,
                              color: AppColors.blueGrey,
                            ),
                            hintText: 'Es: 15',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final parsed = int.tryParse(value);
                              if (parsed == null ||
                                  parsed < 0 ||
                                  parsed >= 60) {
                                return 'Inserisci tra 0 e 59';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                // 2. Campo Km (solo per Trasferta)
                if (_selectedType == 'transfert') ...[
                  TextFormField(
                    controller: _kilometersController,
                    decoration: const InputDecoration(
                      labelText: 'Distanza percorsa (Km)',
                      prefixIcon: Icon(
                        Icons.map_outlined,
                        color: AppColors.blueGrey,
                      ),
                      hintText: 'Es: 15.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (_selectedType == 'transfert') {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci i km per la trasferta';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Inserisci un numero valido di km';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                // 3. Campo Francobolli (solo per Email/Lettera)
                if (_selectedType == 'mail') ...[
                  TextFormField(
                    controller: _stampController,
                    decoration: const InputDecoration(
                      labelText: 'Costo Francobolli (CHF)',
                      prefixIcon: Icon(
                        Icons.local_post_office_outlined,
                        color: AppColors.blueGrey,
                      ),
                      hintText: 'Es: 1.20',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed < 0) {
                          return 'Inserisci un costo valido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 12),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.terraCotta,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _save,
                        child: const Text('Salva Attività'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
