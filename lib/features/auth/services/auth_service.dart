import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // L'utente attuale autenticato
  User? get currentUser => _supabase.auth.currentUser;
  // Stream per ascoltare i cambiamenti di stato dell'autenticazione
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Salviamo il nome nei metadati dell'utente usando il parametro `data`
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    await _saveLoginTimestamp();
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _saveLoginTimestamp();
    return response;
  }

  Future<void> _saveLoginTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_login_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Invia un'email con un codice OTP a 6 cifre per reimpostare la password.
  /// Supabase risponde con successo anche se l'email non è registrata
  /// (protezione contro l'enumerazione degli utenti).
  Future<void> sendPasswordResetCode(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Verifica il codice OTP di recupero e imposta la nuova password.
  /// Al termine chiude la sessione di recupero: l'utente dovrà rifare il
  /// login con la nuova password.
  Future<void> verifyResetCodeAndUpdatePassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    await _supabase.auth.signOut();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
