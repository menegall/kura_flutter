import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../models/activity_model.dart';
import '../services/pupils_service.dart';
import 'edit_activity_page.dart';

class ActivityDetailPage extends StatefulWidget {
  final Activity activity;
  final String pupilName;
  const ActivityDetailPage({
    super.key,
    required this.activity,
    required this.pupilName,
  });
  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  final _pupilsService = PupilsService();
  late Activity _activity;
  bool _isLoading = false;
  bool _hasChanges = false;
  @override
  void initState() {
    super.initState();
    _activity = widget.activity;
  }

  Future<void> _reloadActivity() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _pupilsService.getActivityById(_activity.id);
      setState(() {
        _activity = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel ricaricare l\'attività: $e'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editActivity() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            EditActivityPage(activity: _activity, pupilName: widget.pupilName),
      ),
    );
    if (result == true) {
      _hasChanges = true;
      _reloadActivity();
    }
  }

  Future<void> _deleteActivity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Attività'),
        content: const Text(
          'Sei sicuro di voler eliminare questa attività? Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppColors.blueGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Elimina',
              style: TextStyle(
                color: AppColors.terraCotta,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _pupilsService.deleteActivity(_activity.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attività eliminata con successo!'),
              backgroundColor: AppColors.darkGreen,
            ),
          );
          Navigator.of(
            context,
          ).pop(true); // Ritorna true per notificare la cancellazione
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante l\'eliminazione: $e'),
              backgroundColor: AppColors.terraCotta,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (_activity.type) {
      case 'call':
        iconData = Icons.phone_outlined;
        break;
      case 'transfert':
        iconData = Icons.directions_car_outlined;
        break;
      case 'mail':
        iconData = Icons.email_outlined;
        break;
      case 'meeting_various':
        iconData = Icons.groups_outlined;
        break;
      case 'meeting_pupils':
        iconData = Icons.person_search_outlined;
        break;
      case 'other':
      default:
        iconData = Icons.work_outline;
    }
    final formattedDate =
        '${_activity.activityDate.day.toString().padLeft(2, '0')}/${_activity.activityDate.month.toString().padLeft(2, '0')}/${_activity.activityDate.year}';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dettaglio Attività'),
          backgroundColor: AppColors.darkGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanges),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  _editActivity();
                } else if (value == 'delete') {
                  _deleteActivity();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: AppColors.darkGreen),
                      SizedBox(width: 12),
                      Text('Modifica'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.terraCotta),
                      SizedBox(width: 12),
                      Text(
                        'Elimina',
                        style: TextStyle(color: AppColors.terraCotta),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.terraCotta),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header con Icona e Tipo Attività
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.beige.withOpacity(0.5),
                            foregroundColor: AppColors.darkGreen,
                            child: Icon(iconData, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _activity.typeLabel,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pupillo: ${widget.pupilName}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.blueGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        height: 40,
                        color: AppColors.beige,
                        thickness: 1.5,
                      ),
                      // Dettagli in Card
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.beige,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Data
                              _buildDetailRow(
                                Icons.calendar_today_outlined,
                                'Data prestazione',
                                formattedDate,
                              ),

                              // Durata (Tempo) - se presente
                              if (_activity.duration != null) ...[
                                const Divider(
                                  height: 24,
                                  color: AppColors.beige,
                                ),
                                _buildDetailRow(
                                  Icons.access_time,
                                  'Tempo impiegato',
                                  formatDuration(_activity.duration!),
                                ),
                              ],
                              // Kilometri - se presenti
                              if (_activity.kilometers != null) ...[
                                const Divider(
                                  height: 24,
                                  color: AppColors.beige,
                                ),
                                _buildDetailRow(
                                  Icons.map_outlined,
                                  'Distanza percorsa',
                                  '${_activity.kilometers!.toStringAsFixed(1)} km',
                                ),
                              ],
                              // Francobolli - se presenti
                              if (_activity.stamp != null) ...[
                                const Divider(
                                  height: 24,
                                  color: AppColors.beige,
                                ),
                                _buildDetailRow(
                                  Icons.local_post_office_outlined,
                                  'Spesa francobolli',
                                  '${_activity.stamp!.toStringAsFixed(2)} CHF',
                                ),
                              ],
                              // Altre Spese - se presenti
                              if (_activity.otherExpenses != null) ...[
                                const Divider(
                                  height: 24,
                                  color: AppColors.beige,
                                ),
                                _buildDetailRow(
                                  Icons.monetization_on_outlined,
                                  'Altre spese',
                                  '${_activity.otherExpenses!.toStringAsFixed(2)} CHF',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Sezione Descrizione / Note (se presente)
                      const Text(
                        'Descrizione / Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.beige, width: 1),
                        ),
                        child: Text(
                          (_activity.description != null &&
                                  _activity.description!.trim().isNotEmpty)
                              ? _activity.description!
                              : 'Nessuna descrizione o nota inserita per questa attività.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color:
                                (_activity.description != null &&
                                    _activity.description!.trim().isNotEmpty)
                                ? AppColors.darkGreen
                                : AppColors.blueGrey.withOpacity(0.8),
                            fontStyle:
                                (_activity.description != null &&
                                    _activity.description!.trim().isNotEmpty)
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blueGrey, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
