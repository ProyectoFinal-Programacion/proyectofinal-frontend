import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../state/auth_provider.dart';
import '../../widgets/chat/image_message_widget.dart';
import '../../widgets/common/custom_loading.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  late final StorageService _storageService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _storageService = StorageService();
    
    // Escuchar cambios en el texto para indicador de "escribiendo"
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final auth = context.read<AuthProvider>();
    final me = auth.user;
    if (me == null) return;

    final conversationId = _conversationId(me.id);
    final isTyping = _textController.text.trim().isNotEmpty;
    
    _chatService.setTypingStatus(conversationId, me.id, isTyping);
  }

  String _conversationId(int meId) {
    return _chatService.conversationIdForUsers(meId, widget.otherUserId);
  }

  Future<void> _sendMessage(int meId) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final msg = ChatMessage(
      id: '',
      conversationId: _conversationId(meId),
      fromUserId: meId,
      toUserId: widget.otherUserId,
      text: text,
      imageUrl: null,
      type: MessageType.text,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    try {
      await _chatService.sendMessage(msg);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar mensaje: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendImage(int meId) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final conversationId = _conversationId(meId);

      // Subir imagen a Firebase Storage
      String imageUrl;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        imageUrl = await _storageService.uploadChatImage(
          conversationId: conversationId,
          imageFile: bytes,
          fileName: image.name,
        );
      } else {
        imageUrl = await _storageService.uploadChatImage(
          conversationId: conversationId,
          imageFile: File(image.path),
          fileName: image.name,
        );
      }

      // Enviar mensaje con imagen
      await _chatService.sendImageMessage(
        conversationId: conversationId,
        fromUserId: meId,
        toUserId: widget.otherUserId,
        imageUrl: imageUrl,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar imagen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.user;

    if (me == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para usar el chat'),
        ),
      );
    }

    final conversationId = _conversationId(me.id);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: widget.otherUserAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        widget.otherUserAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          widget.otherUserName.isNotEmpty
                              ? widget.otherUserName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                    )
                  : Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Indicador de "escribiendo..."
                  StreamBuilder<bool>(
                    stream: _chatService.isTypingStream(
                      conversationId,
                      widget.otherUserId,
                    ),
                    builder: (context, snapshot) {
                      final isTyping = snapshot.data ?? false;
                      if (!isTyping) return const SizedBox.shrink();

                      return Row(
                        children: [
                          Text(
                            'escribiendo',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .appBarTheme
                                      .foregroundColor
                                      ?.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const DotLoadingIndicator(
                            size: 4,
                            color: Colors.white70,
                          ),
                        ],
                      ).animate().fadeIn(duration: 200.ms);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mensajes
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.messagesStream(conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CustomLoading());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay mensajes aún',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Envía el primer mensaje!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.fromUserId == me.id;

                    // Agrupar por fecha
                    bool showDateHeader = false;
                    if (index == 0) {
                      showDateHeader = true;
                    } else {
                      final prevMsg = messages[index - 1];
                      showDateHeader = !_isSameDay(m.createdAt, prevMsg.createdAt);
                    }

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(m.createdAt),
                        _buildMessageBubble(m, isMe, me.name)
                            .animate()
                            .fadeIn(duration: 200.ms)
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 200.ms,
                              curve: Curves.easeOut,
                            ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Indicador de subida de imagen
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Subiendo imagen...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ).animate().fadeIn(),

          const Divider(height: 1),

          // Input de mensaje
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Botón de imagen
                  IconButton(
                    icon: Icon(
                      Icons.image,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _isUploading ? null : () => _pickAndSendImage(me.id),
                  ),
                  const SizedBox(width: 8),

                  // Campo de texto
                  Expanded(
                    child: TextFormField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (_) => _sendMessage(me.id),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botón de enviar
                  Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => _sendMessage(me.id),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (_isSameDay(date, today)) {
      dateText = 'Hoy';
    } else if (_isSameDay(date, yesterday)) {
      dateText = 'Ayer';
    } else {
      dateText = DateFormat('d MMM yyyy', 'es').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          dateText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMessageBubble(ChatMessage m, bool isMe, String myName) {
    final bubbleColor = isMe
        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
        : Theme.of(context).cardColor;

    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del otro usuario
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Burbuja de mensaje
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Imagen si existe
                  if (m.imageUrl != null && m.imageUrl!.isNotEmpty) ...[
                    ImageMessageWidget(
                      imageUrl: m.imageUrl!,
                      isMe: isMe,
                    ),
                    if (m.text.isNotEmpty) const SizedBox(height: 8),
                  ],

                  // Texto del mensaje
                  if (m.text.isNotEmpty)
                    Text(
                      m.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                          ),
                    ),

                  const SizedBox(height: 4),

                  // Hora y estado
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(m.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          m.status == MessageStatus.sent
                              ? Icons.check
                              : m.status == MessageStatus.sending
                                  ? Icons.access_time
                                  : Icons.error_outline,
                          size: 14,
                          color: m.status == MessageStatus.failed
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Avatar propio
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                myName.isNotEmpty ? myName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }
}
