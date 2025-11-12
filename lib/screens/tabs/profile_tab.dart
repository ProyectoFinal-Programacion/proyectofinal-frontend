import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_pin_circle, size: 64),
          const SizedBox(height: 8),
          Text(auth.role ?? '-', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, LoginScreen.route);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          )
        ],
      ),
    );
  }
}
