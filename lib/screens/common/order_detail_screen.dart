import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/enums.dart';
import '../../services/api_client.dart';
import '../../services/orders_service.dart';
import '../../services/reviews_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../utils/image_utils.dart';
import 'chat_screen.dart';
import '../users/client_profile_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = false;

  Future<void> _updateStatus(OrderStatus status) async {
    setState(() => _loading = true);

    try {
      final api = context.read<ApiClient>();
      final service = OrdersService(api);

      await service.updateStatus(widget.order.id, status);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a ${status.name}')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _openReviewModal() {
    showDialog(
      context: context,
      builder: (_) => ReviewDialog(order: widget.order),
    );
  }

  void _openChat() {
    final o = widget.order;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: o.clientId, // para worker es el cliente
          otherUserName: o.clientName ?? o.workerName ?? 'Usuario',
        ),
      ),
    );
  }

  void _openClientProfile() {
    final o = widget.order;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientProfileScreen(
          clientId: o.clientId,
          orderId: o.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final o = widget.order;

    final isWorker = user?.role == UserRole.worker;

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${o.id}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.title ?? 'Servicio contratado',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            o.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: isWorker
                            ? (o.clientImageUrl != null && o.clientImageUrl!.isNotEmpty)
                                ? NetworkImage(buildImageUrl(o.clientImageUrl!)) as ImageProvider
                                : null
                            : (o.workerImageUrl != null && o.workerImageUrl!.isNotEmpty)
                                ? NetworkImage(buildImageUrl(o.workerImageUrl!)) as ImageProvider
                                : null,
                        child: (isWorker
                                ? (o.clientImageUrl == null || o.clientImageUrl!.isEmpty)
                                : (o.workerImageUrl == null || o.workerImageUrl!.isEmpty))
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        isWorker ? (o.clientName ?? 'Cliente') : (o.workerName ?? 'Trabajador'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(isWorker ? 'Cliente' : 'Trabajador contratado'),
                      trailing: isWorker
                          ? TextButton(
                              onPressed: _openClientProfile,
                              child: const Text('Ver perfil'),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estado de la orden:', style: Theme.of(context).textTheme.bodyLarge),
                      Chip(
                        label: Text(o.status.toString().split('.').last),
                        backgroundColor: _statusColor(o.status).withOpacity(0.12),
                        labelStyle: TextStyle(color: _statusColor(o.status), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Sección de ubicación (visible para trabajadores)
                  if (isWorker && (o.address != null || o.latitude != null || o.longitude != null))
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  'Ubicación del servicio',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (o.address != null && o.address!.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Dirección:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(o.address!, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            if (o.latitude != null && o.longitude != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Coordenadas:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${o.latitude!.toStringAsFixed(4)}, Lon: ${o.longitude!.toStringAsFixed(4)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  PrimaryButton(
                    onPressed: _openChat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.chat_bubble),
                        SizedBox(width: 8),
                        Text('Abrir chat'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (isWorker) ...[
                    if (o.status == OrderStatus.pending) ...[
                      PrimaryButton(
                        onPressed: () => _updateStatus(OrderStatus.accepted),
                        child: const Text('Aceptar orden'),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        onPressed: () => _updateStatus(OrderStatus.rejected),
                        child: const Text('Rechazar orden'),
                      ),
                    ],
                    if (o.status == OrderStatus.accepted) ...[
                      PrimaryButton(
                        onPressed: () => _updateStatus(OrderStatus.completed),
                        child: const Text('Marcar como completada'),
                      ),
                    ],
                  ],
                  if (o.status == OrderStatus.completed && (o.clientRating == null || o.workerRating == null)) ...[
                    const SizedBox(height: 14),
                    PrimaryButton(
                      onPressed: _openReviewModal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.star),
                          SizedBox(width: 8),
                          Text('Dejar reseña'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// Modal para escribir y enviar reseña
class ReviewDialog extends StatefulWidget {
  final Order order;

  const ReviewDialog({super.key, required this.order});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late int _rating;
  final _reviewController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _rating = 5;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _loading = true);

    try {
      final api = context.read<ApiClient>();
      final reviewsService = ReviewsService(api);
      final auth = context.read<AuthProvider>();
      final user = auth.user;

      if (user == null) throw Exception('Usuario no autenticado');

      // El trabajador reseña al cliente y viceversa
      final toUserId = user.role == UserRole.worker ? widget.order.clientId : widget.order.workerId;

      await reviewsService.createReview(
        orderId: widget.order.id,
        toUserId: toUserId,
        rating: _rating,
        comment: _reviewController.text.isEmpty ? null : _reviewController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña enviada exitosamente')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isWorker = user?.role == UserRole.worker;
    final otherUserName = isWorker ? (widget.order.clientName ?? 'Cliente') : (widget.order.workerName ?? 'Trabajador');

    return AlertDialog(
      title: Text('Reseña para $otherUserName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Califica tu experiencia',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Escribe tu reseña (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submitReview,
          child: _loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enviar reseña'),
        ),
      ],
    );
  }
}
