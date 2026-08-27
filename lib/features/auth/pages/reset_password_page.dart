import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.terraCotta,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (code.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError('Per favore, compila tutti i campi.');
      return;
    }
    if (int.tryParse(code) == null) {
      _showError('Il codice deve contenere solo cifre.');
      return;
    }
    if (code.length < 6) {
      _showError('Codice non valido.');
      return;
    }
    if (password.length < 6) {
      _showError('La password deve contenere almeno 6 caratteri.');
      return;
    }
    if (password != confirm) {
      _showError('Le password non coincidono.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.verifyResetCodeAndUpdatePassword(
        email: widget.email,
        code: code,
        newPassword: password,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password aggiornata! Ora puoi accedere con la nuova password.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        final message = e.message.toLowerCase();
        if (message.contains('expired') ||
            message.contains('invalid') ||
            e.statusCode == '403') {
          _showError('Codice non valido o scaduto. Richiedi un nuovo codice.');
        } else if (e.statusCode == '429') {
          _showError('Troppi tentativi. Attendi qualche minuto e riprova.');
        } else {
          _showError(e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Si è verificato un errore inaspettato.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await _authService.sendPasswordResetCode(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nuovo codice inviato.'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        if (e.statusCode == '429') {
          _showError('Attendi circa un minuto prima di richiedere un nuovo codice.');
        } else {
          _showError(e.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Si è verificato un errore inaspettato.');
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkGreen),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 100,
                  color: AppColors.terraCotta,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Reimposta la password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Abbiamo inviato un codice a ${widget.email}. Inseriscilo qui sotto insieme alla nuova password.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Codice di verifica',
                    prefixIcon: Icon(Icons.pin_outlined, color: AppColors.blueGrey),
                    counterText: '',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Nuova password',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.blueGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: AppColors.blueGrey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Conferma nuova password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.blueGrey),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
                    : ElevatedButton(
                        onPressed: _resetPassword,
                        child: const Text('Reimposta password'),
                      ),
                const SizedBox(height: 16),
                _isResending
                    ? const Center(child: CircularProgressIndicator(color: AppColors.terraCotta))
                    : TextButton(
                        onPressed: _resendCode,
                        child: const Text(
                          'Non hai ricevuto il codice? Invia di nuovo',
                          style: TextStyle(color: AppColors.terraCotta, fontWeight: FontWeight.bold),
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
