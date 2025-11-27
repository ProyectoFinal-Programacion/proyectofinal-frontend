import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/shell/admin_shell.dart';

class AdminDrawer extends StatelessWidget {
  final Function(int) onNavigate;
  final int currentIndex;

  const AdminDrawer({
    super.key,
    required this.onNavigate,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (auth.user?.imageUrl != null && auth.user!.imageUrl!.isNotEmpty)
                  ? NetworkImage(buildImageUrl(auth.user!.imageUrl!)) as ImageProvider
                  : null,
              child: (auth.user?.imageUrl == null || auth.user!.imageUrl!.isEmpty)
                  ? Text(
                      auth.user?.name.substring(0, 1).toUpperCase() ?? 'A',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            accountName: Text(
              auth.user?.name ?? 'Admin',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(auth.user?.email ?? ''),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _item(context, Icons.dashboard_rounded, 'Dashboard', 0),
                _item(context, Icons.people_rounded, 'Usuarios', 1),
                _item(context, Icons.handyman_rounded, 'Trabajadores', 2),
                _item(context, Icons.person_rounded, 'Clientes', 3),
                // _item(context, Icons.receipt_long_rounded, 'Órdenes', 4),
                // _item(context, Icons.check_circle_rounded, 'Completadas', 5),
                const Divider(),
                _item(context, Icons.settings_rounded, 'Cuenta', 4), // Index actualizado a 4
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              Navigator.pop(context);
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String text, int i) {
    final isSelected = currentIndex == i;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? colorScheme.primaryContainer : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : Colors.grey.shade700,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () async {
          Navigator.pop(context); // Close drawer
          // Pequeño delay para asegurar que el drawer se cierra antes de navegar
          await Future.delayed(const Duration(milliseconds: 100));
          onNavigate(i);
        },
      ),
    );
  }
}
