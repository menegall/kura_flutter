import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/pages/login_page.dart';
import '../models/pupil_model.dart';
import '../services/pupils_service.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
  final _pupilsService = PupilsService();
  final _nameController = TextEditingController();
  final _confirmController = TextEditingController();
  List<Pupil>? _pupils;
  bool _isLoading = false;
  bool _isSavingName = false;
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPupils();
  }
  void _loadUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['name'] ?? '';
    }
  }
  Future<void> _loadPupils() async {
    try {
      final list = await _pupilsService.getPupils();
      setState(() {
        _pupils = list;
      });
    } catch (_) {
      // Ignora silente o mostra errore se necessario
    }
  }
  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Il nome non può essere vuoto.'),
          backgroundColor: AppColors.terraCotta,
        ),
      );
      return;
    }
    setState(() => _isSavingName = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'name': newName}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nome aggiornato con successo!'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'aggiornamento del nome.'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }
  // Doppia conferma per l'eliminazione del pupillo
  Future<void> _confirmDeletePupil(Pupil pupil) async {
    // 1. Prima conferma
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare Pupillo?'),
        content: Text('Sei sicuro di voler eliminare ${pupil.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: AppColors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terraCotta),
            child: const Text('Sì, elimina'),
          ),
        ],
      ),
    );
    if (firstConfirm != true) return;
    // 2. Seconda conferma
    if (!mounted) return;
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Azione Irreversibile!'),
        content: Text(
          'Questa azione eliminerà permanentemente ${pupil.name} e TUTTE le sue attività associate dal database. Questa operazione non può essere annullata. Vuoi davvero procedere?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: AppColors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terraCotta),
            child: const Text('Conferma Eliminazione'),
          ),
        ],
      ),
    );
    if (secondConfirm != true) return;
    // Esegui eliminazione
    setState(() => _isLoading = true);
    try {
      await _pupilsService.deletePupil(pupil.id);
      _loadPupils(); // ricarica la lista dei pupilli
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pupil.name} eliminato con successo.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'eliminazione del pupillo.'),
            backgroundColor: AppColors.terraCotta,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  // Doppia conferma per l'eliminazione del profilo
  Future<void> _confirmDeleteProfile() async {
    // 1. Prima conferma
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il Profilo?'),
        content: const Text('Sei sicuro di voler eliminare definitivamente il tuo account? Tutti i dati andranno persi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla', style: TextStyle(color: AppColors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terraCotta),
            child: const Text('Procedi'),
          ),
        ],
      ),
    );
    if (firstConfirm != true) return;
    // 2. Seconda conferma forte con scrittura di "ELIMINA"
    if (!mounted) return;
    _confirmController.clear();
    
    final secondConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Conferma Finale Obligatoria'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Per confermare la cancellazione definitiva del tuo account e di tutti i dati ad esso associati, scrivi ELIMINA nel campo qui sotto:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi ELIMINA',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (val) {
                      setStateDialog(() {}); // aggiorna il dialogo per abilitare il tasto
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annulla', style: TextStyle(color: AppColors.blueGrey)),
                ),
                ElevatedButton(
                  onPressed: _confirmController.text.trim() == 'ELIMINA'
                      ? () => Navigator.of(context).pop(true)
                      : null, // Disabilitato se non corrisponde a "ELIMINA"
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terraCotta,
                    disabledBackgroundColor: AppColors.beige,
                  ),
                  child: const Text('Elimina definitivamente'),
                ),
              ],
            );
          },
        );
      },
    );
    if (secondConfirm != true) return;
    // Esegui eliminazione del profilo richiamando la RPC
    setState(() => _isLoading = true);
    try {
      // Eseguiamo la RPC PostgreSQL registrata su Supabase
      await Supabase.instance.client.rpc('delete_user');
      
      // Eseguiamo il logout locale per ripulire sessione e SharedPreferences
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account eliminato con successo.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante la cancellazione dell\'account: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sezione Profilo (Modifica Nome)
                  const Text(
                    'Profilo Curatore',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.beige, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nome Curatore',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.blueGrey),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isSavingName
                              ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
                              : ElevatedButton(
                                  onPressed: _updateName,
                                  child: const Text('Salva Nome'),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Sezione Gestione Pupilli
                  const Text(
                    'Gestione Pupilli',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _pupils == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
                      : _pupils!.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.beige, width: 1),
                              ),
                              child: const Text(
                                'Nessun pupillo inserito.',
                                style: TextStyle(color: AppColors.blueGrey, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Card(
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.beige, width: 1),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _pupils!.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.beige),
                                itemBuilder: (context, index) {
                                  final pupil = _pupils![index];
                                  return ListTile(
                                    title: Text(
                                      pupil.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkGreen),
                                    ),
                                    subtitle: Text(
                                      '${pupil.maxHours.toStringAsFixed(1)} ore max/anno',
                                      style: const TextStyle(color: AppColors.blueGrey, fontSize: 13),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.terraCotta),
                                      onPressed: () => _confirmDeletePupil(pupil),
                                      tooltip: 'Elimina pupillo',
                                    ),
                                  );
                                },
                              ),
                            ),
                  const SizedBox(height: 40),
                  // Sezione Operazioni Pericolose (Cancellazione account)
                  const Divider(color: AppColors.beige, thickness: 1.5),
                  const SizedBox(height: 20),
                  const Text(
                    'Zona Pericolosa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.terraCotta,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.terraCotta, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cancellazione Account',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Questa operazione cancellerà permanentemente il tuo profilo, tutti i tuoi pupilli registrati e le attività ad essi collegate. Non potrai più recuperare questi dati.',
                            style: TextStyle(fontSize: 13, color: AppColors.blueGrey),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _confirmDeleteProfile,
                            icon: const Icon(Icons.delete_forever, color: AppColors.terraCotta),
                            label: const Text('Elimina il mio profilo', style: TextStyle(color: AppColors.terraCotta)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.terraCotta),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
