import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/gigs_service.dart';
import '../../services/uploads_service.dart';
import '../../widgets/primary_button.dart';

class WorkerCreateGigScreen extends StatefulWidget {
  const WorkerCreateGigScreen({super.key});

  @override
  State<WorkerCreateGigScreen> createState() => _WorkerCreateGigScreenState();
}

class _WorkerCreateGigScreenState extends State<WorkerCreateGigScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // PARA WEB
  List<Uint8List> _webImages = [];

  // PARA MÓVIL
  List<File> _mobileImages = [];

  bool _loading = false;

  // ============================================================
  // PICK MULTIPLE IMAGES
  // ============================================================
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picks = await picker.pickMultiImage();

    if (picks.isEmpty) return;

    if (kIsWeb) {
      final imgs = <Uint8List>[];
      for (final p in picks) {
        imgs.add(await p.readAsBytes());
      }
      setState(() => _webImages = imgs);
    } else {
      setState(() {
        _mobileImages = picks.map((e) => File(e.path)).toList();
      });
    }
  }

  // ============================================================
  // CREATE GIG + UPLOAD IMAGES
  // ============================================================
  Future<void> _createGig() async {
    if (_titleCtrl.text.isEmpty ||
        _categoryCtrl.text.isEmpty ||
        _priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos requeridos")),
      );
      return;
    }

    final price = double.tryParse(_priceCtrl.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Precio inválido")),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final gigs = GigsService(api);
      final uploads = UploadsService(api);

      // CREAR GIG
      final gig = await gigs.createGig(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _categoryCtrl.text,
        price: price,
      );

      // SUBIR IMÁGENES
      if (kIsWeb) {
        for (final bytes in _webImages) {
          await uploads.uploadGigImage(gig.id, bytes);
        }
      } else {
        for (final file in _mobileImages) {
          await uploads.uploadGigImage(gig.id, file);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));

    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    final hasImages = isWeb
        ? _webImages.isNotEmpty
        : _mobileImages.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear servicio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _categoryCtrl,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            if (hasImages)
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      isWeb ? _webImages.length : _mobileImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final img = isWeb
                        ? Image.memory(_webImages[i], fit: BoxFit.cover)
                        : Image.file(_mobileImages[i], fit: BoxFit.cover);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 200,
                        height: 160,
                        child: img,
                      ),
                    );
                  },
                ),
              ),

            Row(
              children: [
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Seleccionar imágenes'),
                ),
                const Spacer(),
                PrimaryButton(
                  onPressed: _loading ? null : _createGig,
                  loading: _loading,
                  child: const Text('Crear servicio'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
