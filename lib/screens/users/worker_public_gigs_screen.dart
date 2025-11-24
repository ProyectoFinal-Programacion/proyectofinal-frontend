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
                  itemCount: _gigs.length,
                  itemBuilder: (_, i) {
                    final g = _gigs[i];

                    String? mainImage;
                    if (g.imageUrls.isNotEmpty) {
                      final relative = g.imageUrls.first;
                      mainImage = "${buildImageUrl(relative)}?v=${DateTime.now().millisecondsSinceEpoch}";
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
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              )
                            : const Icon(Icons.build, size: 32),
                        title: Text(g.title),
                        subtitle: Text(g.category ?? ''),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Bs ${g.price.toStringAsFixed(2)}'),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ClientCreateOrderScreen(gig: g, workerId: widget.workerId),
                                ));
                              },
                              child: const Text('Contratar'),
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
