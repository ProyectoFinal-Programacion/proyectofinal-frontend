import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/geoapify_service.dart';

class AddressResult {
  final String address;
  final double lat;
  final double lon;

  AddressResult({
    required this.address,
    required this.lat,
    required this.lon,
  });
}

class AddressPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? initialAddress;

  const AddressPickerScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialAddress,
  });

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final GeoapifyService _geoapify = GeoapifyService();

  LatLng? _selected;
  String? _address;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      LatLng? initial;

      if (widget.initialLat != null && widget.initialLon != null) {
        initial = LatLng(widget.initialLat!, widget.initialLon!);
      } else {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          setState(() {
            _loading = false;
            _error = 'No se pudo obtener permisos de ubicación.';
          });
          return;
        }

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        initial = LatLng(pos.latitude, pos.longitude);
      }

      String? addr = widget.initialAddress;
      addr ??= await _geoapify.reverseGeocode(
        initial.latitude,
        initial.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selected = initial;
        _address = addr;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Error al cargar mapa: $e';
      });
    }
  }

  Future<void> _onTapMap(TapPosition tapPos, LatLng latLng) async {
    setState(() {
      _selected = latLng;
      _address = null;
      _loading = true;
    });

    try {
      final addr = await _geoapify.reverseGeocode(
        latLng.latitude,
        latLng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _address = addr ?? 'Dirección no encontrada';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _address = 'Error al obtener dirección';
        _loading = false;
      });
    }
  }

  void _confirm() {
    if (_selected == null || _address == null || _address!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Selecciona una ubicación válida antes de confirmar.'),
        ),
      );
      return;
    }

    final result = AddressResult(
      address: _address!,
      lat: _selected!.latitude,
      lon: _selected!.longitude,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegir ubicación'),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : selected == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: selected,
                          initialZoom: 15,
                          onTap: _onTapMap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${GeoapifyService.apiKey}',
                            userAgentPackageName:
                                'com.example.manovecina', // cambia si quieres
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: selected,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey.shade100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dirección seleccionada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _loading && _address == null
                              ? const LinearProgressIndicator()
                              : Text(
                                  _address ?? 'Toca el mapa para elegir lugar',
                                  style: const TextStyle(fontSize: 13),
                                ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirm,
                              child: const Text('Usar esta ubicación'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
