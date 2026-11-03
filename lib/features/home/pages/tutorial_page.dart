import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../auth/services/auth_service.dart';

class _TutorialStep {
  final IconData icon;
  final String title;
  final String text;
  const _TutorialStep(this.icon, this.title, this.text);
}

const _steps = [
  _TutorialStep(
    Icons.hourglass_bottom_rounded,
    'Benvenuto in Kura',
    'Tieni traccia del tempo e delle spese dedicate ai tuoi pupilli, in pochi tocchi.',
  ),
  _TutorialStep(
    Icons.person_add_alt_1_outlined,
    'Aggiungi un pupillo',
    'Dalla Home tocca «Aggiungi il tuo pupillo» e inserisci nome, ore massime all\'anno, tariffa oraria e tariffa per km.',
  ),
  _TutorialStep(
    Icons.edit_calendar_outlined,
    'Registra le attività',
    'Apri un pupillo e tocca «Registra Attività»: scegli il tipo (telefonata, trasferta, email, incontro…), la durata ed eventuali km e spese.',
  ),
  _TutorialStep(
    Icons.donut_large_rounded,
    'Tieni d\'occhio le ore',
    'Nella Home la barra di ogni pupillo mostra le ore usate rispetto al massimo annuale, così sai sempre quante ne restano.',
  ),
  _TutorialStep(
    Icons.bar_chart_rounded,
    'Statistiche e PDF',
    'Dall\'icona del grafico in alto vedi i totali per giorno, mese o anno, anche in CHF, ed esporti il rendiconto in PDF.\n\nPuoi rivedere questa guida quando vuoi dalle Impostazioni.',
  ),
];

/// Guida introduttiva mostrata al primo accesso; si può saltare in ogni
/// momento. Uscendo (fine, «Salta» o indietro) viene segnata come vista.
class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});
  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final _authService = AuthService();
  final _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLastPage) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _authService.markTutorialSeen();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedOpacity(
                        opacity: _isLastPage ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: _isLastPage ? null : () => Navigator.of(context).pop(),
                          child: const Text(
                            'Salta',
                            style: TextStyle(color: AppColors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _steps.length,
                      onPageChanged: (index) => setState(() => _currentPage = index),
                      itemBuilder: (context, index) => _buildStep(_steps[index]),
                    ),
                  ),
                  _buildDots(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(_isLastPage ? 'Inizia' : 'Avanti'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_TutorialStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 140,
            height: 140,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 72, color: AppColors.terraCotta),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.text,
            style: const TextStyle(fontSize: 16, color: AppColors.blueGrey, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.terraCotta : AppColors.beige,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
