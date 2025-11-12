import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'tabs/services_tab.dart';
import 'tabs/workers_tab.dart';
import 'tabs/requests_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const ServicesTab(),
      const WorkersTab(),
      const RequestsTab(),
      const ProfileTab(),
    ];
    final titles = ['Servicios', 'Trabajadores', 'Solicitudes', 'Perfil'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_repair_service_outlined), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Trabajadores'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Solicitudes'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
