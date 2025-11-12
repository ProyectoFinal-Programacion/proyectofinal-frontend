import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../models/models.dart';

class WorkerDetailScreen extends StatefulWidget {
  final int workerId;
  const WorkerDetailScreen({super.key, required this.workerId});

  @override
  State<WorkerDetailScreen> createState() => _WorkerDetailScreenState();
}

class _WorkerDetailScreenState extends State<WorkerDetailScreen> {
  late Future<WorkerProfile> _future;

  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _future = api.getWorker(widget.workerId).then((j) => WorkerProfile.fromJson(j));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil del Trabajador')),
      body: FutureBuilder<WorkerProfile>(
        future: _future,
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final w = s.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(radius: 32, child: Text(w.trade.isNotEmpty ? w.trade[0] : '?')),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.trade, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(w.zone),
                    Text('Rating: ${w.averageRating.toStringAsFixed(1)}'),
                  ])),
                ]),
                const SizedBox(height: 16),
                Text(w.bio),
                const SizedBox(height: 16),
                Row(children: [
                  FilledButton.icon(
                    onPressed: w.phoneNumber == null ? null : () async {
                      try {
                        final api = context.read<ApiClient>();
                        final link = await api.workerWhatsAppLink(w.id, 'Hola! Te contacto desde ManoVecina.');
                        final url = Uri.parse(link['link']);
                        if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Contactar por WhatsApp'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _createRequestDialog(context, w),
                    icon: const Icon(Icons.send),
                    label: const Text('Solicitar servicio'),
                  ),
                ]),
                const SizedBox(height: 24),
                FilledButton.tonal(
                  onPressed: () => _openReviews(context, w.id),
                  child: const Text('Ver reseñas'),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _createRequestDialog(BuildContext context, WorkerProfile w) async {
    final serviceIdController = TextEditingController();
    await showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Nueva solicitud'),
        content: TextField(
          controller: serviceIdController,
          decoration: const InputDecoration(labelText: 'Service ID (numérico)'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final id = int.tryParse(serviceIdController.text);
              if (id == null) return;
              try {
                await context.read<ApiClient>().createRequest(workerId: w.userId, serviceId: id);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitud creada')));
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Enviar'),
          )
        ],
      );
    });
  }

  void _openReviews(BuildContext context, int workerProfileId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _ReviewsScreen(workerProfileId: workerProfileId)));
  }
}

class _ReviewsScreen extends StatefulWidget {
  final int workerProfileId;
  const _ReviewsScreen({required this.workerProfileId});

  @override
  State<_ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<_ReviewsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    final api = context.read<ApiClient>();
    _future = api.reviewsForWorker(widget.workerProfileId).then((l) => l.cast<Map<String, dynamic>>());
  }

  @override
  Widget build(BuildContext context) {
    final ratingCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final reviews = s.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = reviews[i];
                    return ListTile(
                      leading: const Icon(Icons.star),
                      title: Text('Puntaje: ${r['rating']}'),
                      subtitle: Text(r['comment'] ?? ''),
                      trailing: Text((r['date'] ?? '').toString().substring(0, 10)),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: ratingCtrl, decoration: const InputDecoration(labelText: '1-5'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: commentCtrl, decoration: const InputDecoration(labelText: 'Comentario'))),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final rating = int.tryParse(ratingCtrl.text) ?? 5;
                        try {
                          await context.read<ApiClient>().createReview(workerId: widget.workerProfileId, rating: rating, comment: commentCtrl.text);
                          final api = context.read<ApiClient>();
                          final list = await api.reviewsForWorker(widget.workerProfileId);
                          setState(() => _future = Future.value(list.cast<Map<String, dynamic>>());
                        } catch (e) {
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      },
                      child: const Text('Enviar'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
