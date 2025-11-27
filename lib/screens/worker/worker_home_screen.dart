import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/gigs_service.dart';
import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/custom_loading.dart';
import '../common/chat_screen.dart';
import '../client/client_create_order_screen.dart';
import '../worker/worker_dashboard_screen.dart';
import '../client/worker_map_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  bool _loading = true;
  List<Gig> _otherGigs = [];
  List<Gig> _myGigs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final auth = context.read<AuthProvider>();
      final me = auth.user!;

      final gigsService = GigsService(api);
      final all = await gigsService.getGigs();
      
      setState(() {
        _myGigs = all.where((g) => g.workerId == me.id).toList();
        _otherGigs = all.where((g) => g.workerId != me.id).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _openPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkerDashboardScreen()),
    );
  }

  void _openChat(Gig gig) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: gig.workerId,
          otherUserName: gig.workerName ?? "Trabajador",
        ),
      ),
    );
  }

  void _createOrder(Gig gig) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientCreateOrderScreen(
          gig: gig,
          workerId: gig.workerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
          // Header con gradiente y datos del trabajador
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: _openPanel,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.imageUrl != null && user!.imageUrl!.isNotEmpty
                                ? NetworkImage(buildImageUrl(user!.imageUrl!))
                                : null,
                            child: user?.imageUrl == null || user?.imageUrl?.isEmpty == true
                                ? Text(
                                    user?.name.isNotEmpty == true 
                                        ? user!.name.substring(0, 1).toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Hola!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.name ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Toca para ver tu panel',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Botón de Mapa (Nuevo)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.map, color: Colors.white),
                            tooltip: 'Ver Mapa',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WorkerMapScreen(),
                                ),
                              );
                            },
                          ),
                        ).animate().scale(delay: 200.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
          ),

          // Estadísticas del trabajador
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Mis Servicios',
                          value: _myGigs.length.toString(),
                          icon: Icons.work,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: _openPanel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Disponibles',
                          value: _otherGigs.length.toString(),
                          icon: Icons.shopping_bag,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Mis servicios activos (si hay)
          if (_myGigs.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Text(
                      'Mis Servicios',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _openPanel,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Gestionar'),
                    ),
                  ],
                ),
              ),
            ),
            
            // Lista vertical de mis servicios
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final g = _myGigs[index];
                    final imageUrl = g.imageUrls.isNotEmpty
                        ? buildImageUrl(g.imageUrls.first)
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: PremiumCard(
                        onTap: _openPanel,
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        child: Row(
                          children: [
                            // Imagen
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      width: 120, // Un poco más ancho
                                      height: 150, // Altura fija
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 120,
                                        height: 150,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                        child: const Icon(Icons.image, size: 40),
                                      ),
                                    )
                                  : Container(
                                      width: 120,
                                      height: 150,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      child: const Icon(Icons.image, size: 40),
                                    ),
                            ),

                            // Info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      g.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    if (g.category != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          g.category!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Bs ${g.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (index * 100).ms, duration: 400.ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                  childCount: _myGigs.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // Servicios de otros trabajadores
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Explora Otros Servicios',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // Lista de otros servicios
          if (_otherGigs.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay otros servicios disponibles'),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final g = _otherGigs[index];
                    final imageUrl = g.imageUrls.isNotEmpty
                        ? buildImageUrl(g.imageUrls.first)
                        : null;

                    return ServiceCard(
                      title: g.title,
                      category: g.category,
                      price: g.price,
                      imageUrl: imageUrl,
                      rating: 4.5,
                      onTap: () => _createOrder(g),
                      onChat: () => _openChat(g),
                      onHire: () => _createOrder(g),
                    )
                        .animate()
                        .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0);
                  },
                  childCount: _otherGigs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
