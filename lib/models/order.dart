import 'enums.dart';

class Order {
  final int id;
  final int gigId;
  final int clientId;
  final int workerId;

  final String description;
  final OrderStatus status;

  // Datos extra usados en la UI
  final String? clientName;
  final String? workerName;
  final String? title;
  final String? gigCategory;

  // Campos adicionales importantes
  final String? address;
  final double totalPrice;

  final double? latitude;
  final double? longitude;

  // Fotos de perfil
  final String? clientImageUrl;
  final String? workerImageUrl;

  // Campos de reseña
  final double? clientRating;
  final double? workerRating;
  final String? clientReviewText;
  final String? workerReviewText;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.gigId,
    required this.clientId,
    required this.workerId,
    required this.description,
    required this.status,
    this.clientName,
    this.workerName,
    this.title,
    this.gigCategory,
    this.address,
    required this.totalPrice,
    this.latitude,
    this.longitude,
    this.clientImageUrl,
    this.workerImageUrl,
    this.clientRating,
    this.workerRating,
    this.clientReviewText,
    this.workerReviewText,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    int rawStatus = json['status'] ?? 0;

    // ← MAPPING SEGURO DEL ENUM
    OrderStatus safeStatus = OrderStatus.values.length > rawStatus
        ? OrderStatus.values[rawStatus]
        : OrderStatus.pending;

    return Order(
      id: json['id'] as int,
      gigId: json['gigId'] as int,
      clientId: json['clientId'] as int,
      workerId: json['workerId'] as int,

      description: json['description'] ?? '',
      status: safeStatus,

      clientName: json['clientName'],
      workerName: json['workerName'],
      title: json['gigTitle'] ?? json['title'],
      gigCategory: json['gigCategory'],

      address: json['address'],
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,

      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),

      clientImageUrl: json['clientImageUrl'],
      workerImageUrl: json['workerImageUrl'],

      clientRating: (json['clientRating'] as num?)?.toDouble(),
      workerRating: (json['workerRating'] as num?)?.toDouble(),
      clientReviewText: json['clientReviewText'],
      workerReviewText: json['workerReviewText'],
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}
