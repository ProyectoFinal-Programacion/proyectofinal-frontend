import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_client.dart';
import '../../services/admin_service.dart';
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/custom_loading.dart';
import '../../widgets/admin/admin_drawer.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  int _totalUsers = 0;
  int _totalWorkers = 0;
  int _totalClients = 0;
  int _totalOrders = 0;
  int _activeOrders = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final adminService = AdminService(api);
      
      try {
        final dashboard = await adminService.getDashboard();
        if (mounted) {
          setState(() {
            _totalUsers = dashboard['totalUsers'] ?? 0;
            _totalWorkers = dashboard['totalWorkers'] ?? 0;
            _totalClients = dashboard['totalClients'] ?? 0;
            _totalOrders = dashboard['totalOrders'] ?? 0;
            _activeOrders = dashboard['activeOrders'] ?? 0;
            _loading = false;
          });
          return;
        }
      } catch (e) {
        final users = await adminService.getUsers();
        
        if (mounted) {
          setState(() {
            _totalUsers = users.length;
            _totalWorkers = users.where((u) => u['role'] == 1).length;
            _totalClients = users.where((u) => u['role'] == 0).length;
            if (_totalOrders == 0) _totalOrders = 0; 
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CustomLoading(message: 'Cargando dashboard...'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // Header con gradiente y botón de menú
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Panel de Admin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Estadísticas Principales
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estadísticas Generales',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Primera fila de stats
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Usuarios',
                          value: _totalUsers.toString(),
                          icon: Icons.people,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Trabajadores',
                          value: _totalWorkers.toString(),
                          icon: Icons.handyman,
                          color: const Color(0xFF00BFA5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Segunda fila de stats
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Órdenes',
                          value: _totalOrders.toString(),
                          icon: Icons.receipt_long,
                          color: const Color(0xFFFF6F00),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Activas',
                          value: _activeOrders.toString(),
                          icon: Icons.pending_actions,
                          color: const Color(0xFF9C27B0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
