import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/enums.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../utils/image_utils.dart';
import 'admin_create_user_screen.dart';
import '../../widgets/common/premium_cards.dart';
import '../../widgets/common/premium_inputs.dart';
import '../../widgets/common/custom_loading.dart';
import '../../widgets/admin/admin_drawer.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> users = [];
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
      final admin = AdminService(api);
      final data = await admin.getUsers();
      if (!mounted) return;
      setState(() {
        users = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _toggleBan(int id, bool isBanned) async {
    final api = context.read<ApiClient>();
    final admin = AdminService(api);

    try {
      if (isBanned) {
        await admin.unbanUser(id);
      } else {
        await admin.banUser(id);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a "$name"? '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final api = context.read<ApiClient>();
      final admin = AdminService(api);
      await admin.deleteUser(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _goToCreateUser() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminCreateUserScreen()),
    );
    if (created == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CustomLoading(message: "Cargando usuarios..."));
    }

    // Determinar si mostrar botón de menú o atrás
    final canPop = Navigator.canPop(context);

    return Scaffold(
      // Si podemos volver atrás, no necesitamos drawer aquí (o podemos tenerlo pero no accesible via menu)
      // Si estamos en la shell (tab), necesitamos drawer.
      // Pero como no sabemos si estamos en shell o push, usamos canPop.
      drawer: canPop ? null : AdminDrawer(
        currentIndex: 1, // Index de usuarios
        onNavigate: (i) {
          // Si estamos en shell, esto no funcionará bien porque no tenemos acceso al setState de shell.
          // Pero si AdminUsersScreen es hijo directo de AdminShell, el drawer de AdminShell debería usarse.
          // El problema es que AdminUsersScreen tiene su propio Scaffold.
          // Si usamos AdminDrawer aquí, funcionará localmente.
          // Pero para cambiar de tab en la shell, necesitamos el callback.
          // Como no lo tenemos aquí, simplemente hacemos pop si es navegación, o nada.
          // Mejor solución: AdminDrawer debería ser capaz de navegar.
          // Pero AdminDrawer recibe onNavigate.
          // Aquí no tenemos onNavigate.
          // Así que si usamos AdminDrawer aquí, solo servirá para Logout o ver info, no para cambiar tabs.
          // A MENOS que usemos un Provider para la navegación global.
          // Por ahora, dejemos que el drawer solo funcione en la Shell principal.
          // Si estamos en AdminUsersScreen como TAB, el Scaffold de Shell NO se ve porque este Scaffold lo tapa.
          // Así que necesitamos Drawer aquí.
          // Y necesitamos que funcione.
          // Asumiremos que si se selecciona un item, hacemos pushReplacement o similar? No, eso rompe la shell.
          
          // SOLUCIÓN TEMPORAL: Mostrar mensaje o simplemente no implementar navegación compleja desde aquí si no es via Shell.
          // O mejor: Si estamos en TAB, el usuario usa el drawer para ir a otro lado.
          // Si estamos en PUSH (desde dashboard), el usuario usa BACK.
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreateUser,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Gestión de Usuarios',
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = users[index];
                  final name = user['name'] ?? '';
                  final email = user['email'] ?? '';
                  final banned = user['isBanned'] ?? false;
                  final int role = user['role'] ?? 0;
                  final String? imageUrl = user['imageUrl'];

                  final Color roleColor = role == UserRole.admin.index
                      ? Colors.blue.shade600
                      : role == UserRole.worker.index
                          ? Colors.orange.shade600
                          : Colors.green.shade600;

                  final String roleText = role == UserRole.admin.index
                      ? 'Admin'
                      : role == UserRole.worker.index
                          ? 'Trabajador'
                          : 'Cliente';

                  return PremiumCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: roleColor.withOpacity(0.1),
                              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                  ? NetworkImage(buildImageUrl(imageUrl))
                                  : null,
                              child: (imageUrl == null || imageUrl.isEmpty)
                                  ? Text(
                                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: roleColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                roleText,
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              banned ? 'Baneado' : 'Activo',
                              style: TextStyle(
                                color: banned ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                banned ? Icons.check_circle_outline : Icons.block,
                                color: banned ? Colors.green : Colors.orange,
                              ),
                              tooltip: banned ? 'Desbanear' : 'Banear',
                              onPressed: () => _toggleBan(user['id'] as int, banned),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Eliminar',
                              onPressed: () => _deleteUser(user['id'] as int, name),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 50).ms).slideX();
                },
                childCount: users.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
