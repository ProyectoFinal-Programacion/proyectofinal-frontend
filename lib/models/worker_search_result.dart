class WorkerSearchResult {
  final int workerId;
  final String name;
  final String? imageUrl;
  final double? basePrice;
  final double? distanceKm;
  final double averageRating;

  // 👇 NUEVO
  final double? latitude;
  final double? longitude;

  WorkerSearchResult({
    required this.workerId,
    required this.name,
    this.imageUrl,
    this.basePrice,
    this.distanceKm,
    required this.averageRating,
    this.latitude,
    this.longitude,
  });

  factory WorkerSearchResult.fromJson(Map<String, dynamic> json) {
    return WorkerSearchResult(
      workerId: json['workerId'],
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
