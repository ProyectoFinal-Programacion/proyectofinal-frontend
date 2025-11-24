import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/api_client.dart';
import '../../services/workers_service.dart';
import '../../models/worker_search_result.dart';
import '../../services/geoapify_service.dart';
import '../../utils/image_utils.dart';
import '../users/user_public_profile_screen.dart';
import '../users/worker_public_gigs_screen.dart';


class WorkerMapScreen extends StatefulWidget {
  const WorkerMapScreen({super.key});

  @override
  State<WorkerMapScreen> createState() => _WorkerMapScreenState();
}

class _WorkerMapScreenState extends State<WorkerMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _myLocation;
  bool _loading = true;
  List<WorkerSearchResult> _workers = [];
  double _radiusKm = 10;

  // filtros y estado de búsqueda
  List<WorkerSearchResult> _filteredWorkers = [];
  String _query = '';
  double _minPriceFilter = 0;
  double _maxPriceFilter = 500;
  double _globalMinPrice = 0;
  double _globalMaxPrice = 500;

  // ordenar por: nearest | bestRated
  String _sortMode = 'nearest';

  StreamSubscription<Position>? _positionSub;

  WorkerSearchResult? _selectedWorker;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final pos = await _getLocation();
      final myLatLng = LatLng(pos.latitude, pos.longitude);

      final api = context.read<ApiClient>();
      final service = WorkersService(api);

      final results = await service.searchWorkers(
        lat: pos.latitude,
        lon: pos.longitude,
        radiusKm: _radiusKm,
      );

      setState(() {
        _myLocation = myLatLng;
        _workers = results;
        _computePriceBounds();
        _applyFilters();
        _loading = false;
        _selectedWorker = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(_myLocation!, 14);
        } catch (_) {}
      });

      // Suscribirse a cambios de ubicación para actualizar en tiempo real
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 20,
        ),
      ).listen((Position p) async {
        if (!mounted) return;
        final newLat = LatLng(p.latitude, p.longitude);
        // calcular distancia en metros desde la ubicación previa
        double movedMeters = 0;
        if (_myLocation != null) {
          movedMeters = Geolocator.distanceBetween(
            _myLocation!.latitude,
            _myLocation!.longitude,
            p.latitude,
            p.longitude,
          );
        }

        setState(() {
          _myLocation = newLat;
        });

        try {
          _mapController.move(newLat, _mapController.zoom);
        } catch (_) {}

        // Si se movió más de 50 metros, recargar resultados por cercanía
        if (movedMeters > 50) {
          try {
            final api2 = context.read<ApiClient>();
            final service2 = WorkersService(api2);
            final results2 = await service2.searchWorkers(
              lat: p.latitude,
              lon: p.longitude,
              radiusKm: _radiusKm,
            );
            if (!mounted) return;
            setState(() {
              _workers = results2;
              _computePriceBounds();
              _applyFilters();
            });
          } catch (_) {}
        }
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error obteniendo datos: $e')),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _computePriceBounds() {
    final prices = _workers
        .map((w) => (w.basePrice ?? 0).toDouble())
        .toList(growable: false);
    if (prices.isEmpty) {
      _globalMinPrice = 0;
      _globalMaxPrice = 500;
      _minPriceFilter = 0;
      _maxPriceFilter = 500;
      return;
    }
    prices.sort();
    _globalMinPrice = prices.first;
    _globalMaxPrice = prices.last;
    _minPriceFilter = _globalMinPrice;
    _maxPriceFilter = _globalMaxPrice;
  }

  void _applyFilters() {
    final q = _query.trim().toLowerCase();
    final filtered = _workers.where((w) {
      final price = (w.basePrice ?? 0).toDouble();
      final matchesPrice = price >= _minPriceFilter && price <= _maxPriceFilter;
      final matchesQuery = q.isEmpty || (w.name.toLowerCase().contains(q));
      return matchesPrice && matchesQuery;
    }).toList(growable: false);

    if (_sortMode == 'best') {
      filtered.sort((a, b) => (b.averageRating).compareTo(a.averageRating));
    } else if (_sortMode == 'price_asc') {
      filtered.sort((a, b) => ((a.basePrice ?? 0)).compareTo((b.basePrice ?? 0)));
    } else if (_sortMode == 'price_desc') {
      filtered.sort((a, b) => ((b.basePrice ?? 0)).compareTo((a.basePrice ?? 0)));
    } else {
      // nearest: si distancia disponible, ordenar por distanceKm
      filtered.sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });
    }

    setState(() {
      _filteredWorkers = filtered;
    });
  }

  Future<Position> _getLocation() async {
    LocationPermission p = await Geolocator.checkPermission();

    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      p = await Geolocator.requestPermission();
    }

    return Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _myLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trabajadores cercanos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Trabajadores cercanos')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation!,
              initialZoom: 14,
              onTap: (_, __) {
                setState(() => _selectedWorker = null);
              },
              interactiveFlags: InteractiveFlag.all - InteractiveFlag.rotate,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${GeoapifyService.apiKey}',
                userAgentPackageName: 'com.manovecina.app',
              ),

              // Marcador del usuario
              MarkerLayer(
                markers: [
                  Marker(
                    point: _myLocation!,
                    width: 45,
                    height: 45,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),

              // Marcadores de trabajadores
              MarkerLayer(
                markers: _filteredWorkers.map((w) {
                  final point = LatLng(
                    w.latitude ?? _myLocation!.latitude,
                    w.longitude ?? _myLocation!.longitude,
                  );

                  return Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        try {
                          _mapController.move(point, _mapController.zoom);
                        } catch (_) {}
                        setState(() {
                          _selectedWorker = w;
                        });
                      },
                      child: Tooltip(
                        message: w.name,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: (w.imageUrl != null && w.imageUrl!.isNotEmpty)
                              ? NetworkImage(buildImageUrl(w.imageUrl!)) as ImageProvider
                              : null,
                          child: (w.imageUrl == null || w.imageUrl!.isEmpty)
                              ? const Icon(Icons.person_pin, color: Colors.red)
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Barra de búsqueda y botón de filtros
          Positioned(
            top: 10,
            left: 12,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre o servicio',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        _query = v;
                        _applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón de filtros
          Positioned(
            top: 10,
            right: 12,
            child: FloatingActionButton(
              mini: true,
              onPressed: () async {
                final result = await showModalBottomSheet<bool>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) {
                    double localMin = _minPriceFilter;
                    double localMax = _maxPriceFilter;
                    String localSort = _sortMode;
                    return StatefulBuilder(
                      builder: (context, setLocal) {
                        return Padding(
                              padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Filtrar por precio'),
                                    const SizedBox(height: 8),
                                    // Presets rápidos
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            setLocal(() {
                                              localMin = _globalMinPrice;
                                              localMax = _globalMaxPrice;
                                            });
                                          },
                                          child: const Text('Todos'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setLocal(() {
                                              localMin = _globalMinPrice;
                                              localMax = (_globalMinPrice + (_globalMinPrice + 50)) / 2; // aproximado
                                            });
                                          },
                                          child: const Text('< Bs50'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setLocal(() {
                                              localMin = 50;
                                              localMax = 150;
                                            });
                                          },
                                          child: const Text('50 - 150'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setLocal(() {
                                              localMin = 150;
                                              localMax = _globalMaxPrice;
                                            });
                                          },
                                          child: const Text('> 150'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    RangeSlider(
                                      min: _globalMinPrice,
                                      max: _globalMaxPrice <= _globalMinPrice ? _globalMinPrice + 1 : _globalMaxPrice,
                                      values: RangeValues(localMin.clamp(_globalMinPrice, _globalMaxPrice), localMax.clamp(_globalMinPrice, _globalMaxPrice)),
                                      labels: RangeLabels('\Bs ${localMin.toInt()}', '\Bs ${localMax.toInt()}'),
                                      onChanged: (r) {
                                        setLocal(() {
                                          localMin = r.start;
                                          localMax = r.end;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Ordenar por'),
                                    RadioListTile<String>(
                                      title: const Text('Más cercanos'),
                                      value: 'nearest',
                                      groupValue: localSort,
                                      onChanged: (v) => setLocal(() => localSort = v ?? 'nearest'),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Mejor calificados'),
                                      value: 'best',
                                      groupValue: localSort,
                                      onChanged: (v) => setLocal(() => localSort = v ?? 'best'),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Precio (menor primero)'),
                                      value: 'price_asc',
                                      groupValue: localSort,
                                      onChanged: (v) => setLocal(() => localSort = v ?? 'price_asc'),
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Precio (mayor primero)'),
                                      value: 'price_desc',
                                      groupValue: localSort,
                                      onChanged: (v) => setLocal(() => localSort = v ?? 'price_desc'),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            // aplicar filtros locales
                                            _minPriceFilter = localMin;
                                            _maxPriceFilter = localMax;
                                            _sortMode = localSort;
                                            Navigator.of(context).pop(true);
                                          },
                                          child: const Text('Aplicar'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            );
                      },
                    );
                  },
                );

                if (result == true) {
                  _applyFilters();
                }
              },
              child: const Icon(Icons.filter_list),
            ),
          ),

          // Filtro de distancia
          Positioned(
            top: 70,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButton<double>(
                value: _radiusKm,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 km')),
                  DropdownMenuItem(value: 10, child: Text('10 km')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _radiusKm = v);
                  _init(); // recargar resultados
                },
              ),
            ),
          ),

          // Panel inferior con info del trabajador seleccionado
          if (_selectedWorker != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildWorkerInfo(_selectedWorker!),
              ),
            ),

          // Botón para centrar en mi ubicación
          Positioned(
            right: 12,
            bottom: 96,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                if (_myLocation != null) {
                  try {
                    _mapController.move(_myLocation!, 14);
                  } catch (_) {}
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerInfo(WorkerSearchResult w) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          w.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text('Precio base: \$${w.basePrice ?? 0}'),
        Text('Distancia: ${w.distanceKm?.toStringAsFixed(2) ?? "?"} km'),
        Text('Rating: ⭐ ${w.averageRating.toStringAsFixed(1)}'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() => _selectedWorker = null);
              },
              child: const Text('Cerrar'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserPublicProfileScreen(userId: w.workerId),
                  ),
                );
              },
              child: const Text('Ver perfil'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkerPublicGigsScreen(workerId: w.workerId),
                  ),
                );
              },
              child: const Text('Ver servicios'),
            ),
          ],
        ),
      ],
    );
  }
}
