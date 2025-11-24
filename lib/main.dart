import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ManoVecinaApp());
}

class ManoVecinaApp extends StatefulWidget {
  const ManoVecinaApp({super.key});

  @override
  State<ManoVecinaApp> createState() => _ManoVecinaAppState();
}

class _ManoVecinaAppState extends State<ManoVecinaApp> {
  bool _seenOnboarding = false;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _seenOnboarding = prefs.getBool("seen_onboarding") ?? false;
    setState(() => _loadingPrefs = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
          // Mantenemos un splash inicial 1 segundo
          if (auth.isLoading || themeProvider.isLoading) {
            home = const SplashScreen();
          }

          // CASO 2 → Onboarding (solo primera vez)
          else if (!_seenOnboarding) {
            home = OnboardingScreen(
              onFinish: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool("seen_onboarding", true);
                setState(() => _seenOnboarding = true);
              },
            );
          }

          // CASO 3 → Si no está autenticado → Login
          else if (!auth.isAuthenticated) {
            home = const LoginScreen();
          }

          // CASO 4 → Autenticado → Mostrar Shell según rol
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
