class Service {
  final int id;
  final String name;
  final String description;
  final String category;
  Service({required this.id, required this.name, required this.description, required this.category});
  factory Service.fromJson(Map<String, dynamic> j) => Service(id: j['id'], name: j['name'], description: j['description'], category: j['category']);
}

class WorkerProfile {
  final int id;
  final int userId;
  final String trade;
  final String zone;
  final String bio;
  final String availability;
  final double averageRating;
  final String? photoUrl;
  final String? galleryUrls;
  final String? phoneNumber;
  WorkerProfile({
    required this.id, required this.userId, required this.trade, required this.zone, required this.bio,
    required this.availability, required this.averageRating, this.photoUrl, this.galleryUrls, this.phoneNumber
  });
  factory WorkerProfile.fromJson(Map<String, dynamic> j) => WorkerProfile(
    id: j['id'], userId: j['userId'], trade: j['trade'], zone: j['zone'], bio: j['bio'],
    availability: j['availability'], averageRating: (j['averageRating'] ?? 0).toDouble(),
    photoUrl: j['photoUrl'], galleryUrls: j['galleryUrls'], phoneNumber: j['phoneNumber']
  );
}

class ServiceRequest {
  final int id;
  final int clientId;
  final int workerId;
  final int serviceId;
  final DateTime dateRequested;
  final String status;
  ServiceRequest({required this.id, required this.clientId, required this.workerId, required this.serviceId, required this.dateRequested, required this.status});
  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
    id: j['id'], clientId: j['clientId'], workerId: j['workerId'], serviceId: j['serviceId'],
    dateRequested: DateTime.parse(j['dateRequested']), status: j['status'].toString().split('.').last
  );
}

class Review {
  final int id;
  final int workerId;
  final int clientId;
  final int rating;
  final String comment;
  final DateTime date;
  Review({required this.id, required this.workerId, required this.clientId, required this.rating, required this.comment, required this.date});
  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'], workerId: j['workerId'], clientId: j['clientId'],
    rating: j['rating'], comment: j['comment'], date: DateTime.parse(j['date'])
  );
}
