import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatService {
  ChatService() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Deterministic conversation id for a pair of users
  String conversationIdForUsers(int a, int b) {
    if (a <= b) {
      return 'u_${a}_u_${b}';
    } else {
      return 'u_${b}_u_${a}';
    }
  }

  /// Stream de mensajes en tiempo real
  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => ChatMessage.fromMap(
                  d.id,
                  d.data(),
                ),
              )
              .toList(),
        );
  }

  /// Envía un mensaje de texto
  Future<void> sendMessage(ChatMessage message) async {
    final ref = _db
        .collection('conversations')
        .doc(message.conversationId)
        .collection('messages')
        .doc();

    await ref.set(message.toMap());
    
    // Actualizar metadata de la conversación
    await _updateConversationMetadata(
      message.conversationId,
      message.fromUserId,
      message.toUserId,
      message.text.isNotEmpty ? message.text : '📷 Imagen',
    );
  }

  /// Envía un mensaje con imagen
  Future<void> sendImageMessage({
    required String conversationId,
    required int fromUserId,
    required int toUserId,
    required String imageUrl,
    String caption = '',
  }) async {
    final message = ChatMessage(
      id: '',
      conversationId: conversationId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      text: caption,
      imageUrl: imageUrl,
      type: MessageType.image,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
    );

    await sendMessage(message);
  }

  /// Actualiza metadata de la conversación (último mensaje, timestamp, etc.)
  Future<void> _updateConversationMetadata(
    String conversationId,
    int fromUserId,
    int toUserId,
    String lastMessage,
  ) async {
    await _db.collection('conversations').doc(conversationId).set({
      'user1Id': fromUserId < toUserId ? fromUserId : toUserId,
      'user2Id': fromUserId < toUserId ? toUserId : fromUserId,
      'lastMessage': lastMessage,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marca mensajes como leídos
  Future<void> markMessagesAsRead(String conversationId, int myUserId) async {
    final snapshot = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('toUserId', isEqualTo: myUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Obtiene el número de mensajes no leídos
  Stream<int> unreadCountStream(String conversationId, int myUserId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('toUserId', isEqualTo: myUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Establece el estado de "escribiendo"
  Future<void> setTypingStatus(
    String conversationId,
    int userId,
    bool isTyping,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .doc(userId.toString())
        .set({
      'isTyping': isTyping,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream para saber si el otro usuario está escribiendo
  Stream<bool> isTypingStream(String conversationId, int otherUserId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('typing')
        .doc(otherUserId.toString())
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      
      final data = doc.data();
      final isTyping = data?['isTyping'] as bool? ?? false;
      final timestamp = data?['timestamp'] as Timestamp?;
      
      // Si han pasado más de 5 segundos, considerar que ya no está escribiendo
      if (timestamp != null) {
        final diff = DateTime.now().difference(timestamp.toDate());
        if (diff.inSeconds > 5) return false;
      }
      
      return isTyping;
    });
  }

  /// Elimina un mensaje
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  /// Obtiene lista de conversaciones del usuario
  Stream<List<ConversationPreview>> getConversationsStream(int userId) {
    // Obtener todas las conversaciones donde el usuario participa
    // Hacemos una sola query para todas las conversaciones y filtramos en memoria
    return _db
        .collection('conversations')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<ConversationPreview> previews = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final user1Id = (data['user1Id'] as num?)?.toInt() ?? 0;
        final user2Id = (data['user2Id'] as num?)?.toInt() ?? 0;
        
        // Solo incluir si el usuario participa en esta conversación
        if (user1Id == userId || user2Id == userId) {
          try {
            previews.add(ConversationPreview.fromMap(doc.id, data));
          } catch (e) {
            // Ignorar conversaciones con datos inválidos
            print('Error parsing conversation ${doc.id}: $e');
          }
        }
      }
      
      return previews;
    });
  }
}

/// Clase auxiliar para preview de conversaciones
class ConversationPreview {
  final String id;
  final int user1Id;
  final int user2Id;
  final String lastMessage;
  final DateTime lastMessageAt;

  ConversationPreview({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory ConversationPreview.fromMap(String id, Map<String, dynamic> map) {
    return ConversationPreview(
      id: id,
      user1Id: (map['user1Id'] as num?)?.toInt() ?? 0,
      user2Id: (map['user2Id'] as num?)?.toInt() ?? 0,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
