import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../models/activity_model.dart';

/// Valori inseriti nel form di un'attività, pronti per il salvataggio.
class ActivityFormData {
  final DateTime date;
  final String type;
  final double? duration;
  final String description;
  final double? kilometers;
  final double? stamp;
  final double? otherExpenses;

  const ActivityFormData({
    required this.date,
    required this.type,
    required this.duration,
    required this.description,
    required this.kilometers,
    required this.stamp,
    required this.otherExpenses,
  });
}

/// Form condiviso da "Registra attività" e "Modifica attività".
///
/// Ordine pensato per l'inserimento veloce: tipo e durata (obbligatori) in
/// alto con scelte rapide, poi data, note e infine km e spese, che restano
/// nascosti finché non servono (i km sono sempre visibili per le trasferte).
class ActivityForm extends StatefulWidget {
  final Activity? initial;
  final bool requireDuration;
  final String submitLabel;
  final Future<void> Function(ActivityFormData data) onSubmit;

  const ActivityForm({
    super.key,
    this.initial,
    this.requireDuration = true,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  static const _quickDurations = [15, 30, 45, 60, 90, 120];

  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _kilometersController = TextEditingController();
  final _stampController = TextEditingController();
  final _otherExpensesController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedType;
  bool _showExtras = false;
  bool _isSaving = false;
  String? _durationError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _selectedDate = initial?.activityDate ?? DateTime.now();
    _selectedType = initial?.type ?? Activity.types.first;
    if (initial == null) return;
    if (initial.duration != null) {
      _setDurationMinutes((initial.duration! * 60).round());
    }
    _descriptionController.text = initial.description ?? '';
    _kilometersController.text = _formatNumber(initial.kilometers);
    _stampController.text = _formatNumber(initial.stamp);
    _otherExpensesController.text = _formatNumber(initial.otherExpenses);
    _showExtras = initial.kilometers != null || initial.otherExpenses != null;
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

  String _formatNumber(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
  }

  int get _durationMinutes {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    return hours * 60 + minutes;
  }

  void _setDurationMinutes(int total) {
    final hours = total ~/ 60;
    final minutes = total % 60;
    _hoursController.text = hours > 0 ? '$hours' : '';
    _minutesController.text = minutes > 0 ? '$minutes' : '';
  }

  String _quickLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diff = today.difference(day).inDays;
    final formatted = formatDate(_selectedDate);
    if (diff == 0) return 'Oggi, $formatted';
    if (diff == 1) return 'Ieri, $formatted';
    return formatted;
  }

  Future<void> _submit() async {
    final minutes = _durationMinutes;
    setState(() {
      _durationError = widget.requireDuration && minutes == 0
          ? 'Indica quanto tempo hai impiegato.'
          : null;
    });
    final fieldsValid = _formKey.currentState!.validate();
    if (!fieldsValid || _durationError != null) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        ActivityFormData(
          date: _selectedDate,
          type: _selectedType,
          duration: minutes > 0 ? minutes / 60.0 : null,
          description: _descriptionController.text.trim(),
          kilometers: parseDecimal(_kilometersController.text),
          stamp: _selectedType == 'mail' ? parseDecimal(_stampController.text) : null,
          otherExpenses: parseDecimal(_otherExpensesController.text),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateAmount(String? value, String message) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = parseDecimal(value);
    if (parsed == null || parsed < 0) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isTransfer = _selectedType == 'transfert';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Tipo di attività'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in Activity.types) _buildTypeChip(type),
            ],
          ),
          const SizedBox(height: 28),
          _sectionTitle(widget.requireDuration ? 'Durata' : 'Durata (facoltativa)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final minutes in _quickDurations) _buildDurationChip(minutes),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Ore',
                    prefixIcon: Icon(Icons.access_time, color: AppColors.blueGrey),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _durationError = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _minutesController,
                  decoration: const InputDecoration(
                    labelText: 'Minuti',
                    prefixIcon: Icon(Icons.timer_outlined, color: AppColors.blueGrey),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _durationError = null),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed != null && parsed >= 60) return 'Da 0 a 59';
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (_durationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _durationError!,
              style: const TextStyle(color: AppColors.terraCotta, fontSize: 13),
            ),
          ],
          const SizedBox(height: 28),
          _sectionTitle('Data'),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.blueGrey, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.blueGrey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateLabel,
                      style: const TextStyle(fontSize: 16, color: AppColors.darkGreen),
                    ),
                  ),
                  const Text(
                    'Cambia',
                    style: TextStyle(color: AppColors.terraCotta, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          _sectionTitle('Note (facoltative)'),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Es: colloquio con la banca per il conto',
              prefixIcon: Icon(Icons.description_outlined, color: AppColors.blueGrey),
            ),
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
          if (isTransfer) ...[
            _buildKilometersField(),
            const SizedBox(height: 20),
          ],
          if (_selectedType == 'mail') ...[
            TextFormField(
              controller: _stampController,
              decoration: const InputDecoration(
                labelText: 'Costo francobolli (CHF)',
                hintText: 'Es: 1,20',
                prefixIcon: Icon(Icons.local_post_office_outlined, color: AppColors.blueGrey),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _validateAmount(value, 'Inserisci un importo valido'),
            ),
            const SizedBox(height: 20),
          ],
          if (_showExtras) ...[
            if (!isTransfer) ...[
              _buildKilometersField(),
              const SizedBox(height: 20),
            ],
            TextFormField(
              controller: _otherExpensesController,
              decoration: const InputDecoration(
                labelText: 'Altre spese (CHF)',
                hintText: 'Es: 15,00',
                prefixIcon: Icon(Icons.monetization_on_outlined, color: AppColors.blueGrey),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => _validateAmount(value, 'Inserisci un importo valido'),
            ),
            const SizedBox(height: 20),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showExtras = true),
                icon: const Icon(Icons.add),
                label: Text(isTransfer ? 'Aggiungi altre spese' : 'Aggiungi km o spese'),
                style: TextButton.styleFrom(foregroundColor: AppColors.terraCotta),
              ),
            ),
          const SizedBox(height: 16),
          _isSaving
              ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
              : ElevatedButton(
                  onPressed: _submit,
                  child: Text(widget.submitLabel),
                ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.darkGreen,
        ),
      ),
    );
  }

  Widget _buildKilometersField() {
    return TextFormField(
      controller: _kilometersController,
      decoration: const InputDecoration(
        labelText: 'Km percorsi',
        hintText: 'Es: 15,5',
        prefixIcon: Icon(Icons.map_outlined, color: AppColors.blueGrey),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) => _validateAmount(value, 'Inserisci un numero valido di km'),
    );
  }

  Widget _buildTypeChip(String type) {
    final selected = _selectedType == type;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      avatar: Icon(
        Activity.iconFor(type),
        size: 20,
        color: selected ? Colors.white : AppColors.darkGreen,
      ),
      label: Text(Activity.labelFor(type)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.darkGreen,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.darkGreen,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.darkGreen : AppColors.beige, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      onSelected: (_) => setState(() {
        _selectedType = type;
        // Lasciando una trasferta con i km già compilati, il campo si
        // sposta nella sezione spese: va mostrata per non nasconderlo.
        if (_kilometersController.text.isNotEmpty) _showExtras = true;
      }),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final selected = _durationMinutes == minutes;
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text(_quickLabel(minutes)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.darkGreen,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.terraCotta,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.terraCotta : AppColors.beige, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      onSelected: (_) => setState(() {
        _setDurationMinutes(minutes);
        _durationError = null;
      }),
    );
  }
}
