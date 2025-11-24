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

  Uint8List? _webImageBytes;
  io.File? _mobileImage;

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
  // PICK IMAGE
  // ============================================================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
        _mobileImage = null;
      });
    } else {
      setState(() {
        _mobileImage = io.File(picked.path);
        _webImageBytes = null;
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

      // Actualizar los datos del gig
      await gigs.updateGig(
        widget.gig.id,
        title: _titleCtrl.text,
        description: _descCtrl.text,
        category: _categoryCtrl.text,
        price: double.parse(_priceCtrl.text),
      );

      // Subir nueva imagen si existe
      String? newUrl;

      if (kIsWeb && _webImageBytes != null) {
        newUrl = await uploads.uploadGigImage(widget.gig.id, _webImageBytes!);
      } else if (!kIsWeb && _mobileImage != null) {
        newUrl = await uploads.uploadGigImage(widget.gig.id, _mobileImage!);
      }

      // 📌 Si hubo nueva imagen, reemplazar lista
      if (newUrl != null && newUrl.isNotEmpty) {
  final fullUrl = buildImageUrl(newUrl);  // ← ESTO YA ES String
  widget.gig.imageUrls
    ..clear()
    ..add(fullUrl); // 👈 YA NO MARCA ERROR
}


      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
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

    Widget? preview;

    String? firstImage =
        g.imageUrls.isNotEmpty ? g.imageUrls.first : null;

    // Mostrar imagen actual si no se eligió nueva
    if (_webImageBytes == null &&
        _mobileImage == null &&
        firstImage != null) {
      final fullUrl =
          '${buildImageUrl(firstImage)}?t=${DateTime.now().millisecondsSinceEpoch}';

      preview = Image.network(
        fullUrl,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
      );
    }

    if (kIsWeb && _webImageBytes != null) {
      preview = Image.memory(
        _webImageBytes!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (!kIsWeb && _mobileImage != null) {
      preview = Image.file(
        _mobileImage!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

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

            if (preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: preview,
              ),

            Row(
              children: [
                TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Cambiar imagen')),
                const Spacer(),
                PrimaryButton(onPressed: _loading ? null : _save, loading: _loading, child: const Text('Guardar cambios')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
