import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/constant.dart';
import '../models/pupil_model.dart';
import '../models/activity_model.dart';
import '../services/pupils_service.dart';
import 'activity_detail_page.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _pupilsService = PupilsService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isExporting = false;
  List<Pupil>? _pupils;
  Pupil? _selectedPupil;
  List<Activity>? _allActivities; // Tutte le attività del pupillo selezionato
  List<Activity> _filteredActivities = []; // Attività filtrate per periodo
  // Filtri temporali
  String _selectedPeriod = 'Anno'; // 'Giorno', 'Mese', 'Anno'
  DateTime _selectedDay = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _sortAscending =
      false; // false = più recenti prima (discendente), true = più vecchie prima (crescente)
  // Calcoli delle statistiche
  double _totalHours = 0.0;
  double _callHours = 0.0;
  double _meetingVariousHours = 0.0;
  double _meetingPupilsHours = 0.0;
  double _otherHours = 0.0;
  double _mailHours = 0.0;
  double _totalKm = 0.0;
  double _totalStamps = 0.0;
  double _totalOtherExpenses = 0.0;
  final List<String> _monthsItalian = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];
  final List<int> _years = List.generate(
    10,
    (index) => DateTime.now().year - 5 + index,
  );
  @override
  void initState() {
    super.initState();
    _loadPupils();
  }

  Future<void> _loadPupils() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _pupilsService.getPupils();
      setState(() {
        _pupils = list;
        if (list.isNotEmpty) {
          _selectedPupil = list.first;
          _loadActivitiesForSelectedPupil();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossibile caricare i pupilli. Riprova più tardi.';
      });
    } finally {
      setState(() {
        if (_pupils == null || _pupils!.isEmpty) _isLoading = false;
      });
    }
  }

  Future<void> _loadActivitiesForSelectedPupil() async {
    if (_selectedPupil == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _pupilsService.getRecentActivities(_selectedPupil!.id);
      setState(() {
        _allActivities = list;
        _filterAndCalculate();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossibile caricare le attività del pupillo.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterAndCalculate() {
    if (_allActivities == null) return;
    List<Activity> tempFiltered = [];
    for (var act in _allActivities!) {
      final date = act.activityDate;
      bool matches = false;
      if (_selectedPeriod == 'Giorno') {
        matches =
            date.year == _selectedDay.year &&
            date.month == _selectedDay.month &&
            date.day == _selectedDay.day;
      } else if (_selectedPeriod == 'Mese') {
        matches = date.year == _selectedYear && date.month == _selectedMonth;
      } else if (_selectedPeriod == 'Anno') {
        matches = date.year == _selectedYear;
      }
      if (matches) {
        tempFiltered.add(act);
      }
    }
    // Calcolo metriche
    double tempTotalHours = 0.0;
    double tempCall = 0.0;
    double tempMeetingVarious = 0.0;
    double tempMeetingPupils = 0.0;
    double tempOther = 0.0;
    double tempMail = 0.0;
    double tempKm = 0.0;
    double tempStamps = 0.0;
    double tempOtherExpenses = 0.0;
    for (var act in tempFiltered) {
      final duration = act.duration ?? 0.0;
      final kilometers = act.kilometers ?? 0.0;
      final stamp = act.stamp ?? 0.0;
      final otherExpenses = act.otherExpenses ?? 0.0;

      tempTotalHours += duration;
      tempOtherExpenses += otherExpenses;

      switch (act.type) {
        case 'call':
          tempCall += duration;
          break;
        case 'meeting_various':
          tempMeetingVarious += duration;
          break;
        case 'meeting_pupils':
          tempMeetingPupils += duration;
          break;
        case 'other':
          tempOther += duration;
          break;
        case 'transfert':
          tempKm += kilometers;
          break;
        case 'mail':
          tempMail += duration;
          tempStamps += stamp;
          break;
      }
    }
    // Ordina la lista in base alla preferenza dell'utente
    if (_sortAscending) {
      tempFiltered.sort((a, b) => a.activityDate.compareTo(b.activityDate));
    } else {
      tempFiltered.sort((a, b) => b.activityDate.compareTo(a.activityDate));
    }
    setState(() {
      _filteredActivities = tempFiltered;
      _totalHours = tempTotalHours;
      _callHours = tempCall;
      _meetingVariousHours = tempMeetingVarious;
      _meetingPupilsHours = tempMeetingPupils;
      _otherHours = tempOther;
      _mailHours = tempMail;
      _totalKm = tempKm;
      _totalStamps = tempStamps;
      _totalOtherExpenses = tempOtherExpenses;
    });
  }

  Future<void> _selectDay(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
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
    if (picked != null && picked != _selectedDay) {
      setState(() {
        _selectedDay = picked;
        _filterAndCalculate();
      });
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedPupil == null) return;
    setState(() => _isExporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.terraCotta),
              SizedBox(width: 20),
              Expanded(child: Text("Generazione PDF in corso...")),
            ],
          ),
        );
      },
    );
    try {
      final supabaseClient = Supabase.instance.client;
      final session = supabaseClient.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) throw Exception('Sessione non attiva');
      final projectUrl = SupabaseCredentials.databaseUrl;
      final anonKey = SupabaseCredentials.anonKey;
      final functionUrl = '$projectUrl/functions/v1/generate-stat-pdf';
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'apikey': anonKey,
        },
        body: jsonEncode({
          'pupil_id': _selectedPupil!.id,
          'period_type': _selectedPeriod,
          'year': _selectedYear,
          'month': _selectedMonth,
          'day': _selectedDay.day,
        }),
      );
      // Chiudi il dialog di caricamento
      if (mounted) Navigator.of(context).pop();
      if (response.statusCode != 200) {
        throw Exception(
          'Errore server: ${response.statusCode} - ${response.body}',
        );
      }
      final pdfBytes = response.bodyBytes;
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'statistiche_${_selectedPupil!.name.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        // Chiudi il caricamento se ancora attivo (il dialog è visualizzato prima della chiamata)
        // Per sicurezza, verifichiamo che il dialog sia presente.
        // Se si è verificato un errore immediato prima di caricare la risposta, pop() chiude il dialog.
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'esportazione: $e'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche Interattive'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedPupil != null && _filteredActivities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _isExporting ? null : _exportPdf,
              tooltip: 'Esporta PDF',
            ),
        ],
      ),
      body: _isLoading && _pupils == null
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
                    onPressed: _loadPupils,
                    child: const Text('Riprova'),
                  ),
                ],
              ),
            )
          : _pupils == null || _pupils!.isEmpty
          ? _buildNoPupilsState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colonna Sinistra (Filtri e Riepilogo)
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPupilSelector(),
                              const SizedBox(height: 20),
                              _buildPeriodSelector(),
                              const SizedBox(height: 16),
                              _buildFilterControls(context),
                              const SizedBox(height: 24),
                              _isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: CircularProgressIndicator(
                                          color: AppColors.terraCotta,
                                        ),
                                      ),
                                    )
                                  : _buildStatsSummary(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Colonna Destra (Attività Filtrate)
                        Expanded(
                          flex: 5,
                          child: _isLoading
                              ? const SizedBox()
                              : _buildFilteredActivitiesSection(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPupilSelector(),
                        const SizedBox(height: 20),
                        _buildPeriodSelector(),
                        const SizedBox(height: 16),
                        _buildFilterControls(context),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.terraCotta,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildStatsSummary(),
                                  const SizedBox(height: 24),
                                  _buildFilteredActivitiesSection(),
                                ],
                              ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildPupilSelector() {
    return DropdownButtonFormField<Pupil>(
      initialValue: _selectedPupil,
      decoration: const InputDecoration(
        labelText: 'Seleziona Pupillo',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.blueGrey),
      ),
      items: _pupils!.map((pupil) {
        return DropdownMenuItem<Pupil>(value: pupil, child: Text(pupil.name));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedPupil = value;
            _loadActivitiesForSelectedPupil();
          });
        }
      },
    );
  }

  Widget _buildFilteredActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attività nel periodo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            IconButton(
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: AppColors.darkGreen,
                size: 20,
              ),
              tooltip: _sortAscending
                  ? 'Ordina per: Meno recenti prima'
                  : 'Ordina per: Più recenti prima',
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                  _filterAndCalculate();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _filteredActivities.isEmpty
            ? _buildEmptyActivitiesState()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredActivities.length,
                itemBuilder: (context, index) {
                  final activity = _filteredActivities[index];
                  return _buildActivityCard(activity);
                },
              ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.beige.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.beige),
      ),
      child: Row(
        children: ['Giorno', 'Mese', 'Anno'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _filterAndCalculate();
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.blueGrey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    if (_selectedPeriod == 'Giorno') {
      final formattedDay =
          '${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}';
      return InkWell(
        onTap: () => _selectDay(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    formattedDay,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.edit_calendar_outlined,
                color: AppColors.blueGrey,
              ),
            ],
          ),
        ),
      );
    } else if (_selectedPeriod == 'Mese') {
      return Row(
        children: [
          // Dropdown Mese
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(labelText: 'Mese'),
              items: List.generate(12, (index) {
                return DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text(_monthsItalian[index]),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = value;
                    _filterAndCalculate();
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          // Dropdown Anno
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(labelText: 'Anno'),
              items: _years.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    _filterAndCalculate();
                  });
                }
              },
            ),
          ),
        ],
      );
    } else {
      // Anno
      return DropdownButtonFormField<int>(
        initialValue: _selectedYear,
        decoration: const InputDecoration(
          labelText: 'Anno',
          prefixIcon: Icon(
            Icons.calendar_month_outlined,
            color: AppColors.blueGrey,
          ),
        ),
        items: _years.map((year) {
          return DropdownMenuItem<int>(
            value: year,
            child: Text(year.toString()),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedYear = value;
              _filterAndCalculate();
            });
          }
        },
      );
    }
  }

  Widget _buildStatsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ore Totali Lavorate
        Card(
          color: AppColors.darkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Ore Totali Lavorate nel Periodo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.beige,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatDuration(_totalHours),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Grid per Categoria
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              icon: Icons.phone_outlined,
              title: 'Telefonate',
              value: formatDuration(_callHours),
              color: AppColors.darkGreen,
            ),
            _buildStatCard(
              icon: Icons.directions_car_outlined,
              title: 'Trasferte',
              value: '${_totalKm.toStringAsFixed(1)} km',
              subtitle: 'Solo km',
              color: AppColors.terraCotta,
            ),
            _buildMailCard(),
            _buildStatCard(
              icon: Icons.person_search_outlined,
              title: 'Incontri Pupillo',
              value: formatDuration(_meetingPupilsHours),
              color: AppColors.blueGrey,
            ),
            _buildStatCard(
              icon: Icons.groups_outlined,
              title: 'Incontri Varie',
              value: formatDuration(_meetingVariousHours),
              color: AppColors.blueGrey,
            ),
            _buildStatCard(
              icon: Icons.work_outline,
              title: 'Altro',
              value: formatDuration(_otherHours),
              color: AppColors.blueGrey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.beige, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 8,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
      ),
    );
  }

  Widget _buildMailCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.beige, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.email_outlined,
              color: AppColors.darkGreen,
              size: 24,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email / Lettere',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.blueGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDuration(_mailHours),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  '${_totalStamps.toStringAsFixed(2)} CHF francobolli',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.terraCotta,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Activity activity) {
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
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.beige, width: 0.8),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ActivityDetailPage(
                activity: activity,
                pupilName: _selectedPupil!.name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.beige.withValues(alpha: 0.5),
                foregroundColor: AppColors.darkGreen,
                child: Icon(iconData, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          activity.typeLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                    if (activity.description != null &&
                        activity.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.beige, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.blueGrey),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPupilsState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: AppColors.blueGrey,
            ),
            SizedBox(height: 16),
            Text(
              'Nessun pupillo disponibile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aggiungi un pupillo dalla homepage prima di consultare le statistiche.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivitiesState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.beige, width: 0.8),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note_outlined, size: 40, color: AppColors.blueGrey),
          SizedBox(height: 12),
          Text(
            'Nessuna attività in questo periodo',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Non ci sono prestazioni registrate per i filtri selezionati.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.blueGrey),
          ),
        ],
      ),
    );
  }
}
