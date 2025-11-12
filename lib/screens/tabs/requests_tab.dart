import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});
  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  late Future<List<ServiceRequest>> _future;
  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _future = api.listRequests().then((l) => l.map((e) => ServiceRequest.fromJson(e)).toList());
  }

  Future<void> _refresh() async {
    final api = context.read<ApiClient>();
    final data = await api.listRequests();
    setState(() => _future = Future.value(data.map((e) => ServiceRequest.fromJson(e)).toList()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServiceRequest>>(
      future: _future,
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text('Error: ${s.error}'));
        final items = s.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Sin solicitudes aún'));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = items[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text('Solicitud #${r.id} — ${r.status}'),
                  subtitle: Text('Servicio ${r.serviceId} • ${DateFormat.yMMMd().add_jm().format(r.dateRequested.toLocal())}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      try {
                        await context.read<ApiClient>().updateRequestStatus(r.id, v);
                        await _refresh();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'Accepted', child: Text('Marcar aceptada (Worker)')),
                      PopupMenuItem(value: 'Completed', child: Text('Marcar completada (Client/Worker)')),
                      PopupMenuItem(value: 'Canceled', child: Text('Cancelar (Client)')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
