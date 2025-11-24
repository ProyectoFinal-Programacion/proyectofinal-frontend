import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../models/review.dart';

import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../services/reviews_service.dart';
import '../../utils/image_utils.dart';

class ClientProfileScreen extends StatefulWidget {
  final int clientId;

  const ClientProfileScreen({super.key, required this.clientId});

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
      final avg = await reviewsService.getUserAverage(widget.clientId);


      setState(() {
        _user = user;
        _reviews = reviews;
        _averageRating = avg;
        _loading = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user!;
    final avatar = user.imageUrl != null && user.imageUrl!.isNotEmpty
        ? buildImageUrl(user.imageUrl!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil del cliente")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(user.email, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoTile("Email", user.email),
            if (user.phone != null) _buildInfoTile("Teléfono", user.phone!),
            if (user.address != null) _buildInfoTile("Dirección", user.address!),
            if (user.bio != null) _buildInfoTile("Bio", user.bio!),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  _averageRating > 0
                      ? _averageRating.toStringAsFixed(1)
                      : "Sin calificaciones",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),

            const SizedBox(height: 18),
            Text("Reseñas recibidas", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),

            _reviews.isEmpty
                ? const Text("Este usuario no tiene reseñas aún.")
                : Column(
                    children: _reviews.map((r) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(r.rating.toStringAsFixed(1)),
                          subtitle: Text(r.comment ?? ""),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            "$label: ",
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}
