import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../models/pupil_model.dart';
import '../models/activity_model.dart';
import '../services/pupils_service.dart';
import 'add_activity_page.dart';
import 'edit_pupil_page.dart';

class PupilDetailPage extends StatefulWidget {
  final Pupil pupil;
  const PupilDetailPage({super.key, required this.pupil});
  @override
  State<PupilDetailPage> createState() => _PupilDetailPageState();
}

class _PupilDetailPageState extends State<PupilDetailPage> {
  final _pupilsService = PupilsService();
  late Pupil _pupil;
  List<Activity>? _activities;
  bool _isLoading = false;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _pupil = widget.pupil;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final updatedPupil = await _pupilsService.getPupilById(_pupil.id);
      final list = await _pupilsService.getRecentActivities(_pupil.id);
      setState(() {
        _pupil = updatedPupil;
        _activities = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossibile caricare i dati. Riprova più tardi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddActivity() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddActivityPage(pupil: _pupil)),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToEditPupil() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => EditPupilPage(pupil: _pupil)),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcolo della percentuale
    final double rawPercent = _pupil.maxHours > 0
        ? (_pupil.workedHours / _pupil.maxHours)
        : 0.0;
    final double percent = rawPercent.clamp(0.0, 1.0);
    final double remainingHours = _pupil.maxHours - _pupil.workedHours;
    Color progressColor;
    if (rawPercent >= 1.0) {
      progressColor = AppColors.terraCotta;
    } else if (rawPercent >= 0.8) {
      progressColor = AppColors.blueGrey;
    } else {
      progressColor = AppColors.darkGreen;
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 750;
    return Scaffold(
      appBar: AppBar(
        title: Text(_pupil.name),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPupil,
            tooltip: 'Modifica',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: _isLoading && _activities == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terraCotta),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.terraCotta),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sinistra: Statistiche e Tariffe
                        Expanded(
                          flex: 5,
                          child: _buildStatsCard(
                            percent,
                            progressColor,
                            remainingHours,
                            rawPercent,
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Destra: Attività Recenti
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildRecentActivitiesHeader(),
                              const SizedBox(height: 12),
                              _buildRecentActivitiesList(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatsCard(
                          percent,
                          progressColor,
                          remainingHours,
                          rawPercent,
                        ),
                        const SizedBox(height: 24),
                        _buildRecentActivitiesHeader(),
                        const SizedBox(height: 12),
                        _buildRecentActivitiesList(),
                      ],
                    ),
            ),
      floatingActionButton: _activities != null && _activities!.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddActivity,
              backgroundColor: AppColors.terraCotta,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildStatsCard(
    double percent,
    Color progressColor,
    double remainingHours,
    double rawPercent,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.beige, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Resoconto Ore',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ore svolte quest\'anno:',
                  style: TextStyle(color: AppColors.blueGrey),
                ),
                Text(
                  '${formatDuration(_pupil.workedHours)} / ${formatDuration(_pupil.maxHours)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: AppColors.beige,
                color: progressColor,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              rawPercent >= 1.0
                  ? 'Ore esaurite!'
                  : '${formatDuration(remainingHours)} rimanenti',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: rawPercent >= 1.0
                    ? AppColors.terraCotta
                    : AppColors.blueGrey,
              ),
            ),
            const Divider(height: 32, color: AppColors.beige),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tariffa Oraria',
                      style: TextStyle(fontSize: 12, color: AppColors.blueGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_pupil.tarif.toStringAsFixed(2)} CHF/h',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tariffa Kilometrica',
                      style: TextStyle(fontSize: 12, color: AppColors.blueGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_pupil.kmTarif.toStringAsFixed(2)} CHF/km',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Attività Recenti',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGreen,
          ),
        ),
        TextButton.icon(
          onPressed: _navigateToAddActivity,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Aggiungi'),
          style: TextButton.styleFrom(foregroundColor: AppColors.terraCotta),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesList() {
    return _activities == null || _activities!.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities!.length,
            itemBuilder: (context, index) {
              final activity = _activities![index];
              return _buildActivityItem(activity);
            },
          );
  }

  Widget _buildActivityItem(Activity activity) {
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
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.beige, width: 0.8),
      ),
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.beige.withValues(alpha: 0.5),
          foregroundColor: AppColors.darkGreen,
          child: Icon(iconData),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              activity.typeLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: AppColors.blueGrey),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.description != null &&
                activity.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.description!,
                style: const TextStyle(color: AppColors.darkGreen),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: [
                if (activity.duration != null)
                  _buildBadge(
                    Icons.access_time,
                    formatDuration(activity.duration!),
                  ),
                if (activity.kilometers != null)
                  _buildBadge(
                    Icons.map_outlined,
                    '${activity.kilometers!.toStringAsFixed(1)} km',
                  ),
                if (activity.stamp != null)
                  _buildBadge(
                    Icons.local_post_office_outlined,
                    '${activity.stamp!.toStringAsFixed(2)} CHF',
                  ),
                if (activity.otherExpenses != null)
                  _buildBadge(
                    Icons.monetization_on_outlined,
                    'Spese: ${activity.otherExpenses!.toStringAsFixed(2)} CHF',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.beige, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.blueGrey),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.blueGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.beige, width: 0.8),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_late_outlined,
            size: 48,
            color: AppColors.blueGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna attività registrata',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inserisci la prima attività lavorativa per questo pupillo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.blueGrey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _navigateToAddActivity,
            icon: const Icon(Icons.add),
            label: const Text('Registra Attività'),
          ),
        ],
      ),
    );
  }
}
