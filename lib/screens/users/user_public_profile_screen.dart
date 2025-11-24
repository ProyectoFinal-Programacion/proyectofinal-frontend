import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../services/reviews_service.dart';
import '../../utils/image_utils.dart';

class UserPublicProfileScreen extends StatefulWidget {
  final int userId;

  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  State<UserPublicProfileScreen> createState() =>
      _UserPublicProfileScreenState();
}

class _UserPublicProfileScreenState extends State<UserPublicProfileScreen> {
  UserProfile? user;
  double average = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiClient>();
    final userService = UserService(api);
    final reviewsService = ReviewsService(api);

    try {
      final profile = await userService.getUserById(widget.userId);
      final avg = await reviewsService.getUserAverage(widget.userId);

      if (!mounted) return;

      setState(() {
        user = profile;
        average = avg;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no encontrado")),
      );
    }

    final u = user!;

    final avatar = u.imageUrl != null && u.imageUrl!.isNotEmpty
    ? buildImageUrl(u.imageUrl!)
    : "";

    return Scaffold(
      appBar: AppBar(title: Text(u.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? Text(u.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 35, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(u.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(u.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(average > 0 ? average.toStringAsFixed(1) : "N/A", style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          if (u.bio != null && u.bio!.isNotEmpty) ...[
            const Text("Biografía", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(u.bio!),
            const SizedBox(height: 20),
          ],

          if (u.phone != null && u.phone!.isNotEmpty) ...[
            const Text("Teléfono", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(u.phone!),
            const SizedBox(height: 20),
          ],

          if (u.address != null && u.address!.isNotEmpty) ...[
            const Text("Dirección", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(u.address!),
          ],
        ],
      ),
    );
  }
}
