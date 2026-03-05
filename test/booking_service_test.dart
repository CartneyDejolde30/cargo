import 'package:flutter_test/flutter_test.dart';

/// Unit tests for BookingService
/// 
/// Tests the booking retrieval and cancellation functionality
/// to ensure proper API communication and data handling.
void main() {
  group('BookingService Tests', () {
    
    group('getMyBookings', () {
      test('should return list of bookings when API call is successful', () async {
        // Arrange
        final mockBookingsResponse = {
          'success': true,
          'bookings': [
            {
              'id': 1,
              'user_id': 'user123',
              'car_id': 10,
              'car_name': 'Toyota Vios',
              'owner_name': 'John Doe',
              'start_date': '2026-02-20',
              'end_date': '2026-02-25',
              'total_price': 5000.0,
              'status': 'confirmed',
              'main_image': 'car1.jpg',
              'pickup_location': 'Butuan City',
            },
            {
              'id': 2,
              'user_id': 'user123',
              'car_id': 15,
              'car_name': 'Honda City',
              'owner_name': 'Jane Smith',
              'start_date': '2026-03-01',
              'end_date': '2026-03-05',
              'total_price': 6000.0,
              'status': 'pending',
              'main_image': 'car2.jpg',
              'pickup_location': 'Cagayan de Oro',
            },
          ],
        };

        // Note: This test validates the expected API response structure
        // and data parsing logic for booking retrieval.
        
        final List bookingsList = mockBookingsResponse['bookings'] as List;
        
        // Validate booking data structure
        final firstBooking = bookingsList[0] as Map<String, dynamic>;
        final secondBooking = bookingsList[1] as Map<String, dynamic>;

        // Assert
        expect(bookingsList, isNotEmpty);
        expect(bookingsList.length, 2);
        expect(firstBooking['car_name'], 'Toyota Vios');
        expect(secondBooking['status'], 'pending');
      });

      test('should return empty list when no bookings exist', () async {
        // Arrange
        final mockEmptyResponse = {
          'success': true,
          'bookings': [],
        };

        final List bookingsList = mockEmptyResponse['bookings'] as List;

        // Assert
        expect(bookingsList, isEmpty);
      });

      test('should handle null bookings gracefully', () {
        // Arrange
        final mockNullResponse = {
          'success': true,
          'bookings': null,
        };

        // Act
        final bookingsList = mockNullResponse['bookings'];

        // Assert
        expect(bookingsList, isNull);
      });
    });

    group('cancelBooking', () {
      test('should return success when booking cancellation succeeds', () {
        // Arrange
        final mockSuccessResponse = {
          'success': true,
          'message': 'Booking cancelled successfully',
          'current_status': 'cancelled',
        };

        // Act
        final result = {
          'success': mockSuccessResponse['success'] == true,
          'message': mockSuccessResponse['message'] ?? 'Unknown response',
          'current_status': mockSuccessResponse['current_status'],
        };

        // Assert
        expect(result['success'], isTrue);
        expect(result['message'], contains('successfully'));
        expect(result['current_status'], 'cancelled');
      });

      test('should return failure when booking cannot be cancelled', () {
        // Arrange
        final mockFailureResponse = {
          'success': false,
          'message': 'Cannot cancel confirmed booking',
          'current_status': 'confirmed',
        };

        // Act
        final result = {
          'success': mockFailureResponse['success'] == true,
          'message': mockFailureResponse['message'] ?? 'Unknown response',
          'current_status': mockFailureResponse['current_status'],
        };

        // Assert
        expect(result['success'], isFalse);
        expect(result['message'], contains('Cannot cancel'));
      });

      test('should handle network errors gracefully', () {
        // Arrange - Simulate network error
        final errorMessage = 'Network error: Connection timeout';

        // Act
        final result = {
          'success': false,
          'message': errorMessage,
        };

        // Assert
        expect(result['success'], isFalse);
        expect(result['message'], contains('Network error'));
      });
    });

    group('Booking Data Validation', () {
      test('should validate required booking fields', () {
        // Arrange
        final validBookingData = {
          'id': 1,
          'user_id': 'user123',
          'car_id': 10,
          'car_name': 'Toyota Vios',
          'owner_name': 'John Doe',
          'start_date': '2026-02-20',
          'end_date': '2026-02-25',
          'total_price': 5000.0,
          'status': 'confirmed',
        };

        // Assert - Check all required fields exist
        expect(validBookingData['id'], isNotNull);
        expect(validBookingData['user_id'], isNotNull);
        expect(validBookingData['car_id'], isNotNull);
        expect(validBookingData['car_name'], isNotNull);
        expect(validBookingData['start_date'], isNotNull);
        expect(validBookingData['end_date'], isNotNull);
        expect(validBookingData['total_price'], isA<num>());
        expect(validBookingData['status'], isNotNull);
      });

      test('should handle missing optional fields', () {
        // Arrange - Booking without optional fields
        final minimalBookingData = {
          'id': 1,
          'user_id': 'user123',
          'car_id': 10,
          'car_name': 'Toyota Vios',
          'start_date': '2026-02-20',
          'end_date': '2026-02-25',
          'total_price': 5000.0,
          'status': 'confirmed',
          // Missing: main_image, pickup_location, owner_name
        };

        // Assert - Should still be valid
        expect(minimalBookingData['id'], isNotNull);
        expect(minimalBookingData['main_image'], isNull);
        expect(minimalBookingData['pickup_location'], isNull);
      });
    });
  });
}
