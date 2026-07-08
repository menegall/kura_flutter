import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../models/activity_model.dart';

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;
  final String pupilName;
  const ActivityDetailPage({
    super.key,
    required this.activity,
    required this.pupilName,
  });
  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (activity.type) {
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
        '${activity.activityDate.day.toString().padLeft(2, '0')}/${activity.activityDate.month.toString().padLeft(2, '0')}/${activity.activityDate.year}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Attività'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
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
                    backgroundColor: AppColors.beige.withValues(alpha: 0.5),
                    foregroundColor: AppColors.darkGreen,
                    child: Icon(iconData, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.typeLabel,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pupillo: $pupilName',
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
              const Divider(height: 40, color: AppColors.beige, thickness: 1.5),
              // Dettagli in Card
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.beige, width: 1),
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
                      if (activity.duration != null) ...[
                        const Divider(height: 24, color: AppColors.beige),
                        _buildDetailRow(
                          Icons.access_time,
                          'Tempo impiegato',
                          formatDuration(activity.duration!),
                        ),
                      ],
                      // Kilometri - se presenti
                      if (activity.kilometers != null) ...[
                        const Divider(height: 24, color: AppColors.beige),
                        _buildDetailRow(
                          Icons.map_outlined,
                          'Distanza percorsa',
                          '${activity.kilometers!.toStringAsFixed(1)} km',
                        ),
                      ],
                      // Francobolli - se presenti
                      if (activity.stamp != null) ...[
                        const Divider(height: 24, color: AppColors.beige),
                        _buildDetailRow(
                          Icons.local_post_office_outlined,
                          'Spesa francobolli',
                          '${activity.stamp!.toStringAsFixed(2)} CHF',
                        ),
                      ],
                      // Altre Spese - se presenti
                      if (activity.otherExpenses != null) ...[
                        const Divider(height: 24, color: AppColors.beige),
                        _buildDetailRow(
                          Icons.monetization_on_outlined,
                          'Altre spese',
                          '${activity.otherExpenses!.toStringAsFixed(2)} CHF',
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
                  (activity.description != null &&
                          activity.description!.trim().isNotEmpty)
                      ? activity.description!
                      : 'Nessuna descrizione o nota inserita per questa attività.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color:
                        (activity.description != null &&
                            activity.description!.trim().isNotEmpty)
                        ? AppColors.darkGreen
                        : AppColors.blueGrey.withValues(alpha: 0.8),
                    fontStyle:
                        (activity.description != null &&
                            activity.description!.trim().isNotEmpty)
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ),
            ],
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
