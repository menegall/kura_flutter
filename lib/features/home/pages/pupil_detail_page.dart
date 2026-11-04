import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/hours_progress.dart';
import '../../../core/widgets/activity_badge.dart';
import '../models/pupil_model.dart';
import '../models/activity_model.dart';
import '../services/pupils_service.dart';
import '../widgets/archive_pupil_dialog.dart';
import 'add_activity_page.dart';
import 'edit_pupil_page.dart';
import 'activity_detail_page.dart';
import 'stats_page.dart';

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

  Future<void> _archivePupil() async {
    final confirm = await confirmArchivePupil(context, _pupil);
    if (!confirm) return;
    try {
      await _pupilsService.setPupilArchived(_pupil.id, true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_pupil.name} archiviato. Lo trovi nelle Impostazioni.'),
          backgroundColor: AppColors.darkGreen,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Errore archiviazione pupillo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Non è stato possibile archiviare il pupillo. Controlla la connessione e riprova.'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
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
          PopupMenuButton<String>(
            tooltip: 'Altre azioni',
            onSelected: (value) {
              if (value == 'refresh') _loadData();
              if (value == 'archive') _archivePupil();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Aggiorna'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Archivia pupillo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                          child: _buildStatsCard(),
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
                        _buildStatsCard(),
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

  Widget _buildStatsCard() {
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
            HoursProgress(
              workedHours: _pupil.workedHours,
              maxHours: _pupil.maxHours,
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
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _openStats,
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('Statistiche, PDF e CSV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkGreen,
                side: const BorderSide(color: AppColors.darkGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => StatsPage(initialPupilId: _pupil.id)),
    );
  }

  Widget _buildRecentActivitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Attività',
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

  // Attività raggruppate per mese (già ordinate dalla più recente), con il
  // totale delle ore del mese nell'intestazione.
  Widget _buildRecentActivitiesList() {
    if (_activities == null || _activities!.isEmpty) return _buildEmptyState();
    final children = <Widget>[];
    for (final group in groupActivitiesByMonth(_activities!)) {
      children.add(_buildMonthHeader(group));
      children.addAll(group.activities.map(_buildActivityItem));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildMonthHeader(MonthGroup group) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${italianMonths[group.month - 1]} ${group.year}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
          ),
          Text(
            formatDuration(group.totalHours),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Activity activity) {
    final formattedDate = formatDate(activity.activityDate);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.beige, width: 0.8),
      ),
      elevation: 0,
      child: ListTile(
        onTap: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => ActivityDetailPage(
                activity: activity,
                pupilName: _pupil.name,
              ),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.beige.withValues(alpha: 0.5),
          foregroundColor: AppColors.darkGreen,
          child: Icon(activity.icon),
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
                  ActivityBadge(
                    Icons.access_time,
                    formatDuration(activity.duration!),
                  ),
                if (activity.kilometers != null)
                  ActivityBadge(
                    Icons.map_outlined,
                    '${activity.kilometers!.toStringAsFixed(1)} km',
                  ),
                if (activity.stamp != null)
                  ActivityBadge(
                    Icons.local_post_office_outlined,
                    '${activity.stamp!.toStringAsFixed(2)} CHF',
                  ),
                if (activity.otherExpenses != null)
                  ActivityBadge(
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
