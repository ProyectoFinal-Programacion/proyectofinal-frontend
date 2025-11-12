import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  static const route = '/worker-onboarding';
  const WorkerOnboardingScreen({super.key});

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  final _trade = TextEditingController();
  final _zone = TextEditingController();
  final _years = TextEditingController();
  final _bio = TextEditingController();
  final _availability = TextEditingController(text: 'Disponible');
  final _phone = TextEditingController();
  final _photo = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar perfil (Fiverr style)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tu oficio y experiencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: _trade, decoration: const InputDecoration(labelText: 'Oficio (ej. Plomería) *')),
            const SizedBox(height: 8),
            TextField(controller: _zone, decoration: const InputDecoration(labelText: 'Zona *')),
            const SizedBox(height: 8),
            TextField(controller: _years, decoration: const InputDecoration(labelText: 'Años de experiencia *'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio / Especialidades'), maxLines: 4),
            const SizedBox(height: 8),
            TextField(controller: _availability, decoration: const InputDecoration(labelText: 'Disponibilidad (ej. Lun–Vie 9–18)')),
            const SizedBox(height: 8),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp')),
            const SizedBox(height: 8),
            TextField(controller: _photo, decoration: const InputDecoration(labelText: 'Foto URL (opcional)')),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  final years = _years.text.trim();
                  final bio = _bio.text.trim();
                  final composedBio = [
                    if (bio.isNotEmpty) bio,
                    if (years.isNotEmpty) 'Experiencia: $years año(s)',
                  ].join(' • ');
                  await context.read<ApiClient>().createWorkerProfile(
                    trade: _trade.text.trim(),
                    zone: _zone.text.trim(),
                    bio: composedBio,
                    availability: _availability.text.trim().isEmpty ? 'Disponible' : _availability.text.trim(),
                    phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                    photoUrl: _photo.text.trim().isNotEmpty ? _photo.text.trim() : null,
                    galleryUrls: null,
                  );
                  if (mounted) Navigator.pop(context, true);
                } catch (e) {
                  setState(() => _error = e.toString());
                } finally {
                  setState(() => _loading = false);
                }
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Crear perfil'),
            )
          ],
        ),
      ),
    );
  }
}
