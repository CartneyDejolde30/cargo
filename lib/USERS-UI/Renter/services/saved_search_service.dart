import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_search.dart';

class SavedSearchService {
  static const String _savedSearchesKey = 'saved_searches';

  // Get all saved searches
  Future<List<SavedSearch>> getSavedSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedSearchesJson = prefs.getString(_savedSearchesKey);
      
      if (savedSearchesJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(savedSearchesJson);
      return decoded.map((json) => SavedSearch.fromJson(json)).toList();
    } catch (e) {
      print('Error loading saved searches: $e');
      return [];
    }
  }

  // Save a new search
  Future<bool> saveSearch(String name, Map<String, dynamic> filters) async {
    try {
      final searches = await getSavedSearches();
      
      // Check if name already exists
      if (searches.any((s) => s.name.toLowerCase() == name.toLowerCase())) {
        return false;
      }

      final newSearch = SavedSearch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        filters: filters,
        createdAt: DateTime.now(),
      );

      searches.add(newSearch);
      
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(searches.map((s) => s.toJson()).toList());
      await prefs.setString(_savedSearchesKey, encoded);
      
      return true;
    } catch (e) {
      print('Error saving search: $e');
      return false;
    }
  }

  // Delete a saved search
  Future<bool> deleteSearch(String id) async {
    try {
      final searches = await getSavedSearches();
      searches.removeWhere((s) => s.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(searches.map((s) => s.toJson()).toList());
      await prefs.setString(_savedSearchesKey, encoded);
      
      return true;
    } catch (e) {
      print('Error deleting search: $e');
      return false;
    }
  }

  // Update a saved search
  Future<bool> updateSearch(String id, String newName, Map<String, dynamic> newFilters) async {
    try {
      final searches = await getSavedSearches();
      final index = searches.indexWhere((s) => s.id == id);
      
      if (index == -1) {
        return false;
      }

      searches[index] = SavedSearch(
        id: id,
        name: newName,
        filters: newFilters,
        createdAt: searches[index].createdAt,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(searches.map((s) => s.toJson()).toList());
      await prefs.setString(_savedSearchesKey, encoded);
      
      return true;
    } catch (e) {
      print('Error updating search: $e');
      return false;
    }
  }

  // Clear all saved searches
  Future<bool> clearAllSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedSearchesKey);
      return true;
    } catch (e) {
      print('Error clearing searches: $e');
      return false;
    }
  }
}
