import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constant.dart';
import 'core/theme.dart';
import 'features/auth/pages/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseCredentials.databaseUrl,
    publishableKey: SupabaseCredentials.publicKey,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kura',
      theme: appTheme,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Il testo segue la dimensione scelta nelle impostazioni del
        // telefono (accessibilità) fino al 200%, il massimo raccomandato
        // dalle linee guida WCAG: oltre, le schermate non sarebbero più
        // leggibili su un telefono.
        final appWidget = MediaQuery.withClampedTextScaling(
          maxScaleFactor: 2.0,
          child: child!,
        );

        if (screenWidth <= 600) {
          return appWidget;
        }
        return Container(
          color: AppColors.offWhite,
          child: Center(
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: appWidget,
              ),
            ),
          ),
        );
      },
    );
  }
}
