class TempBookingData {
  // Active bookings - currently renting
  static List<Map<String, dynamic>> activeBookings = [];

  // Pending bookings - awaiting payment
  static List<Map<String, dynamic>> pendingBookings = [];

  // Upcoming bookings - confirmed, scheduled for future
  static List<Map<String, dynamic>> upcomingBookings = [];

  // Past bookings - completed
  static List<Map<String, dynamic>> pastBookings = [];

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
}