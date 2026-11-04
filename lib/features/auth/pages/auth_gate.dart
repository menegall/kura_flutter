import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../../home/pages/main_shell.dart';

/// Sceglie la schermata iniziale in base alla sessione.
///
/// La durata della sessione è gestita da Supabase: il token di accesso si
/// rinnova da solo e l'utente resta collegato finché non esce, cambia
/// password o la sessione viene revocata dal server.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null ? const MainShell() : const LoginPage();
  }
}
