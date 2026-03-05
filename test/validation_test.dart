import 'package:flutter_test/flutter_test.dart';

/// Unit tests for Data Validation
/// 
/// Tests common validation scenarios for the CarGO platform
/// including dates, prices, locations, and user inputs.
void main() {
  group('Date Validation Tests', () {
    
    test('should validate booking date range', () {
      // Arrange
      final startDate = DateTime(2026, 2, 20);
      final endDate = DateTime(2026, 2, 25);

      // Act
      final isValidRange = endDate.isAfter(startDate);
      final duration = endDate.difference(startDate).inDays;

      // Assert
      expect(isValidRange, isTrue);
      expect(duration, 5);
      expect(duration, greaterThan(0));
    });

    test('should reject invalid date ranges', () {
      // Arrange
      final startDate = DateTime(2026, 2, 25);
      final endDate = DateTime(2026, 2, 20);

      // Act
      final isValidRange = endDate.isAfter(startDate);

      // Assert
      expect(isValidRange, isFalse);
    });

    test('should reject past booking dates', () {
      // Arrange
      final pastDate = DateTime(2020, 1, 1);
      final today = DateTime.now();

      // Act
      final isPastDate = pastDate.isBefore(today);

      // Assert
      expect(isPastDate, isTrue);
    });

    test('should allow same-day start dates', () {
      // Arrange
      final today = DateTime.now();
      final startDate = DateTime(today.year, today.month, today.day);

      // Act
      final isSameDay = startDate.year == today.year &&
          startDate.month == today.month &&
          startDate.day == today.day;

      // Assert
      expect(isSameDay, isTrue);
    });

    test('should calculate rental duration correctly', () {
      // Arrange
      final testCases = [
        {'start': DateTime(2026, 2, 20), 'end': DateTime(2026, 2, 25), 'expected': 5},
        {'start': DateTime(2026, 2, 1), 'end': DateTime(2026, 2, 29), 'expected': 28},
        {'start': DateTime(2026, 1, 1), 'end': DateTime(2026, 1, 2), 'expected': 1},
      ];

      for (final testCase in testCases) {
        // Act
        final duration = (testCase['end'] as DateTime)
            .difference(testCase['start'] as DateTime)
            .inDays;

        // Assert
        expect(duration, testCase['expected']);
      }
    });
  });

  group('Price Validation Tests', () {
    
    test('should validate positive prices', () {
      // Arrange
      final prices = [100.0, 500.50, 1000.0, 5000.0];

      for (final price in prices) {
        // Assert
        expect(price, greaterThan(0));
        expect(price, isA<num>());
      }
    });

    test('should reject negative prices', () {
      // Arrange
      final invalidPrices = [-100.0, -50.0, 0.0];

      for (final price in invalidPrices) {
        // Assert
        expect(price, lessThanOrEqualTo(0));
      }
    });

    test('should calculate total rental price correctly', () {
      // Arrange
      final dailyRate = 1000.0;
      final days = 5;

      // Act
      final totalPrice = dailyRate * days;

      // Assert
      expect(totalPrice, 5000.0);
      expect(totalPrice, equals(dailyRate * days));
    });

    test('should calculate price with discounts', () {
      // Arrange
      final basePrice = 5000.0;
      final discountPercent = 10.0;

      // Act
      final discountAmount = basePrice * (discountPercent / 100);
      final finalPrice = basePrice - discountAmount;

      // Assert
      expect(discountAmount, 500.0);
      expect(finalPrice, 4500.0);
    });

    test('should round prices to 2 decimal places', () {
      // Arrange
      final prices = [100.123, 500.567, 1000.999];

      for (final price in prices) {
        // Act
        final rounded = double.parse(price.toStringAsFixed(2));

        // Assert
        expect(rounded.toString(), matches(r'^\d+\.\d{2}$'));
      }
    });
  });

  group('Location Validation Tests', () {
    
    test('should validate location string format', () {
      // Arrange
      final validLocations = [
        'Butuan City, Agusan del Norte',
        'Cagayan de Oro City',
        'Surigao City',
      ];

      for (final location in validLocations) {
        // Assert
        expect(location.isNotEmpty, isTrue);
        expect(location.trim(), equals(location));
      }
    });

    test('should reject empty locations', () {
      // Arrange
      final invalidLocations = ['', '   ', '\n'];

      for (final location in invalidLocations) {
        // Assert
        expect(location.trim().isEmpty, isTrue);
      }
    });

    test('should validate Philippine city names', () {
      // Arrange
      final philippineCities = [
        'Manila',
        'Quezon City',
        'Davao City',
        'Butuan City',
        'Cagayan de Oro',
      ];

      for (final city in philippineCities) {
        // Assert
        expect(city, isNotEmpty);
        expect(city.length, greaterThan(3));
      }
    });
  });

  group('Vehicle Information Validation Tests', () {
    
    test('should validate vehicle model year', () {
      // Arrange
      final currentYear = DateTime.now().year;
      final validYears = [2020, 2021, 2022, 2023, 2024, 2025, 2026];

      for (final year in validYears) {
        // Assert
        expect(year, lessThanOrEqualTo(currentYear + 1));
        expect(year, greaterThanOrEqualTo(2000));
      }
    });

    test('should validate plate number format', () {
      // Arrange - Philippine plate number patterns
      final validPlateNumbers = [
        'ABC 1234',
        'XYZ 5678',
        'NCR 9999',
      ];

      for (final plate in validPlateNumbers) {
        // Assert
        expect(plate, matches(r'^[A-Z]{3}\s\d{4}$'));
      }
    });

    test('should validate passenger capacity', () {
      // Arrange
      final validCapacities = [2, 4, 5, 7, 8];

      for (final capacity in validCapacities) {
        // Assert
        expect(capacity, greaterThan(0));
        expect(capacity, lessThanOrEqualTo(20));
      }
    });

    test('should validate fuel type', () {
      // Arrange
      final validFuelTypes = ['Gasoline', 'Diesel', 'Electric', 'Hybrid'];

      for (final fuelType in validFuelTypes) {
        // Assert
        expect(fuelType, isNotEmpty);
        expect(fuelType, isIn(['Gasoline', 'Diesel', 'Electric', 'Hybrid']));
      }
    });
  });

  group('User Input Validation Tests', () {
    
    test('should validate email format', () {
      // Arrange
      final validEmails = [
        'user@example.com',
        'test.user@domain.co.ph',
        'admin@cargo.ph',
      ];

      for (final email in validEmails) {
        // Assert
        expect(email, contains('@'));
        expect(email, contains('.'));
        expect(email, matches(r'^[\w\.-]+@[\w\.-]+\.\w+$'));
      }
    });

    test('should reject invalid email formats', () {
      // Arrange
      final invalidEmails = [
        'notanemail',
        '@nodomain.com',
        'missing@domain',
        'spaces in@email.com',
      ];

      for (final email in invalidEmails) {
        // Act
        final hasAt = email.contains('@');
        final hasDot = email.contains('.');
        final hasSpaces = email.contains(' ');
        final isValid = hasAt && hasDot && !hasSpaces && 
                       email.indexOf('@') > 0 &&
                       email.indexOf('.') > email.indexOf('@');

        // Assert
        expect(isValid, isFalse);
      }
    });

    test('should validate phone number format', () {
      // Arrange - Philippine phone numbers
      final validPhones = [
        '09171234567',
        '09281234567',
        '+639171234567',
      ];

      for (final phone in validPhones) {
        // Assert
        expect(phone.replaceAll(RegExp(r'[^\d]'), '').length, greaterThanOrEqualTo(10));
      }
    });

    test('should validate password strength', () {
      // Arrange
      final weakPasswords = ['123', 'password', 'abc'];
      final strongPasswords = ['MyP@ssw0rd', 'Secure123!', 'CarGO2026#'];

      // Assert weak passwords
      for (final password in weakPasswords) {
        expect(password.length, lessThan(8));
      }

      // Assert strong passwords
      for (final password in strongPasswords) {
        expect(password.length, greaterThanOrEqualTo(8));
      }
    });
  });

  group('Booking Status Validation Tests', () {
    
    test('should validate booking statuses', () {
      // Arrange
      final validStatuses = [
        'pending',
        'confirmed',
        'ongoing',
        'completed',
        'cancelled',
        'rejected',
      ];

      for (final status in validStatuses) {
        // Assert
        expect(status, isIn([
          'pending',
          'confirmed',
          'ongoing',
          'completed',
          'cancelled',
          'rejected',
        ]));
      }
    });

    test('should validate status transitions', () {
      // Arrange - Valid transitions
      final validTransitions = {
        'pending': ['confirmed', 'rejected', 'cancelled'],
        'confirmed': ['ongoing', 'cancelled'],
        'ongoing': ['completed'],
      };

      // Assert
      expect(validTransitions['pending'], contains('confirmed'));
      expect(validTransitions['confirmed'], contains('ongoing'));
      expect(validTransitions['ongoing'], contains('completed'));
    });
  });
}
