import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/gigs_service.dart';
import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/premium_inputs.dart';
import '../../widgets/common/custom_loading.dart';
import '../common/chat_screen.dart';
import '../client/client_create_order_screen.dart';
import '../client/worker_map_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  bool _loading = true;
  List<Gig> _gigs = [];
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      final gigsService = GigsService(api);
      final data = await gigsService.getGigs();
      setState(() {
        _gigs = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar servicios: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _openChat(Gig gig) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: gig.workerId,
          otherUserName: gig.workerName ?? 'Trabajador',
        ),
      ),
    );
  }

  void _createOrder(Gig gig) {
    Navigator.of(context).push(
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
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (_loading) {
      return const Center(child: CustomLoading(message: 'Cargando servicios...'));
    }

    final filtered = _gigs.where((g) {
      if (_search.trim().isEmpty) return true;
      final query = _search.toLowerCase();
      return g.title.toLowerCase().contains(query) ||
          (g.category ?? '').toLowerCase().contains(query) ||
          (g.description ?? '').toLowerCase().contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: Theme.of(context).colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo y Botón de Mapa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '¡Hola${user?.name != null && user!.name.isNotEmpty ? ', ${user.name}' : ''}!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
                      ),
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

                  const SizedBox(height: 8),

                  const Text(
                    '¿Qué servicio necesitas hoy?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 24),

                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar servicios...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms).scale(),
                ],
              ),
            ),
          ),

          // Estadísticas rápidas
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Servicios',
                      value: _gigs.length.toString(),
                      icon: Icons.work,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Disponibles',
                      value: filtered.length.toString(),
                      icon: Icons.check_circle,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Título de sección
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Text(
                    _search.isEmpty ? 'Servicios Destacados' : 'Resultados de Búsqueda',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (filtered.isNotEmpty)
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? 'servicio' : 'servicios'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                ],
              ),
            ),
          ),

          // Lista de servicios
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _search.isEmpty
                          ? 'No hay servicios disponibles'
                          : 'No se encontraron resultados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _search.isEmpty
                          ? 'Vuelve más tarde'
                          : 'Intenta con otra búsqueda',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final g = filtered[index];
                    final imageUrl = g.imageUrls.isNotEmpty
                        ? buildImageUrl(g.imageUrls.first)
                        : null;

                    return ServiceCard(
                      title: g.title,
                      category: g.category,
                      price: g.price,
                      imageUrl: imageUrl,
                      rating: 4.5, // TODO: Obtener rating real
                      onTap: () => _createOrder(g),
                      onChat: () => _openChat(g),
                      onHire: () => _createOrder(g),
                    )
                        .animate()
                        .fadeIn(
                          delay: (index * 50).ms,
                          duration: 400.ms,
                        )
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          delay: (index * 50).ms,
                        );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
