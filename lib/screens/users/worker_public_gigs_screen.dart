import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/gigs_service.dart';
import '../../utils/image_utils.dart';
import '../client/client_create_order_screen.dart';

class WorkerPublicGigsScreen extends StatefulWidget {
  final int workerId;
  const WorkerPublicGigsScreen({super.key, required this.workerId});

  @override
  State<WorkerPublicGigsScreen> createState() => _WorkerPublicGigsScreenState();
}

class _WorkerPublicGigsScreenState extends State<WorkerPublicGigsScreen> {
  bool _loading = true;
  List<Gig> _gigs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);
      final api = context.read<ApiClient>();
      final gigsService = GigsService(api);
      final list = await gigsService.getWorkerGigs(widget.workerId);
      if (!mounted) return;
      setState(() {
        _gigs = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando servicios: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servicios del trabajador')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _gigs.isEmpty
              ? const Center(child: Text('No se encontraron servicios'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _gigs.length,
                  itemBuilder: (_, i) {
                    final g = _gigs[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Galería de imágenes horizontal
                            if (g.imageUrls.isNotEmpty) ...[
                              SizedBox(
                                height: 160,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: g.imageUrls.length,
                                  itemBuilder: (context, imgIndex) {
                                    final imageUrl = "${buildImageUrl(g.imageUrls[imgIndex])}?v=${DateTime.now().millisecondsSinceEpoch}";
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 160,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 160,
                                            height: 160,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, size: 32),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (g.imageUrls.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${g.imageUrls.length} imágenes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Información del servicio
                            Text(
                              g.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (g.category != null && g.category!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                g.category!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Bs ${g.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Botón contratar
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => ClientCreateOrderScreen(
                                      gig: g,
                                      workerId: widget.workerId,
                                    ),
                                  ));
                                },
                                child: const Text('Contratar'),
                              ),
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
