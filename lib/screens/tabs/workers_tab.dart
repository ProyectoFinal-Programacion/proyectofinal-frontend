import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../models/models.dart';
import '../worker_detail_screen.dart';

class WorkersTab extends StatefulWidget {
  const WorkersTab({super.key});
  @override
  State<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<WorkersTab> {
  late Future<List<WorkerProfile>> _future;
  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _future = api.listWorkers().then((l) => l.map((e) => WorkerProfile.fromJson(e)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkerProfile>>(
      future: _future,
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final items = s.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final w = items[i];
            return ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerDetailScreen(workerId: w.id))),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              leading: CircleAvatar(child: Text(w.trade.isEmpty ? '?' : w.trade[0])),
              title: Text('${w.trade} • ${w.zone}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(w.bio, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 16),
                  Text(w.averageRating.toStringAsFixed(1)),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        );
      },
    );
  }
}
