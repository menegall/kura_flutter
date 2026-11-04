import 'package:flutter/material.dart';
import '../../../core/app_navigation.dart';
import '../../../core/theme.dart';
import '../../auth/services/auth_service.dart';

class _TourStep {
  final GlobalKey? target;
  final String title;
  final String text;
  const _TourStep(this.target, this.title, this.text);
}

final _steps = [
  const _TourStep(
    null,
    'Benvenuto in Kura!',
    'Ti mostriamo in pochi passi dove trovare tutto. Puoi saltare la guida '
        'in qualsiasi momento e rivederla dalle Impostazioni.',
  ),
  _TourStep(
    TourKeys.addPupil,
    'Aggiungi i tuoi pupilli',
    'Inizia da qui: nome, ore massime all\'anno, tariffa oraria e tariffa per '
        'km. Puoi aggiungerne quanti vuoi.',
  ),
  _TourStep(
    TourKeys.addActivity,
    'Registra le attività',
    'Con questo pulsante registri una telefonata, una trasferta o un '
        'incontro: scegli il pupillo, il tipo e la durata.',
  ),
  _TourStep(
    TourKeys.statsTab,
    'Statistiche',
    'Ore e totali in CHF per giorno, mese o anno. Da qui esporti il '
        'rendiconto in PDF o i dati in CSV per Excel.',
  ),
  _TourStep(
    TourKeys.settingsTab,
    'Impostazioni',
    'Profilo, pupilli archiviati, versione dell\'app e uscita. Qui trovi '
        'anche «Rivedi il tutorial».',
  ),
];

OverlayEntry? _activeTour;

/// Avvia il tour guidato sulla scheda Pupilli: scurisce lo schermo ed
/// evidenzia uno alla volta gli elementi veri dell'app. Alla fine, o con
/// «Salta», il tutorial viene segnato come visto ([onFinished] sostituisce
/// questo comportamento, utile nei test).
void startAppTour(BuildContext context, {VoidCallback? onFinished}) {
  if (_activeTour != null) return;
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _TourOverlay(
      onFinish: () {
        entry.remove();
        _activeTour = null;
        (onFinished ?? () => AuthService().markTutorialSeen())();
      },
    ),
  );
  _activeTour = entry;
  overlay.insert(entry);
}

class _TourOverlay extends StatefulWidget {
  final VoidCallback onFinish;
  const _TourOverlay({required this.onFinish});
  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;

  bool get _isLast => _index == _steps.length - 1;

  Future<void> _goTo(int index) async {
    if (index >= _steps.length) {
      widget.onFinish();
      return;
    }
    final targetContext = _steps[index].target?.currentContext;
    // Un elemento non presente (es. layout diverso) si salta.
    if (_steps[index].target != null && targetContext == null) {
      return _goTo(index + 1);
    }
    if (targetContext != null) {
      // Porta in vista l'elemento se è fuori schermo (es. fondo della lista).
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 250),
        alignment: 0.5,
      );
    }
    if (mounted) setState(() => _index = index);
  }

  Rect? _targetRect() {
    final targetContext = _steps[_index].target?.currentContext;
    final targetBox = targetContext?.findRenderObject() as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null || overlayBox == null || !targetBox.hasSize || !targetBox.attached) {
      return null;
    }
    final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return (topLeft & targetBox.size).inflate(6);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = constraints.biggest;
        final rect = step.target == null ? null : _targetRect();
        final cardWidth = (screen.width - 32).clamp(0.0, 360.0);
        final card = _buildCard(step, cardWidth);

        Widget positionedCard;
        if (rect == null) {
          positionedCard = Center(child: card);
        } else {
          final left = (rect.center.dx - cardWidth / 2).clamp(16.0, screen.width - cardWidth - 16);
          // Il fumetto va dalla parte dello schermo con più spazio.
          final below = rect.center.dy < screen.height / 2;
          positionedCard = Positioned(
            left: left,
            top: below ? rect.bottom + 16 : null,
            bottom: below ? null : screen.height - rect.top + 16,
            child: card,
          );
        }

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // Blocca i tocchi sull'app sotto il velo.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: CustomPaint(painter: _HolePainter(rect)),
                ),
              ),
              positionedCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(_TourStep step, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            step.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
          ),
          const SizedBox(height: 8),
          Text(
            step.text,
            style: const TextStyle(fontSize: 15, color: AppColors.darkGreen, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_index + 1} di ${_steps.length}',
                style: const TextStyle(fontSize: 13, color: AppColors.blueGrey),
              ),
              const Spacer(),
              if (!_isLast)
                TextButton(
                  onPressed: widget.onFinish,
                  child: const Text('Salta', style: TextStyle(color: AppColors.blueGrey)),
                ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () => _goTo(_index + 1),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(_index == 0 ? 'Inizia' : _isLast ? 'Fine' : 'Avanti'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Velo scuro su tutto lo schermo con un "buco" arrotondato sull'elemento
/// evidenziato.
class _HolePainter extends CustomPainter {
  final Rect? hole;
  _HolePainter(this.hole);

  @override
  void paint(Canvas canvas, Size size) {
    final veil = Path()..addRect(Offset.zero & size);
    final path = hole == null
        ? veil
        : Path.combine(
            PathOperation.difference,
            veil,
            Path()..addRRect(RRect.fromRectAndRadius(hole!, const Radius.circular(16))),
          );
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.65));
  }

  @override
  bool shouldRepaint(_HolePainter oldDelegate) => oldDelegate.hole != hole;
}
