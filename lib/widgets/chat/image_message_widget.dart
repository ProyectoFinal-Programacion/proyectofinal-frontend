import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../screens/common/image_preview_screen.dart';

class ImageMessageWidget extends StatelessWidget {
  final String imageUrl;
  final bool isMe;
  final String? messageId; // Para hacer el Hero tag único
  final VoidCallback? onLongPress;

  const ImageMessageWidget({
    super.key,
    required this.imageUrl,
    required this.isMe,
    this.messageId,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImagePreviewScreen(imageUrl: imageUrl),
          ),
        );
      },
      onLongPress: onLongPress,
      child: Hero(
        tag: 'image_${messageId ?? imageUrl}_${DateTime.now().millisecondsSinceEpoch}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 200,
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error al cargar imagen',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
