import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/gigs_service.dart';
import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';

import 'worker_create_gig_screen.dart';
import 'worker_gig_edit_screen.dart';

class WorkerGigsScreen extends StatefulWidget {
  const WorkerGigsScreen({super.key});

  @override
  State<WorkerGigsScreen> createState() => _WorkerGigsScreenState();
}

class _WorkerGigsScreenState extends State<WorkerGigsScreen> {
  bool _loading = true;
  List<Gig> _gigs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // LOAD WORKER GIGS
  // ============================================================
  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final auth = context.read<AuthProvider>();
      final gigsService = GigsService(api);

      final me = auth.user!;
      final myGigs = await gigsService.getWorkerGigs(me.id);

      setState(() {
        _gigs = myGigs;
      });

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error al cargar: $e")));

    } finally {
      setState(() => _loading = false);
    }
  }

  // ============================================================
  // DELETE GIG
  // ============================================================
  Future<void> _delete(int id) async {
    final api = context.read<ApiClient>();
    final gigsService = GigsService(api);

    await gigsService.deleteGig(id);
    _load();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis servicios')),
      
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkerCreateGigScreen()),
          ).then((value) {
            if (value == true) _load();
          });
        },
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _gigs.isEmpty
              ? const Center(child: Text('No tienes servicios creados'))
              : ListView.builder(
                  itemCount: _gigs.length,
                  itemBuilder: (_, i) {
                    final g = _gigs[i];

                    // ========================================================
                    // IMAGEN PRINCIPAL — ARREGLADO ✔
                    // ========================================================
                    String? mainImage;

                    if (g.imageUrls.isNotEmpty) {
                      // Siempre normalizamos
                      final relative = g.imageUrls.first;

                      // Construimos URL absoluta correcta
                      mainImage =
                          "${buildImageUrl(relative)}?v=${DateTime.now().millisecondsSinceEpoch}";
                    }

                    return Card(
                      child: ListTile(
                        leading: mainImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  mainImage,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,

                                  // Si falla carga → ícono
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              )
                            : const Icon(Icons.build, size: 32),
                        
                        title: Text(g.title),
                        subtitle: Text(g.category ?? ''),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WorkerGigEditScreen(gig: g),
                                  ),
                                ).then((value) {
                                  if (value == true) _load();
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _delete(g.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
