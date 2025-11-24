enum MessageType {
  text,
  image,
  system, // Para mensajes del sistema como "Usuario se unió"
}

enum MessageStatus {
  sending,
  sent,
  failed,
}

class ChatMessage {
  final String id;
  final String conversationId;
  final int fromUserId;
  final int toUserId;
  final String text;
  final String? imageUrl;
  final MessageType type;
  final MessageStatus status;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.fromUserId,
    required this.toUserId,
    required this.text,
    this.imageUrl,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'text': text,
      'imageUrl': imageUrl,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    return ChatMessage(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      fromUserId: (map['fromUserId'] as num?)?.toInt() ?? 0,
      toUserId: (map['toUserId'] as num?)?.toInt() ?? 0,
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      type: _parseMessageType(map['type'] as String?),
      status: _parseMessageStatus(map['status'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ).toLocal(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _parseMessageStatus(String? status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  /// Copia el mensaje con cambios
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    int? fromUserId,
    int? toUserId,
    String? text,
    String? imageUrl,
    MessageType? type,
    MessageStatus? status,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
