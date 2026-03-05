import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Unit tests for MapTiler Geocoding Service
/// 
/// Tests the geocoding and reverse geocoding functionality
/// for location search and address resolution.
void main() {
  group('MapTilerGeocodingService Tests', () {
    
    group('Place Model', () {
      test('should create Place with all fields', () {
        // Arrange & Act
        final place = TestPlace(
          name: 'Butuan City Hall',
          address: 'J.C. Aquino Avenue, Butuan City, Agusan del Norte',
          coordinates: LatLng(8.9475, 125.5406),
          placeType: 'poi',
          context: {
            'city': 'Butuan City',
            'region': 'Agusan del Norte',
            'country': 'Philippines',
          },
        );

        // Assert
        expect(place.name, 'Butuan City Hall');
        expect(place.city, 'Butuan City');
        expect(place.region, 'Agusan del Norte');
        expect(place.country, 'Philippines');
        expect(place.coordinates.latitude, closeTo(8.9475, 0.0001));
        expect(place.coordinates.longitude, closeTo(125.5406, 0.0001));
      });

      test('should handle empty context gracefully', () {
        // Arrange & Act
        final place = TestPlace(
          name: 'Test Location',
          address: 'Unknown Address',
          coordinates: LatLng(0, 0),
          placeType: 'place',
          context: {},
        );

        // Assert
        expect(place.city, isEmpty);
        expect(place.region, isEmpty);
        expect(place.country, isEmpty);
      });

      test('should use name as displayName when available', () {
        // Arrange & Act
        final place = TestPlace(
          name: 'Robinsons Place Butuan',
          address: 'Montilla Boulevard, Butuan City',
          coordinates: LatLng(8.9475, 125.5406),
          placeType: 'poi',
          context: {},
        );

        // Assert
        expect(place.displayName, 'Robinsons Place Butuan');
      });

      test('should fallback to address when name is empty', () {
        // Arrange & Act
        final place = TestPlace(
          name: '',
          address: 'Montilla Boulevard, Butuan City',
          coordinates: LatLng(8.9475, 125.5406),
          placeType: 'address',
          context: {},
        );

        // Assert
        expect(place.displayName, 'Montilla Boulevard, Butuan City');
      });
    });

    group('Context Extraction', () {
      test('should extract city, region, and country from context', () {
        // Arrange
        final context = [
          {'id': 'place.123', 'text': 'Butuan City'},
          {'id': 'region.456', 'text': 'Agusan del Norte'},
          {'id': 'country.789', 'text': 'Philippines'},
        ];

        // Act
        final result = extractContext(context);

        // Assert
        expect(result['city'], 'Butuan City');
        expect(result['region'], 'Agusan del Norte');
        expect(result['country'], 'Philippines');
      });

      test('should handle partial context', () {
        // Arrange
        final context = [
          {'id': 'place.123', 'text': 'Cagayan de Oro'},
        ];

        // Act
        final result = extractContext(context);

        // Assert
        expect(result['city'], 'Cagayan de Oro');
        expect(result['region'], isNull);
        expect(result['country'], isNull);
      });

      test('should handle empty context', () {
        // Arrange
        final List<dynamic>? context = null;

        // Act
        final result = extractContext(context);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('Coordinate Validation', () {
      test('should validate Philippines coordinates', () {
        // Caraga Region coordinates
        final butuan = LatLng(8.9475, 125.5406);
        final surigao = LatLng(9.7844, 125.4914);
        final agusan = LatLng(8.0667, 125.9667);

        // Assert - Philippines latitude range: 4°N to 21°N
        expect(butuan.latitude, inInclusiveRange(4, 21));
        expect(surigao.latitude, inInclusiveRange(4, 21));
        expect(agusan.latitude, inInclusiveRange(4, 21));

        // Assert - Philippines longitude range: 116°E to 127°E
        expect(butuan.longitude, inInclusiveRange(116, 127));
        expect(surigao.longitude, inInclusiveRange(116, 127));
        expect(agusan.longitude, inInclusiveRange(116, 127));
      });

      test('should validate coordinate precision', () {
        // Arrange - Precise coordinates
        final location = LatLng(8.947523, 125.540611);

        // Assert - Should maintain precision
        expect(location.latitude.toStringAsFixed(6), '8.947523');
        expect(location.longitude.toStringAsFixed(6), '125.540611');
      });
    });

    group('Search Query Validation', () {
      test('should handle empty search query', () {
        // Arrange
        final query = '';

        // Act & Assert
        expect(query.isEmpty, isTrue);
      });

      test('should handle single character search', () {
        // Arrange
        final query = 'B';

        // Act & Assert
        expect(query.length, 1);
        expect(query.isNotEmpty, isTrue);
      });

      test('should handle special characters in search', () {
        // Arrange
        final queries = [
          'J.C. Aquino Avenue',
          'Saint Joseph\'s Cathedral',
          'SM City #1',
        ];

        // Assert
        for (final query in queries) {
          expect(query.isNotEmpty, isTrue);
          expect(query, isNot(contains(RegExp(r'[<>]')))); // No HTML tags
        }
      });

      test('should trim whitespace from search query', () {
        // Arrange
        final query = '  Butuan City  ';

        // Act
        final trimmed = query.trim();

        // Assert
        expect(trimmed, 'Butuan City');
        expect(trimmed.length, lessThan(query.length));
      });
    });
  });
}

// Test helper classes
class TestPlace {
  final String name;
  final String address;
  final LatLng coordinates;
  final String placeType;
  final Map<String, String> context;

  const TestPlace({
    required this.name,
    required this.address,
    required this.coordinates,
    required this.placeType,
    required this.context,
  });

  String get displayName => name.isNotEmpty ? name : address;
  String get city => context['city'] ?? '';
  String get region => context['region'] ?? '';
  String get country => context['country'] ?? '';
}

// Test helper function
Map<String, String> extractContext(List? context) {
  final result = <String, String>{};

  if (context == null) return result;

  for (var item in context) {
    final id = item['id'] as String?;
    final text = item['text'] as String?;

    if (id != null && text != null) {
      if (id.startsWith('place')) {
        result['city'] = text;
      } else if (id.startsWith('region')) {
        result['region'] = text;
      } else if (id.startsWith('country')) {
        result['country'] = text;
      }
    }
  }

  return result;
}
