class Favorite {
  final int favoriteId;
  final String vehicleType; // 'car' or 'motorcycle'
  final int vehicleId;
  final String brand;
  final String model;
  final String year;
  final String price;
  final String location;
  final String? bodyStyle;
  final String? transmission;
  final int? seats;
  final double rating;
  final String image;
  final bool hasUnlimitedMileage;
  final String status;
  final DateTime addedAt;

  Favorite({
    required this.favoriteId,
    required this.vehicleType,
    required this.vehicleId,
    required this.brand,
    required this.model,
    required this.year,
    required this.price,
    required this.location,
    this.bodyStyle,
    this.transmission,
    this.seats,
    required this.rating,
    required this.image,
    required this.hasUnlimitedMileage,
    required this.status,
    required this.addedAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      favoriteId: int.tryParse(json['favorite_id'].toString()) ?? 0,
      vehicleType: json['vehicle_type'] ?? 'car',
      vehicleId: int.tryParse(json['vehicle_id'].toString()) ?? 0,
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      year: json['year']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      location: json['location'] ?? '',
      bodyStyle: json['body_style'],
      transmission: json['transmission'],
      seats: json['seats'] != null ? int.tryParse(json['seats'].toString()) : null,
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      image: json['image'] ?? '',
      hasUnlimitedMileage: (json['has_unlimited_mileage'] == 1 || json['has_unlimited_mileage'] == '1'),
      status: json['status'] ?? 'approved',
      addedAt: DateTime.tryParse(json['added_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorite_id': favoriteId,
      'vehicle_type': vehicleType,
      'vehicle_id': vehicleId,
      'brand': brand,
      'model': model,
      'year': year,
      'price': price,
      'location': location,
      'body_style': bodyStyle,
      'transmission': transmission,
      'seats': seats,
      'rating': rating,
      'image': image,
      'has_unlimited_mileage': hasUnlimitedMileage ? 1 : 0,
      'status': status,
      'added_at': addedAt.toIso8601String(),
    };
  }

  String get displayName => '$brand $model';
  
  String get fullDisplayName => '$brand $model $year';
  
  bool get isCar => vehicleType == 'car';
  
  bool get isMotorcycle => vehicleType == 'motorcycle';
}
