import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/orders_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/primary_button.dart';
import '../common/address_picker_screen.dart';

class ClientCreateOrderScreen extends StatefulWidget {
  final Gig gig;
  final int workerId;

  const ClientCreateOrderScreen({
    super.key,
    required this.gig,
    required this.workerId,
  });

  @override
  State<ClientCreateOrderScreen> createState() =>
      _ClientCreateOrderScreenState();
}

class _ClientCreateOrderScreenState extends State<ClientCreateOrderScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  double? _lat;
  double? _lon;

  bool _loading = false;

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<AddressResult>(
      MaterialPageRoute(
        builder: (_) => const AddressPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result.address;
        _lat = result.lat;
        _lon = result.lon;
      });
    }
  }

  Future<void> _createOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe seleccionar una dirección.")),
      );
      return;
    }

    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debe escribir una descripción.")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final service = OrdersService(api);

      await service.createOrder(
        workerId: widget.workerId,
        gigId: widget.gig.id,
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        totalPrice: widget.gig.price, // precio provisto por el gig
        latitude: _lat,
        longitude: _lon,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Orden creada correctamente")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al crear la orden: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gig;

    return Scaffold(
      appBar: AppBar(
        title: Text("Contratar a ${g.workerName ?? "Trabajador"}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              g.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),
            Text(g.description ?? ""),

            const SizedBox(height: 16),

            // ---------- GALERÍA DE IMÁGENES ----------
            if (g.imageUrls.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: g.imageUrls.length,
                  itemBuilder: (context, imgIndex) {
                    final imageUrl = "${buildImageUrl(g.imageUrls[imgIndex])}?v=${DateTime.now().millisecondsSinceEpoch}";
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          // Mostrar imagen en pantalla completa
                          _showFullImage(context, imageUrl);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Error cargando imagen', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
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
                    '${g.imageUrls.length} imágenes - Toca para ampliar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],

            // ---------- DIRECCIÓN ----------
            Text(
              "Dirección",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: "Selecciona una ubicación en el mapa",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.map, size: 32),
                  onPressed: _pickOnMap,
                ),
              ],
            ),

            if (_lat != null && _lon != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Lat: $_lat, Lon: $_lon",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ),

            const SizedBox(height: 20),

            // ---------- DESCRIPCIÓN ----------
            Text(
              "Descripción del trabajo",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Ej: Necesito ayuda con...",
              ),
            ),

            const SizedBox(height: 25),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    onPressed: _createOrder,
                    child: const Text('Confirmar orden'),
                  ),
          ],
        ),
      ),
    );
  }
}
