
class Review {
  final int id;
  final int fromUserId;
  final int toUserId;
  final int orderId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.orderId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      fromUserId: json['fromUserId'] as int,
      toUserId: json['toUserId'] as int,
      orderId: json['orderId'] as int,
      rating: json['rating'] as int,
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
