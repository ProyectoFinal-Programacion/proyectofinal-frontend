class Gig {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final double price;

  /// Nunca será null y siempre será List<String>
  final List<String> imageUrls;

  final int workerId;
  final String? workerName;

  Gig({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.price,
    required this.imageUrls,
    required this.workerId,
    this.workerName,
  });

  factory Gig.fromJson(Map<String, dynamic> json) {
    return Gig(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      price: (json['price'] as num).toDouble(),
      
      // 🔥 FIX DEFINITIVO: forzar lista segura
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList()
          ?? <String>[],

      workerId: json['workerId'],
      workerName: json['workerName'],
    );
  }
}
