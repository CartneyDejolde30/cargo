/// Analytics data models

class AnalyticsOverview {
  final int totalBookings;
  final int completedBookings;
  final double totalRevenue;
  final int activeVehicles;
  final int activeCars;
  final int activeMotorcycles;
  final double averageRating;
  final double completionRate;

  AnalyticsOverview({
    required this.totalBookings,
    required this.completedBookings,
    required this.totalRevenue,
    required this.activeVehicles,
    required this.activeCars,
    required this.activeMotorcycles,
    required this.averageRating,
    required this.completionRate,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalBookings: json['total_bookings'] ?? 0,
      completedBookings: json['completed_bookings'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      activeVehicles: json['active_vehicles'] ?? 0,
      activeCars: json['active_cars'] ?? 0,
      activeMotorcycles: json['active_motorcycles'] ?? 0,
      averageRating: (json['average_rating'] ?? 5.0).toDouble(),
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
    );
  }
}

class BookingTrend {
  final String month;
  final String monthName;
  final int total;
  final int completed;
  final int cancelled;
  final double revenue;

  BookingTrend({
    required this.month,
    required this.monthName,
    required this.total,
    required this.completed,
    required this.cancelled,
    required this.revenue,
  });

  factory BookingTrend.fromJson(Map<String, dynamic> json) {
    return BookingTrend(
      month: json['month'] ?? '',
      monthName: json['month_name'] ?? '',
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class VehicleTypeRevenue {
  final String type;
  final int bookings;
  final double revenue;

  VehicleTypeRevenue({
    required this.type,
    required this.bookings,
    required this.revenue,
  });

  factory VehicleTypeRevenue.fromJson(Map<String, dynamic> json) {
    return VehicleTypeRevenue(
      type: json['type'] ?? '',
      bookings: json['bookings'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class PaymentStatusBreakdown {
  final String status;
  final int count;
  final double amount;

  PaymentStatusBreakdown({
    required this.status,
    required this.count,
    required this.amount,
  });

  factory PaymentStatusBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentStatusBreakdown(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class RevenueBreakdown {
  final List<VehicleTypeRevenue> byVehicleType;
  final List<PaymentStatusBreakdown> byPaymentStatus;

  RevenueBreakdown({
    required this.byVehicleType,
    required this.byPaymentStatus,
  });

  factory RevenueBreakdown.fromJson(Map<String, dynamic> json) {
    return RevenueBreakdown(
      byVehicleType: (json['by_vehicle_type'] as List? ?? [])
          .map((item) => VehicleTypeRevenue.fromJson(item))
          .toList(),
      byPaymentStatus: (json['by_payment_status'] as List? ?? [])
          .map((item) => PaymentStatusBreakdown.fromJson(item))
          .toList(),
    );
  }
}

class VehicleStats {
  final int id;
  final String name;
  final String plate;
  final String? image;
  final int bookings;
  final double rating;
  final double revenue;

  VehicleStats({
    required this.id,
    required this.name,
    required this.plate,
    this.image,
    required this.bookings,
    required this.rating,
    required this.revenue,
  });

  factory VehicleStats.fromJson(Map<String, dynamic> json) {
    return VehicleStats(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      plate: json['plate'] ?? '',
      image: json['image'],
      bookings: json['bookings'] ?? 0,
      rating: (json['rating'] ?? 5.0).toDouble(),
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class PopularVehicles {
  final List<VehicleStats> cars;
  final List<VehicleStats> motorcycles;

  PopularVehicles({
    required this.cars,
    required this.motorcycles,
  });

  factory PopularVehicles.fromJson(Map<String, dynamic> json) {
    return PopularVehicles(
      cars: (json['cars'] as List? ?? [])
          .map((item) => VehicleStats.fromJson(item))
          .toList(),
      motorcycles: (json['motorcycles'] as List? ?? [])
          .map((item) => VehicleStats.fromJson(item))
          .toList(),
    );
  }
}

class DailyBooking {
  final String day;
  final int count;

  DailyBooking({
    required this.day,
    required this.count,
  });

  factory DailyBooking.fromJson(Map<String, dynamic> json) {
    return DailyBooking(
      day: json['day'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class PeakBookingData {
  final List<int> hourly;
  final List<DailyBooking> daily;

  PeakBookingData({
    required this.hourly,
    required this.daily,
  });

  factory PeakBookingData.fromJson(Map<String, dynamic> json) {
    return PeakBookingData(
      hourly: (json['hourly'] as List? ?? List.filled(24, 0))
          .map((e) => e as int)
          .toList(),
      daily: (json['daily'] as List? ?? [])
          .map((item) => DailyBooking.fromJson(item))
          .toList(),
    );
  }
}
