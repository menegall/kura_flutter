import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kura_flutter/core/app_navigation.dart';
import 'package:kura_flutter/features/auth/pages/forgot_password_page.dart';
import 'package:kura_flutter/features/auth/pages/login_page.dart';
import 'package:kura_flutter/features/auth/pages/reset_password_page.dart';
import 'package:kura_flutter/features/auth/pages/signup_page.dart';
import 'package:kura_flutter/features/home/pages/add_pupil_page.dart';
import 'package:kura_flutter/features/home/pages/edit_pupil_page.dart';
import 'package:kura_flutter/features/home/pages/main_shell.dart';
import 'package:kura_flutter/features/home/pages/settings_page.dart';
import 'package:kura_flutter/features/home/widgets/app_tour.dart';
import 'package:kura_flutter/core/theme.dart';
import 'package:kura_flutter/core/widgets/hours_progress.dart';
import 'package:kura_flutter/features/home/models/activity_model.dart';
import 'package:kura_flutter/features/home/models/pupil_model.dart';
import 'package:kura_flutter/features/home/pages/home_page.dart';
import 'package:kura_flutter/features/home/pages/pupil_detail_page.dart';
import 'package:kura_flutter/features/home/pages/stats_page.dart';
import 'package:kura_flutter/features/home/pages/activity_detail_page.dart';
import 'package:kura_flutter/features/home/services/pupils_service.dart';
import 'package:kura_flutter/features/home/widgets/activity_form.dart';

// Dati finti con nomi e valori lunghi, il caso peggiore per il layout.
final _pupil = Pupil(
  id: 'p1',
  userId: 'u1',
  name: 'Maria Antonietta Bianchi-Rossi',
  maxHours: 120,
  workedHours: 101.75,
  tarif: 85.5,
  kmTarif: 0.75,
);

final _now = DateTime.now();
final _activities = [
  Activity(
    id: 'a1',
    pupilId: 'p1',
    activityDate: DateTime(_now.year, _now.month, 3),
    type: 'meeting_pupils',
    duration: 2.75,
    description: 'Colloquio con la banca per il conto e la cassa malati',
    kilometers: 123.5,
    otherExpenses: 15.5,
    createdAt: _now,
  ),
  Activity(
    id: 'a2',
    pupilId: 'p1',
    activityDate: DateTime(_now.year, _now.month, 1),
    type: 'mail',
    duration: 0.25,
    stamp: 1.2,
    createdAt: _now,
  ),
];

class _FakePupilsService extends PupilsService {
  _FakePupilsService() : super.base();
  @override
  Future<List<Pupil>> getPupils({bool includeArchived = false}) async => [_pupil];
  @override
  Future<Pupil> getPupilById(String id) async => _pupil;
  @override
  Future<List<Activity>> getRecentActivities(String pupilId) async => _activities;
}

// Nei test Flutter usa un carattere in cui ogni lettera è un quadrato:
// il testo risulta molto più largo del vero. Si carica il Roboto reale
// (incluso nell'SDK di Flutter) per misure realistiche.
Future<void> _loadRealFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) return;
  final dir = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final file in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
    final f = File('$dir/$file');
    if (f.existsSync()) roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await roboto.load();
  final icons = File('$dir/materialicons-regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _loadRealFonts();
    // Supabase serve solo per leggere l'utente (nessuno): niente rete.
    await Supabase.initialize(
      url: 'http://localhost:54321',
      publishableKey: 'test',
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        detectSessionInUri: false,
      ),
    );
    PupilsService.testOverride = _FakePupilsService();
  });

  // Telefono piccolo (320 px) con il testo al 200%, il massimo consentito.
  for (final scale in [1.0, 2.0]) {
    Future<void> pump(WidgetTester tester, Widget page) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        home: MediaQuery(
          data: MediaQueryData(size: const Size(320, 640), textScaler: TextScaler.linear(scale)),
          child: page,
        ),
      ));
      await tester.pumpAndSettle();
    }

    // Un layout rotto ("RenderFlex overflowed") fa fallire il test.
    group('testo al ${(scale * 100).round()}%', () {
      testWidgets('Home con la scheda del pupillo', (tester) async {
        await pump(tester, const HomePage());
        expect(find.text(_pupil.name), findsOneWidget);
      });

      testWidgets('Dettaglio del pupillo', (tester) async {
        await pump(tester, PupilDetailPage(pupil: _pupil));
        expect(find.textContaining('Ore svolte'), findsOneWidget);
      });

      testWidgets('Statistiche', (tester) async {
        await pump(tester, const StatsPage());
        expect(find.text('Telefonate'), findsOneWidget);
      });

      testWidgets('Dettaglio attività', (tester) async {
        await pump(tester, ActivityDetailPage(activity: _activities.first, pupilName: _pupil.name));
        expect(find.text('Incontro con Pupillo'), findsWidgets);
      });

      testWidgets('Form attività', (tester) async {
        await pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: ActivityForm(initial: _activities.first, submitLabel: 'Salva', onSubmit: (_) async {}),
            ),
          ),
        );
        expect(find.text('Km percorsi'), findsOneWidget);
      });

      testWidgets('Impostazioni', (tester) async {
        await pump(tester, const SettingsPage());
        expect(find.text('Rivedi il tutorial'), findsOneWidget);
      });

      testWidgets('Login', (tester) async {
        await pump(tester, const LoginPage());
        expect(find.text('Password dimenticata?'), findsOneWidget);
      });

      testWidgets('Registrazione', (tester) async {
        await pump(tester, const SignupPage());
      });

      testWidgets('Password dimenticata e reimposta', (tester) async {
        await pump(tester, const ForgotPasswordPage());
        await pump(tester, const ResetPasswordPage(email: 'maria.antonietta.bianchi@example.com'));
      });

      testWidgets('Nuovo e modifica pupillo', (tester) async {
        await pump(tester, const AddPupilPage());
        await pump(tester, EditPupilPage(pupil: _pupil));
      });

      testWidgets('Menu in basso e fumetto del tour', (tester) async {
        await pump(
          tester,
          const MainShell(tabRoots: [Scaffold(), Scaffold(), Scaffold()]),
        );
        expect(find.text('Impostazioni'), findsOneWidget);
        startAppTour(tester.element(find.byType(NavigationBar)), onFinished: () {});
        await tester.pumpAndSettle();
        expect(find.text('Inizia'), findsOneWidget);
        await tester.tap(find.text('Salta'));
        await tester.pumpAndSettle();
        currentAppTab.value = AppTab.pupils;
      });

      testWidgets('Barra delle ore', (tester) async {
        await pump(
          tester,
          const Scaffold(body: HoursProgress(workedHours: 101.75, maxHours: 120)),
        );
        expect(find.textContaining('Attenzione'), findsOneWidget);
      });
    });
  }
}
