import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../client/client_home_screen.dart';
import '../client/client_orders_screen.dart';
import '../client/worker_map_screen.dart';
import '../common/profile_screen.dart';
import '../common/chats_list_screen.dart';
import '../auth/login_screen.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  final _screens = const [
    ClientHomeScreen(),
    ClientOrdersScreen(),
    ProfileScreen(),
  ];

  void _onTap(int i) {
    setState(() => _index = i);
  }

  String get _title {
    switch (_index) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Órdenes';
      case 2:
      default:
        return 'Cuenta';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: const IconThemeData(size: 30),
        unselectedIconTheme: const IconThemeData(size: 24),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Órdenes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cuenta',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ChatsListScreen(),
            ),
          );
        },
        tooltip: 'Mensajes',
        child: const Icon(Icons.chat),
      ),
    );
  }
}
