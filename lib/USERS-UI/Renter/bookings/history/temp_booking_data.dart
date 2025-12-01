class TempBookingData {
  // Active bookings - currently renting
  static List<Map<String, dynamic>> activeBookings = [
    {
      'bookingId': 'BK001234',
      'carName': 'Tesla Model 3',
      'carImage': 'assets/cars/tesla_model3.png',
      'location': 'Midsayap, North Cotabato',
      'pickupDate': '25 Nov 2024',
      'pickupTime': '09:00 AM',
      'returnDate': '02 Dec 2024',
      'returnTime': '05:00 PM',
      'totalPrice': '8,750.00',
      'numberOfDays': 7,
      'withDriver': true,
      'status': 'active',
    },
  ];

  // Pending bookings - awaiting payment
  static List<Map<String, dynamic>> pendingBookings = [
    {
      'bookingId': 'BK001567',
      'carName': 'Honda Civic 2024',
      'carImage': 'assets/cars/honda_civic.png',
      'location': 'Kidapawan City',
      'pickupDate': '05 Dec 2024',
      'pickupTime': '10:00 AM',
      'returnDate': '08 Dec 2024',
      'returnTime': '06:00 PM',
      'totalPrice': '4,500.00',
      'numberOfDays': 3,
      'withDriver': false,
      'status': 'pending',
    },
  ];

  // Upcoming bookings - confirmed, scheduled for future
  static List<Map<String, dynamic>> upcomingBookings = [
    {
      'bookingId': 'BK001789',
      'carName': 'Toyota Fortuner',
      'carImage': 'assets/cars/toyota_fortuner.png',
      'location': 'Cotabato City',
      'pickupDate': '15 Dec 2024',
      'pickupTime': '08:00 AM',
      'returnDate': '20 Dec 2024',
      'returnTime': '07:00 PM',
      'totalPrice': '12,500.00',
      'numberOfDays': 5,
      'withDriver': true,
      'status': 'upcoming',
    },
    {
      'bookingId': 'BK001890',
      'carName': 'Mitsubishi Montero',
      'carImage': 'assets/cars/mitsubishi_montero.png',
      'location': 'Koronadal City',
      'pickupDate': '28 Dec 2024',
      'pickupTime': '09:00 AM',
      'returnDate': '31 Dec 2024',
      'returnTime': '08:00 PM',
      'totalPrice': '9,000.00',
      'numberOfDays': 3,
      'withDriver': true,
      'status': 'upcoming',
    },
  ];

  // Past bookings - completed
  static List<Map<String, dynamic>> pastBookings = [
    {
      'bookingId': 'BK000912',
      'carName': 'Nissan Navara',
      'carImage': 'assets/cars/nissan_navara.png',
      'location': 'Midsayap, North Cotabato',
      'pickupDate': '10 Nov 2024',
      'pickupTime': '07:00 AM',
      'returnDate': '15 Nov 2024',
      'returnTime': '06:00 PM',
      'totalPrice': '7,500.00',
      'numberOfDays': 5,
      'withDriver': false,
      'status': 'completed',
    },
    {
      'bookingId': 'BK000845',
      'carName': 'Hyundai Tucson',
      'carImage': 'assets/cars/hyundai_tucson.png',
      'location': 'General Santos City',
      'pickupDate': '28 Oct 2024',
      'pickupTime': '09:30 AM',
      'returnDate': '30 Oct 2024',
      'returnTime': '05:00 PM',
      'totalPrice': '4,200.00',
      'numberOfDays': 2,
      'withDriver': false,
      'status': 'completed',
    },
    {
      'bookingId': 'BK000756',
      'carName': 'Ford Ranger Raptor',
      'carImage': 'assets/cars/ford_ranger.png',
      'location': 'Tacurong City',
      'pickupDate': '15 Oct 2024',
      'pickupTime': '08:00 AM',
      'returnDate': '22 Oct 2024',
      'returnTime': '07:00 PM',
      'totalPrice': '14,000.00',
      'numberOfDays': 7,
      'withDriver': true,
      'status': 'completed',
    },
  ];

  // Helper method to get all bookings
  static List<Map<String, dynamic>> getAllBookings() {
    return [
      ...activeBookings,
      ...pendingBookings,
      ...upcomingBookings,
      ...pastBookings,
    ];
  }

  // Helper method to get booking by ID
  static Map<String, dynamic>? getBookingById(String bookingId) {
    try {
      return getAllBookings().firstWhere(
        (booking) => booking['bookingId'] == bookingId,
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to clear all bookings (for testing empty state)
  static void clearAllBookings() {
    activeBookings.clear();
    pendingBookings.clear();
    upcomingBookings.clear();
    pastBookings.clear();
  }

  // Helper method to reset to default data
  static void resetToDefault() {
    // This would reset all lists to their original state
    // You can call the initialization again if needed
  }
}