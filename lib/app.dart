import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_service_screen.dart';
import 'screens/worker_onboarding_screen.dart';

class ManoVecinaApp extends StatelessWidget {
  const ManoVecinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return MaterialApp(
      title: 'ManoVecina',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      routes: {
        LoginScreen.route: (_) => const LoginScreen(),
        RegisterScreen.route: (_) => const RegisterScreen(),
        HomeScreen.route: (_) => const HomeScreen(),
        CreateServiceScreen.route: (_) => const CreateServiceScreen(),
        WorkerOnboardingScreen.route: (_) => const WorkerOnboardingScreen(),
      },
    );
  }
}
