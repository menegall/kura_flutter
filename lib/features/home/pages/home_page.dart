import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_navigation.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../core/widgets/adaptive_row.dart';
import '../../../core/widgets/hours_progress.dart';
import '../../../core/widgets/install_banner.dart';
import '../../../core/widgets/update_banner.dart';
import '../../auth/services/auth_service.dart';
import '../models/pupil_model.dart';
import '../services/pupils_service.dart';
import '../widgets/app_tour.dart';
import 'add_activity_page.dart';
import 'add_pupil_page.dart';
import 'pupil_detail_page.dart';

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
  bool _tourChecked = false;
  @override
  void initState() {
    super.initState();
    appDataRefresh.addListener(_loadPupils);
    _loadPupils();
  }
  @override
  void dispose() {
    appDataRefresh.removeListener(_loadPupils);
    super.dispose();
  }
  Future<void> _loadPupils() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _pupilsService.getPupils();
      if (!mounted) return;
      setState(() {
        _pupils = list;
      });
      _maybeStartTour();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossibile caricare i pupilli. Riprova più tardi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Il tour guidato parte una sola volta, al primo accesso dopo la
  // registrazione, quando la Home è disegnata e i pulsanti da evidenziare
  // esistono.
  void _maybeStartTour() {
    if (_tourChecked) return;
    _tourChecked = true;
    if (!_authService.shouldShowTutorial) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) startAppTour(context);
    });
  }
  Future<void> _navigateToAddPupil() async {
    // I form si aprono a schermo intero, sopra il menu.
    final result = await Navigator.of(context, rootNavigator: true).push(
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
  // "+" della Home: registra un'attività. Con un solo pupillo apre subito
  // il form, altrimenti chiede prima per quale pupillo.
  Future<void> _registerActivity() async {
    final pupils = _pupils ?? [];
    if (pupils.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aggiungi prima un pupillo, poi potrai registrare le sue attività.'),
          backgroundColor: AppColors.darkGreen,
        ),
      );
      return;
    }
    final pupil = pupils.length == 1 ? pupils.first : await _choosePupil(pupils);
    if (pupil == null || !mounted) return;
    final saved = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (context) => AddActivityPage(pupil: pupil)),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attività registrata per ${pupil.name}.'),
          backgroundColor: AppColors.darkGreen,
        ),
      );
      _loadPupils();
    }
  }
  Future<Pupil?> _choosePupil(List<Pupil> pupils) {
    return showModalBottomSheet<Pupil>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: AppColors.offWhite,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  'Per quale pupillo?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final pupil in pupils)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.beige,
                          foregroundColor: AppColors.darkGreen,
                          child: Text(pupil.name.isNotEmpty ? pupil.name[0].toUpperCase() : '?'),
                        ),
                        title: Text(
                          pupil.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGreen),
                        ),
                        subtitle: Text(
                          '${formatDuration(pupil.workedHours)} su ${formatDuration(pupil.maxHours)}',
                          style: const TextStyle(color: AppColors.blueGrey),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.blueGrey),
                        onTap: () => Navigator.of(context).pop(pupil),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
      ),
      body: Column(
        children: [
          const UpdateBanner(),
          const InstallBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPupils,
              color: AppColors.terraCotta,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: _pupils != null
          ? FloatingActionButton.extended(
              key: TourKeys.addActivity,
              onPressed: _registerActivity,
              backgroundColor: AppColors.terraCotta,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Registra attività', style: TextStyle(fontWeight: FontWeight.bold)),
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

    // Spazio in fondo per non coprire l'ultimo elemento con il pulsante "+".
    const padding = EdgeInsets.fromLTRB(16, 16, 16, 96);
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return GridView.builder(
        padding: padding,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 900 ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          // L'altezza delle schede cresce con il testo (accessibilità).
          mainAxisExtent: 90 + 60 * MediaQuery.textScalerOf(context).scale(1),
        ),
        itemCount: _pupils!.length + 1,
        itemBuilder: (context, index) {
          if (index == _pupils!.length) return _buildAddPupilTile();
          return _buildPupilCard(_pupils![index], useMargin: false);
        },
      );
    }

    return ListView.builder(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _pupils!.length + 1,
      itemBuilder: (context, index) {
        if (index == _pupils!.length) return _buildAddPupilButton();
        return _buildPupilCard(_pupils![index]);
      },
    );
  }
  Widget _buildAddPupilButton() {
    return OutlinedButton.icon(
      key: TourKeys.addPupil,
      onPressed: _navigateToAddPupil,
      icon: const Icon(Icons.person_add_alt_1_outlined),
      label: const Text('Aggiungi pupillo'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkGreen,
        side: const BorderSide(color: AppColors.beige, width: 1.5),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  // Nella griglia (web, tablet, telefono in orizzontale) "Aggiungi pupillo"
  // è una scheda come le altre, invece di un pulsante grande quanto la cella.
  Widget _buildAddPupilTile() {
    return Card(
      key: TourKeys.addPupil,
      color: Colors.white,
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.beige, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _navigateToAddPupil,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.beige,
              child: Icon(Icons.person_add_alt_1_outlined, color: AppColors.terraCotta),
            ),
            SizedBox(height: 10),
            Text(
              'Aggiungi pupillo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPupilCard(Pupil pupil, {bool useMargin = true}) {
    final nameText = Text(
      pupil.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkGreen,
      ),
    );
    final hoursText = Text(
      '${formatDuration(pupil.workedHours)} / ${formatDuration(pupil.maxHours)}',
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGreen,
      ),
    );
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
              // Con il testo ingrandito le ore vanno sotto il nome.
              if (isLargeText(context))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [nameText, const SizedBox(height: 4), hoursText],
                )
              else
                Row(
                  children: [Expanded(child: nameText), const SizedBox(width: 12), hoursText],
                ),
              const SizedBox(height: 16),
              HoursProgress(
                workedHours: pupil.workedHours,
                maxHours: pupil.maxHours,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.blueGrey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 96),
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
                  key: TourKeys.addPupil,
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
        ),
      ),
    );
  }
}
