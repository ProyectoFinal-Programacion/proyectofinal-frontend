import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/gig.dart';
import '../../models/review.dart';

import '../../services/api_client.dart';
import '../../services/orders_service.dart';
import '../../services/gigs_service.dart';
import '../../services/reviews_service.dart';
import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';

import '../worker/worker_create_gig_screen.dart';
import '../worker/worker_gig_edit_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _loading = true;
  List<Gig> _myGigs = [];
  List<Order> _pendingOrders = [];
  List<Order> _completedOrders = [];
  List<Review> _reviews = [];

  double _averageRating = 0;
  double _totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final auth = context.read<AuthProvider>();
      final user = auth.user!;
      final workerId = user.id;

      final ordersService = OrdersService(api);
      final gigsService = GigsService(api);
      final reviewsService = ReviewsService(api);

      final gigs = await gigsService.getWorkerGigs(workerId);
      final receivedOrders = await ordersService.getReceivedOrders();
      final reviews = await reviewsService.getUserReviews(workerId);
      final avgRating = await reviewsService.getUserAverage(workerId);

      final pending = receivedOrders.where((o) =>
          o.status.index == 0 || o.status.index == 1).toList();

      final completed = receivedOrders.where((o) =>
          o.status.index == 3).toList();

      double earnings = 0;
      for (var o in completed) {
        earnings += o.totalPrice;
      }

      setState(() {
        _myGigs = gigs;
        _pendingOrders = pending;
        _completedOrders = completed;
        _reviews = reviews;
        _averageRating = avgRating;
        _totalEarnings = earnings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar panel: $e')),
      );
      setState(() => _loading = false);
    }
  }

  // ----------------------------------------------------------------------
  // UI PRINCIPAL
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel del trabajador"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkerCreateGigScreen()),
              ).then((value) => _loadDashboard());
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatsCards(),
            const SizedBox(height: 25),
            _buildSectionTitle("Tus servicios"),
            _buildMyGigsList(),
            const SizedBox(height: 25),
            _buildSectionTitle("Órdenes pendientes"),
            _buildOrdersList(_pendingOrders,
                emptyText: "No tienes órdenes pendientes."),
            const SizedBox(height: 25),
            _buildSectionTitle("Órdenes completadas"),
            _buildOrdersList(_completedOrders,
                emptyText: "Aún no completaste trabajos."),
            const SizedBox(height: 25),
            _buildSectionTitle("Últimas reseñas"),
            _buildReviews(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------------------

  Widget _buildHeader() {
    final user = context.read<AuthProvider>().user!;
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              user.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 28, color: Colors.white),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hola, ${user.name}", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text("Tu panel de trabajo", style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // STATS CARDS
  // ----------------------------------------------------------------------

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _statCard("Ganancias", "Bs ${_totalEarnings.toStringAsFixed(2)}", Icons.monetization_on)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Pendientes", "${_pendingOrders.length}", Icons.pending_actions)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Completados", "${_completedOrders.length}", Icons.check_circle)),
        const SizedBox(width: 12),
        Expanded(child: _statCard("Rating", _averageRating > 0 ? _averageRating.toStringAsFixed(1) : "N/A", Icons.star, color: Colors.amber)),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon,
      {Color color = Colors.blue}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // SECCIÓN TITULOS
  // ----------------------------------------------------------------------

  Widget _buildSectionTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
  }

  // ----------------------------------------------------------------------
  // LISTA DE SERVICIOS
  // ----------------------------------------------------------------------

  Widget _buildMyGigsList() {
    if (_myGigs.isEmpty) {
      return const Text("Aún no tienes servicios creados.");
    }

    return Column(
      children: _myGigs.map((g) {
        String? img =
            g.imageUrls.isNotEmpty ? buildImageUrl(g.imageUrls.first) : null;

        return Card(
          child: ListTile(
            leading: img != null
                ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, width: 64, height: 64, fit: BoxFit.cover))
                : const Icon(Icons.build, size: 40),
            title: Text(g.title, style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text(g.category ?? '', style: Theme.of(context).textTheme.bodyLarge),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkerGigEditScreen(gig: g),
                      ),
                    ).then((value) => _loadDashboard());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final api = context.read<ApiClient>();
                    final gigsService = GigsService(api);
                    await gigsService.deleteGig(g.id);
                    _loadDashboard();
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------------------
  // LISTA DE ÓRDENES
  // ----------------------------------------------------------------------

  Widget _buildOrdersList(List<Order> orders, {String emptyText = ""}) {
    if (orders.isEmpty) {
      return Text(emptyText);
    }

    return Column(
      children: orders.map((o) {
        return Card(
          child: ListTile(
            title: Text(o.title ?? "Servicio", style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text("Cliente: ${o.clientName ?? 'N/A'}\nBs ${o.totalPrice}", style: Theme.of(context).textTheme.bodyLarge),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------------------
  // RESEÑAS
  // ----------------------------------------------------------------------

  Widget _buildReviews() {
    if (_reviews.isEmpty) {
      return const Text("Aún no tienes reseñas.");
    }

    return Column(
      children: _reviews.take(3).map((r) {
        return Card(
          child: ListTile(
            title: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(r.rating.toStringAsFixed(1)),
              ],
            ),
            subtitle: Text(r.comment ?? ''),
          ),
        );
      }).toList(),
    );
  }
}
