import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';
import '../create_service_screen.dart';
import '../../providers/auth_provider.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});
  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  late Future<List<Service>> _future;
  List<Service> _all = [];
  final _search = TextEditingController();
  final _categories = ['Hogar', 'Reparaciones', 'Electricidad', 'Construcción', 'Limpieza'];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _future = api.listServices().then((l) => l.map((e) => Service.fromJson(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return FutureBuilder<List<Service>>(
      future: _future,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text('Error: ${s.error}'));
        _all = s.data ?? [];
        final q = _search.text.toLowerCase();
        final filtered = _all.where((sv) {
          final okQ = q.isEmpty || sv.name.toLowerCase().contains(q) || sv.description.toLowerCase().contains(q);
          final okC = _selectedCategory == null || sv.category.toLowerCase() == _selectedCategory!.toLowerCase();
          return okQ && okC;
        }).toList();

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar servicios...'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final label = i == 0 ? 'Todos' : _categories[i-1];
                    final selected = (i == 0 && _selectedCategory == null) || (_selectedCategory == label);
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedCategory = i == 0 ? null : label),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ...filtered.map((sv) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(sv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(sv.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(sv.category),
                ),
              )),
            ],
          ),
          floatingActionButton: (auth.role == 'Worker' || auth.role == 'Admin')
              ? FloatingActionButton(
                  onPressed: () async {
                    final created = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateServiceScreen()));
                    if (created == true) {
                      final api = context.read<ApiClient>();
                      final list = await api.listServices();
                      setState(() => _future = Future.value(list.map((e) => Service.fromJson(e)).toList()));
                    }
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}
