import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/order.dart';
import '../../models/enums.dart';
import '../../services/api_client.dart';
import '../../services/orders_service.dart';
import '../../services/admin_service.dart'; // Import agregado
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/custom_loading.dart';
import '../../widgets/admin/admin_drawer.dart';

class AdminCompletedScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const AdminCompletedScreen({super.key, this.onOpenDrawer});

  @override
  State<AdminCompletedScreen> createState() => _AdminCompletedScreenState();
}

class _AdminCompletedScreenState extends State<AdminCompletedScreen> {
  List<Order> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final api = context.read<ApiClient>();
      final adminService = AdminService(api);
      final allOrders = await adminService.getAllOrders();
      if (!mounted) return;
      setState(() {
        orders = allOrders.where((o) => o.status == OrderStatus.completed).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CustomLoading(message: "Cargando órdenes completadas..."));
    }

    final canPop = Navigator.canPop(context);

    return Scaffold(
      // Eliminamos el drawer local
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            leading: canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  )
                : IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: widget.onOpenDrawer,
                  ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Órdenes Completadas',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
          if (orders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay órdenes completadas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final o = orders[index];

                    return PremiumCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orden #${o.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  o.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Bs ${o.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).slideX();
                  },
                  childCount: orders.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
