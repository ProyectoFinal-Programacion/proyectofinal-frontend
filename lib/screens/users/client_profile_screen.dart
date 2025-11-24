import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../models/review.dart';

import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../services/reviews_service.dart';
import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/primary_button.dart';

class ClientProfileScreen extends StatefulWidget {
  final int clientId;
  final int orderId; // ← orden desde donde se abrió

  const ClientProfileScreen({
    super.key,
    required this.clientId,
    required this.orderId,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _loading = true;
  UserProfile? _user;
  List<Review> _reviews = [];
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _loading = true);

      final api = context.read<ApiClient>();
      final userService = UserService(api);
      final reviewsService = ReviewsService(api);

      final user = await userService.getUserById(widget.clientId);
      final reviews = await reviewsService.getUserReviews(widget.clientId);

      // calculamos promedio localmente
      double avg = 0;
      if (reviews.isNotEmpty) {
        final sum = reviews.fold<double>(
            0, (previous, r) => previous + r.rating);
        avg = sum / reviews.length;
      }

      if (!mounted) return;

      setState(() {
        _user = user;
        _reviews = reviews;
        _averageRating = avg;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _loading = false);
    }
  }

  // ------------------------------------------------------------
  // ENVIAR RESEÑA
  // ------------------------------------------------------------
  Future<void> _openReviewDialog() async {
    int rating = 5;
    final commentCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Calificar al cliente'),
          content: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final filled = index < rating;
                      return IconButton(
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comentario (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _submitReview(rating: rating, comment: commentCtrl.text.trim());
  }

  Future<void> _submitReview({
    required int rating,
    required String comment,
  }) async {
    try {
      final api = context.read<ApiClient>();
      final reviewService = ReviewsService(api);

      await reviewService.createReview(
        orderId: widget.orderId,
        toUserId: widget.clientId,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reseña enviada correctamente')),
      );

      await _load(); // refrescamos datos y promedio
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al enviar reseña: $e')));
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    final user = _user!;
    final me = context.watch<AuthProvider>().user;
    final canRate = me != null && me.id != user.id;

    final avatar = (user.imageUrl != null && user.imageUrl!.isNotEmpty)
        ? buildImageUrl(user.imageUrl!)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text(
                                _averageRating > 0 ? _averageRating.toStringAsFixed(1) : 'Sin calificaciones',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Datos
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoTile('Email', user.email),
                    if (user.phone != null && user.phone!.isNotEmpty) _buildInfoTile('Teléfono', user.phone!),
                    if (user.address != null && user.address!.isNotEmpty) _buildInfoTile('Dirección', user.address!),
                    if (user.bio != null && user.bio!.isNotEmpty) _buildInfoTile('Bio', user.bio!),
                    if (user.basePrice != null) _buildInfoTile('Precio base', 'Bs ${user.basePrice!.toStringAsFixed(2)}'),
                    if (user.latitude != null && user.longitude != null)
                      _buildInfoTile('Ubicación', 'Lat: ${user.latitude!.toStringAsFixed(4)}, Lon: ${user.longitude!.toStringAsFixed(4)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (canRate)
              PrimaryButton(
                onPressed: _openReviewDialog,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.rate_review), SizedBox(width: 8), Text('Calificar al cliente')],
                ),
              ),

            const SizedBox(height: 20),

            const Text('Reseñas recibidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _reviews.isEmpty
                ? const Text('Este usuario no tiene reseñas aún.')
                : Column(
                    children: _reviews.map((r) {
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(r.rating.toStringAsFixed(1)),
                          subtitle: Text(r.comment ?? ''),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
