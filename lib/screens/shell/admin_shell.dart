
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/admin_users_screen.dart';
import '../admin/admin_workers_screen.dart';
import '../admin/admin_clients_screen.dart';
import '../admin/admin_orders_screen.dart';
import '../admin/admin_completed_screen.dart';
import '../common/profile_screen.dart';
import '../../widgets/admin/admin_drawer.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  // Usamos una lista de getters o builders para poder pasar callbacks si fuera necesario
  // Pero como _index es estado local, simplemente reconstruimos el body.
  
  // Para que AdminDashboardScreen pueda navegar, necesitamos pasarle una función.
  // Pero AdminDashboardScreen es const.
  // Podemos pasarle un callback en el constructor.

  void _navigateTo(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminDashboardScreen(onNavigate: _navigateTo),
      const AdminUsersScreen(),
      const AdminWorkersScreen(),
      const AdminClientsScreen(),
      const AdminOrdersScreen(),
      const AdminCompletedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // AppBar eliminado para permitir headers personalizados
      drawer: AdminDrawer(
        currentIndex: _index,
        onNavigate: _navigateTo,
      ),
      body: screens[_index],
    );
  }
}
