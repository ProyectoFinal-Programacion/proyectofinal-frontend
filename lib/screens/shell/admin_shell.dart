
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateTo(int index) {
    setState(() => _index = index);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminDashboardScreen(onNavigate: _navigateTo), // Dashboard no necesita openDrawer porque usa onNavigate
      AdminUsersScreen(onOpenDrawer: _openDrawer),
      AdminWorkersScreen(onOpenDrawer: _openDrawer),
      AdminClientsScreen(onOpenDrawer: _openDrawer),
      // Eliminadas pantallas de órdenes por falta de endpoint
      const ProfileScreen(), 
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AdminDrawer(
        currentIndex: _index,
        onNavigate: _navigateTo,
      ),
      body: screens[_index],
    );
  }
}
