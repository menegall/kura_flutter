import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/pages/login_page.dart';
import '../models/pupil_model.dart';
import '../services/pupils_service.dart';
import 'add_pupil_page.dart';
import 'pupil_detail_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _pupilsService = PupilsService();
  List<Pupil>? _pupils;
  bool _isLoading = false;
  String? _errorMessage;
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossibile caricare i pupilli. Riprova più tardi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }
  Future<void> _navigateToAddPupil() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddPupilPage()),
    );
    if (result == true) {
      _loadPupils();
    }
  }
  Future<void> _navigateToDetail(Pupil pupil) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PupilDetailPage(pupil: pupil),
      ),
    );
    // Ricarica la lista per mostrare le ore lavorate aggiornate al ritorno
    _loadPupils();
  }
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Curatore';
    return Scaffold(
      appBar: AppBar(
        title: Text('Ciao, $userName'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatsPage()),
              );
            },
            tooltip: 'Statistiche',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              _loadPupils();
            },
            tooltip: 'Impostazioni',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Esci',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPupils,
        color: AppColors.terraCotta,
        child: _buildBody(),
      ),
      floatingActionButton: _pupils != null && _pupils!.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddPupil,
              backgroundColor: AppColors.terraCotta,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
  Widget _buildBody() {
    if (_isLoading && _pupils == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.terraCotta),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppColors.terraCotta),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.darkGreen),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPupils,
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }
    if (_pupils == null || _pupils!.isEmpty) {
      return _buildEmptyState();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 900 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 140,
        ),
        itemCount: _pupils!.length,
        itemBuilder: (context, index) {
          final pupil = _pupils![index];
          return _buildPupilCard(pupil, useMargin: false);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _pupils!.length,
      itemBuilder: (context, index) {
        final pupil = _pupils![index];
        return _buildPupilCard(pupil);
      },
    );
  }
  Widget _buildPupilCard(Pupil pupil, {bool useMargin = true}) {
    final double rawPercent = pupil.maxHours > 0 ? (pupil.workedHours / pupil.maxHours) : 0.0;
    final double percent = rawPercent.clamp(0.0, 1.0);
    final double remainingHours = pupil.maxHours - pupil.workedHours;
    Color progressColor;
    if (rawPercent >= 1.0) {
      progressColor = AppColors.terraCotta;
    } else if (rawPercent >= 0.8) {
      progressColor = AppColors.blueGrey;
    } else {
      progressColor = AppColors.darkGreen;
    }
    return Card(
      color: Colors.white,
      margin: useMargin ? const EdgeInsets.only(bottom: 16.0) : EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.beige, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(pupil),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pupil.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ),
                  Text(
                    '${pupil.workedHours.toStringAsFixed(1)} / ${pupil.maxHours.toStringAsFixed(1)} h',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    rawPercent >= 1.0
                        ? 'Ore esaurite!'
                        : '${remainingHours.toStringAsFixed(1)} ore rimanenti',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: rawPercent >= 1.0 ? AppColors.terraCotta : AppColors.blueGrey,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.blueGrey.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_add_outlined,
              size: 80,
              color: AppColors.blueGrey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Non hai ancora nessun pupillo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Inizia aggiungendo il primo pupillo per gestire le ore di lavoro.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddPupil,
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi il tuo pupillo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}