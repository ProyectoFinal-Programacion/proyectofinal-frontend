import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'config/api_config.dart';
import 'services/api_client.dart';
import 'state/auth_provider.dart';
import 'state/theme_provider.dart';
import 'models/enums.dart';

// NUEVOS imports
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';

// Mantengo tus shells
import 'screens/shell/admin_shell.dart';
import 'screens/shell/client_shell.dart';
import 'screens/shell/worker_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formateo de fechas (para intl)
  await initializeDateFormatting('es_ES', null);
  Intl.defaultLocale = 'es_ES';

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://mtsdcpgiuexdgmfegdfk.supabase.co',
    anonKey: 'sb_publishable_zzlvXc3PEIzwQDVylVFpgQ_uPWJBLMs',
  );

  runApp(const ManoVecinaApp());
}

class ManoVecinaApp extends StatefulWidget {
  const ManoVecinaApp({super.key});

  @override
  State<ManoVecinaApp> createState() => _ManoVecinaAppState();
}

class _ManoVecinaAppState extends State<ManoVecinaApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// Servicio de API
        Provider<ApiClient>(
          create: (_) => ApiClient(baseUrl: ApiConfig.baseUrl),
        ),

        /// ThemeProvider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),

        /// AuthProvider
        ChangeNotifierProvider<AuthProvider>(
          create: (context) {
            final api = context.read<ApiClient>();
            final auth = AuthProvider(api);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              auth.loadFromStorage();
            });

            return auth;
          },
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProvider, _) {
          Widget home;

          // CASO 1 → Splash
          if (auth.isLoading || themeProvider.isLoading) {
            home = const SplashScreen();
          }

          // CASO 2 → Si no está autenticado → Login
          else if (!auth.isAuthenticated) {
            home = const LoginScreen();
          }

          // CASO 3 → Autenticado → Mostrar Shell según rol
          else {
            switch (auth.user!.role) {
              case UserRole.admin:
                home = const AdminShell();
                break;
              case UserRole.worker:
                home = const WorkerShell();
                break;
              case UserRole.client:
              default:
                home = const ClientShell();
                break;
            }
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ManoVecina',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: home,
          );
        },
      ),
    );
  }
}
