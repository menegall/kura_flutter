import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../models/activity_model.dart';
import '../services/pupils_service.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _pupilsService = PupilsService();
  bool _isLoading = false;
  late DateTime _selectedDate;
  late String _selectedType;
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _kilometersController = TextEditingController();
  final _stampController = TextEditingController();
  final _otherExpensesController = TextEditingController();
  final List<Map<String, String>> _activityTypes = [
    {'value': 'call', 'label': 'Telefonata'},
    {'value': 'meeting_pupils', 'label': 'Incontro con Pupillo'},
    {'value': 'meeting_various', 'label': 'Incontro Varie'},
    {'value': 'mail', 'label': 'Email/Lettera'},
    {'value': 'transfert', 'label': 'Trasferta'},
    {'value': 'other', 'label': 'Altro'},
  ];
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.activity.activityDate;
    _selectedType = widget.activity.type;
    // Popola i campi orari
    if (widget.activity.duration != null) {
      final double duration = widget.activity.duration!;
      final int h = duration.floor();
      final int m = ((duration - h) * 60).round();
      _hoursController.text = h > 0 ? h.toString() : '';
      _minutesController.text = m > 0 ? m.toString() : '';
    }
    _descriptionController.text = widget.activity.description ?? '';
    _kilometersController.text = widget.activity.kilometers != null
        ? widget.activity.kilometers!.toStringAsFixed(1)
        : '';
    _stampController.text = widget.activity.stamp != null
        ? widget.activity.stamp!.toStringAsFixed(2)
        : '';
    _otherExpensesController.text = widget.activity.otherExpenses != null
        ? widget.activity.otherExpenses!.toStringAsFixed(2)
        : '';
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _descriptionController.dispose();
    _kilometersController.dispose();
    _stampController.dispose();
    _otherExpensesController.dispose();
    super.dispose();
  }

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
      // Calcolo della durata in ore decimale
      final int hours = _hoursController.text.isNotEmpty
          ? int.parse(_hoursController.text.trim())
          : 0;
      final int minutes = _minutesController.text.isNotEmpty
          ? int.parse(_minutesController.text.trim())
          : 0;

      double? duration;
      if (hours > 0 || minutes > 0) {
        duration = hours + (minutes / 60.0);
      }
      final double? kilometers =
          _selectedType == 'transfert' && _kilometersController.text.isNotEmpty
          ? double.tryParse(_kilometersController.text.trim())
          : null;
      final double? stamp =
          _selectedType == 'mail' && _stampController.text.isNotEmpty
          ? double.tryParse(_stampController.text.trim())
          : null;
      final double? otherExpenses = _otherExpensesController.text.isNotEmpty
          ? double.tryParse(_otherExpensesController.text.trim())
          : null;
      await _pupilsService.updateActivity(
        id: widget.activity.id,
        activityDate: _selectedDate,
        type: _selectedType,
        duration: duration,
        description: _descriptionController.text.trim(),
        kilometers: kilometers,
        stamp: stamp,
        otherExpenses: otherExpenses,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'aggiornamento: $e'),
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
        title: const Text('Modifica Attività'),
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
                  'Modifica attività per ${widget.pupilName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 24),
                // Scelta Data
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.beige, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: AppColors.blueGrey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Data prestazione: $formattedDate',
                              style: const TextStyle(
                                fontSize: 15,
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
                // Scelta Tipo Attività
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo di attività',
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
                // Nota / Descrizione
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione / Note',
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      color: AppColors.blueGrey,
                    ),
                    hintText:
                        'Es: Colloquio telefonico con l\'assistente sociale',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                // Sezione Inserimento Tempo (Ore e Minuti)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
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
                              return 'Inserisci un numero';
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
                            if (parsed == null || parsed < 0 || parsed >= 60) {
                              return 'Inserisci tra 0 e 59';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Campo Km (solo per Trasferta)
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
                          return 'Inserisci un numero valido';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                // Campo Francobolli (solo per Email/Lettera)
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
                // Campo Altre Spese (opzionale per qualsiasi attività)
                TextFormField(
                  controller: _otherExpensesController,
                  decoration: const InputDecoration(
                    labelText: 'Altre Spese (CHF) - Opzionale',
                    prefixIcon: Icon(
                      Icons.monetization_on_outlined,
                      color: AppColors.blueGrey,
                    ),
                    hintText: 'Es: 15.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed < 0) {
                        return 'Inserisci un importo valido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.terraCotta,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _save,
                        child: const Text('Salva Modifiche'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
