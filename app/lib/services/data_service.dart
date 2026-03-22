import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/restaurant_models.dart';

class DataService {
  Future<List<Restaurant>> loadSampleRestaurants() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/sample_restaurants.jsonl');
      final lines = jsonString.split('\n');
      final restaurants = <Restaurant>[];
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final json = jsonDecode(line) as Map<String, dynamic>;
        restaurants.add(Restaurant.fromJson(json));
      }
      
      return restaurants;
    } catch (e) {
      debugPrint('Error loading sample restaurants: $e');
      return [];
    }
  }
}
