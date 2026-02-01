class SavedSearch {
  final String id;
  final String name;
  final Map<String, dynamic> filters;
  final DateTime createdAt;

  SavedSearch({
    required this.id,
    required this.name,
    required this.filters,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filters': filters,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'],
      name: json['name'],
      filters: Map<String, dynamic>.from(json['filters']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String getFilterSummary() {
    List<String> summary = [];
    
    if (filters['location'] != null && filters['location'].toString().isNotEmpty) {
      summary.add('📍 ${filters['location']}');
    }
    if (filters['brand'] != null && filters['brand'].toString().isNotEmpty) {
      summary.add('🚗 ${filters['brand']}');
    }
    if (filters['minPrice'] != null || filters['maxPrice'] != null) {
      double min = (filters['minPrice'] ?? 0).toDouble();
      double max = (filters['maxPrice'] ?? 999999).toDouble();
      if (max < 999999) {
        summary.add('💰 ₱${min.toInt()}-₱${max.toInt()}');
      } else if (min > 0) {
        summary.add('💰 ₱${min.toInt()}+');
      }
    }
    
    return summary.isEmpty ? 'No filters' : summary.join(' • ');
  }
}
