import 'package:flutter/foundation.dart';
import 'install_platform.dart';

// Le app Android/iOS sono già installate: nessun banner.
final ValueNotifier<bool> installPromptAvailable = ValueNotifier(false);

InstallPlatform? installPlatform() => null;

bool isInstallBannerDismissed() => true;

void dismissInstallBanner() {}

Future<bool> promptInstall() async => false;
