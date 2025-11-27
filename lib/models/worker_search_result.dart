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
  
  // 👇 Para búsqueda por tipo de trabajo/profesión
  final List<String> gigTitles;
  final List<String> gigCategories;
  final List<double> gigPrices; // 🔥 NUEVO: Para filtrar por precio de gigs

  WorkerSearchResult({
    required this.workerId,
    required this.name,
    this.imageUrl,
    this.basePrice,
    this.distanceKm,
    required this.averageRating,
    this.latitude,
    this.longitude,
    this.gigTitles = const [],
    this.gigCategories = const [],
    this.gigPrices = const [],
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
      gigTitles: const [],
      gigCategories: const [],
      gigPrices: const [],
    );
  }
  
  // Método para crear copia con gig titles, categories y prices
  WorkerSearchResult copyWith({
    List<String>? gigTitles,
    List<String>? gigCategories,
    List<double>? gigPrices,
  }) {
    return WorkerSearchResult(
      workerId: workerId,
      name: name,
      imageUrl: imageUrl,
      basePrice: basePrice,
      distanceKm: distanceKm,
      averageRating: averageRating,
      latitude: latitude,
      longitude: longitude,
      gigTitles: gigTitles ?? this.gigTitles,
      gigCategories: gigCategories ?? this.gigCategories,
      gigPrices: gigPrices ?? this.gigPrices,
    );
  }
}
