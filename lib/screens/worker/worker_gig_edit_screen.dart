import 'dart:typed_data';
import 'dart:io' as io;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/gig.dart';
import '../../services/api_client.dart';
import '../../services/gigs_service.dart';
import '../../services/uploads_service.dart';
import '../../utils/image_utils.dart';
import '../../widgets/primary_button.dart';

class WorkerGigEditScreen extends StatefulWidget {
  final Gig gig;

  const WorkerGigEditScreen({super.key, required this.gig});

  @override
  State<WorkerGigEditScreen> createState() => _WorkerGigEditScreenState();
}

class _WorkerGigEditScreenState extends State<WorkerGigEditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _priceCtrl;

  // Lista de imágenes nuevas a subir
  List<Uint8List> _webImages = [];
  List<io.File> _mobileImages = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final g = widget.gig;

    _titleCtrl = TextEditingController(text: g.title);
    _descCtrl = TextEditingController(text: g.description ?? "");
    _categoryCtrl = TextEditingController(text: g.category ?? "");
    _priceCtrl = TextEditingController(text: g.price.toString());
  }

  // ============================================================
  // PICK IMAGES (permite múltiples)
  // ============================================================
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    
    // Permitir seleccionar múltiples imágenes
    final List<XFile> pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    if (kIsWeb) {
      final List<Uint8List> newBytes = [];
      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        newBytes.add(bytes);
      }
      setState(() {
        _webImages.addAll(newBytes);
        _mobileImages.clear();
      });
    } else {
      final List<io.File> newFiles = pickedFiles.map((f) => io.File(f.path)).toList();
      setState(() {
        _mobileImages.addAll(newFiles);
        _webImages.clear();
      });
    }
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================
  Future<void> _save() async {
    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final gigs = GigsService(api);
      final uploads = UploadsService(api);

      // 1. Actualizar los datos del gig
      await gigs.updateGig(
        widget.gig.id,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _categoryCtrl.text,
        price: double.parse(_priceCtrl.text),
      );

      // 2. Subir todas las imágenes nuevas
      if (kIsWeb) {
        for (var bytes in _webImages) {
          await uploads.uploadGigImage(widget.gig.id, bytes);
        }
      } else {
        for (var file in _mobileImages) {
          await uploads.uploadGigImage(widget.gig.id, file);
        }
      }

      // 3. 🔥 SOLUCIÓN: Recargar el gig completo desde el servidor
      // Esto asegura que tengamos todas las imágenes actualizadas
      final updatedGig = await gigs.getGig(widget.gig.id);
      
      // Actualizar el objeto gig con los datos frescos
      widget.gig.imageUrls.clear();
      widget.gig.imageUrls.addAll(updatedGig.imageUrls);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final g = widget.gig;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar servicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Mostrar imágenes existentes del servidor
            if (g.imageUrls.isNotEmpty) ...[
              const Text('Imágenes actuales:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: g.imageUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = buildImageUrl(g.imageUrls[index]);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Mostrar nuevas imágenes seleccionadas (aún no subidas)
            if (_webImages.isNotEmpty || _mobileImages.isNotEmpty) ...[
              const Text('Nuevas imágenes a subir:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kIsWeb ? _webImages.length : _mobileImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(
                                _webImages[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _mobileImages[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Añadir imágenes'),
                ),
                const Spacer(),
                PrimaryButton(
                  onPressed: _loading ? null : _save,
                  loading: _loading,
                  child: const Text('Guardar cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
