import 'package:flutter/material.dart';
import '../install_platform.dart';
import '../install_prompt.dart';
import '../theme.dart';

/// Icona, titolo e istruzioni per installare l'app sul dispositivo.
/// [canPrompt]: il browser offre il proprio pulsante di installazione.
(IconData, String, String) installCopy(
  InstallPlatform platform,
  bool canPrompt,
) {
  return switch (platform) {
    InstallPlatform.ios => (
      Icons.ios_share,
      'Installa Kura sulla schermata Home',
      'In Safari tocca Condividi (il quadrato con la freccia in su) e poi '
          '«Aggiungi alla schermata Home». Kura si aprirà a schermo intero '
          'come un\'app. Al primo avvio dall\'icona ti verrà chiesto di '
          'accedere ancora una volta.',
    ),
    InstallPlatform.android => (
      Icons.install_mobile,
      'Installa Kura sul telefono',
      canPrompt
          ? 'Aggiungila alla schermata Home per aprirla come un\'app, a '
                'schermo intero.'
          : 'Apri il menu ⋮ del browser e scegli «Installa app» o «Aggiungi '
                'a schermata Home».',
    ),
    InstallPlatform.desktop => (
      Icons.install_desktop,
      'Installa Kura sul computer',
      canPrompt
          ? 'Aprila come un programma, dalla barra delle applicazioni o dal '
                'Dock, senza passare dal browser.'
          : 'In Chrome o Edge usa l\'icona di installazione nella barra degli '
                'indirizzi. In Safari su Mac scegli File › «Aggiungi al Dock».',
    ),
  };
}

/// Installa l'app: usa il prompt del browser se disponibile, altrimenti
/// mostra le istruzioni per il dispositivo.
Future<void> installOrExplain(
  BuildContext context,
  InstallPlatform platform,
) async {
  if (installPromptAvailable.value && platform != InstallPlatform.ios) {
    await promptInstall();
    return;
  }
  final (icon, title, text) = installCopy(platform, false);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icon, color: AppColors.darkGreen),
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Ho capito',
            style: TextStyle(
              color: AppColors.terraCotta,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Invito a installare la webapp sulla Home (iPhone/Android) o sul computer.
/// Compare solo nel browser, non quando l'app è già installata, e sparisce
/// per sempre su quel dispositivo con «Non ora».
class InstallBanner extends StatefulWidget {
  const InstallBanner({super.key});
  @override
  State<InstallBanner> createState() => _InstallBannerState();
}

class _InstallBannerState extends State<InstallBanner> {
  InstallPlatform? _platform;
  bool _hidden = true;

  @override
  void initState() {
    super.initState();
    _platform = installPlatform();
    _hidden = _platform == null || isInstallBannerDismissed();
    installPromptAvailable.addListener(_refresh);
  }

  @override
  void dispose() {
    installPromptAvailable.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _dismiss() {
    dismissInstallBanner();
    setState(() => _hidden = true);
  }

  Future<void> _install() async {
    final accepted = await promptInstall();
    if (accepted && mounted) setState(() => _hidden = true);
  }

  @override
  Widget build(BuildContext context) {
    final platform = _platform;
    if (_hidden || platform == null) return const SizedBox.shrink();
    final canPrompt = installPromptAvailable.value;

    final (icon, title, text) = installCopy(platform, canPrompt);

    return Material(
      color: AppColors.beige,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, color: AppColors.darkGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Uno sotto l'altro se il testo ingrandito non li fa stare in riga.
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: _dismiss,
                    child: const Text(
                      'Non ora',
                      style: TextStyle(color: AppColors.blueGrey),
                    ),
                  ),
                  if (canPrompt && platform != InstallPlatform.ios)
                    TextButton(
                      onPressed: _install,
                      child: const Text(
                        'Installa',
                        style: TextStyle(
                          color: AppColors.terraCotta,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
