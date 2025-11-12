import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';

class CreateServiceScreen extends StatefulWidget {
  static const route = '/create-service';
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController(text: 'Hogar');
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar servicio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Título del servicio *')),
            const SizedBox(height: 8),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Descripción *'), maxLines: 3),
            const SizedBox(height: 8),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Categoría *')),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  await context.read<ApiClient>().createService(
                    name: _name.text.trim(),
                    description: _description.text.trim(),
                    category: _category.text.trim(),
                  );
                  if (mounted) Navigator.pop(context, true);
                } catch (e) {
                  setState(() => _error = e.toString());
                } finally {
                  setState(() => _loading = false);
                }
              },
              child: _loading ? const CircularProgressIndicator() : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
