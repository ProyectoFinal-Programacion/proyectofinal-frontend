import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../state/auth_provider.dart';
import '../../utils/image_utils.dart';
import '../common/chat_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para ver tus chats'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ConversationPreview>>(
        stream: ChatService().getConversationsStream(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tienes conversaciones',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia un chat desde el perfil de un usuario',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 88,
            ),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              
              // Determinar el ID del otro usuario
              final otherUserId = conversation.user1Id == user.id
                  ? conversation.user2Id
                  : conversation.user1Id;

              return _ConversationTile(
                conversation: conversation,
                otherUserId: otherUserId,
                currentUserId: user.id,
              ).animate().fadeIn(
                    duration: 300.ms,
                    delay: (index * 50).ms,
                  );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationPreview conversation;
  final int otherUserId;
  final int currentUserId;

  const _ConversationTile({
    required this.conversation,
    required this.otherUserId,
    required this.currentUserId,
  });

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (messageDate == yesterday) {
      return 'Ayer';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE', 'es').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Importar servicios necesarios
    final api = context.read<ApiClient>();
    
    return FutureBuilder<UserProfile>(
      future: UserService(api).getUserById(otherUserId),
      builder: (context, snapshot) {
        // Valores por defecto mientras carga
        String otherUserName = 'Usuario $otherUserId';
        String? otherUserAvatar;
        
        if (snapshot.hasData) {
          otherUserName = snapshot.data!.name;
          otherUserAvatar = snapshot.data!.imageUrl;
        }
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                backgroundImage: otherUserAvatar != null && otherUserAvatar.isNotEmpty
                    ? NetworkImage(buildImageUrl(otherUserAvatar))
                    : null,
                child: otherUserAvatar == null || otherUserAvatar.isEmpty
                    ? Text(
                        otherUserName.isNotEmpty 
                            ? otherUserName[0].toUpperCase() 
                            : 'U',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          title: Text(
            otherUserName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            conversation.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          trailing: Text(
            _formatTime(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  otherUserAvatar: otherUserAvatar,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
