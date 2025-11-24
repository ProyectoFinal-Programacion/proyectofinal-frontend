import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/orders_service.dart';
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

            const SizedBox(height: 20),

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
