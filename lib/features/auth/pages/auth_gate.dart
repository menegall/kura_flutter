import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import 'login_page.dart';
import '../../home/pages/home_page.dart';
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        // Mostra un indicatore di caricamento durante il controllo della sessione
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.terraCotta),
            ),
          );
        }
        final isLoggedIn = snapshot.data ?? false;
        if (isLoggedIn) {
          return const HomePage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
  Future<bool> _checkAuth() async {
    // 1. Controlla se c'è una sessione Supabase attiva (persiste automaticamente su disco)
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginMs = prefs.getInt('last_login_time');
      if (lastLoginMs == null) {
        // Se c'è una sessione Supabase ma manca il timestamp locale, lo salviamo adesso
        await prefs.setInt('last_login_time', DateTime.now().millisecondsSinceEpoch);
        return true;
      }
      final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginMs);
      final difference = DateTime.now().difference(lastLogin);
      // Chiediamo di fare nuovamente il login ogni 7 giorni (impostabile a piacimento)
      if (difference.inDays >= 7) {
        await Supabase.instance.client.auth.signOut();
        await prefs.remove('last_login_time');
        return false;
      }
      return true;
    } catch (e) {
      // In caso di errori con SharedPreferences, facciamo comunque accedere l'utente
      // se la sessione Supabase è valida
      return true;
    }
  }
}
