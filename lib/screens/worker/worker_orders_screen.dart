import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/order.dart';
import '../../models/enums.dart';
import '../../services/api_client.dart';
import '../../services/orders_service.dart';
import '../common/order_detail_screen.dart';
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/custom_loading.dart';

class WorkerOrdersScreen extends StatefulWidget {
  const WorkerOrdersScreen({super.key});

  @override
  State<WorkerOrdersScreen> createState() => _WorkerOrdersScreenState();
}

class _WorkerOrdersScreenState extends State<WorkerOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Order> _receivedOrders = [];
  List<Order> _contractedOrders = [];
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final service = OrdersService(api);
      
      // Load both types of orders in parallel
      final results = await Future.wait([
        service.getReceivedOrders(), // Orders assigned TO the worker
        service.getMyOrders(),       // Orders created BY the worker (as client)
      ]);
      
      if (!mounted) return;
      setState(() {
        _receivedOrders = results[0];
        _contractedOrders = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.accepted:
        return 'Aceptada';
      case OrderStatus.completed:
        return 'Completada';
      case OrderStatus.cancelled:
        return 'Rechazada';
      case OrderStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconocido';
    }
  }

  void _openDetail(Order order) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );

    if (changed == true) {
      _load();
    }
  }

  Widget _buildOrdersList(List<Order> orders, String emptyMessage, bool showWorkerName) {
    if (orders.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                showWorkerName 
                    ? 'Los servicios contratados aparecerán aquí'
                    : 'Las nuevas solicitudes aparecerán aquí',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final o = orders[index];
            final statusColor = _statusColor(o.status);

            return PremiumCard(
              onTap: () => _openDetail(o),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.title ?? 'Orden #${o.id}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          _statusText(o.status),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    o.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        showWorkerName 
                            ? (o.workerName ?? 'Trabajador')
                            : (o.clientName ?? 'Cliente'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        'Bs ${o.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
          },
          childCount: orders.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CustomLoading(message: 'Cargando órdenes...'));
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Mis Órdenes',
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
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.assignment_turned_in),
                    text: 'Recibidas',
                  ),
                  Tab(
                    icon: Icon(Icons.shopping_bag),
                    text: 'Contratadas',
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Received Orders
            RefreshIndicator(
              onRefresh: _load,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  _buildOrdersList(
                    _receivedOrders,
                    'No tienes órdenes asignadas',
                    false, // show client name
                  ),
                ],
              ),
            ),
            // Tab 2: Contracted Orders
            RefreshIndicator(
              onRefresh: _load,
              color: Theme.of(context).colorScheme.primary,
              child: CustomScrollView(
                slivers: [
                  _buildOrdersList(
                    _contractedOrders,
                    'No has contratado servicios',
                    true, // show worker name
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
