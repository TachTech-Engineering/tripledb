import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_models.dart';

class DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Restaurant>> loadRestaurants() async {
    try {
      // Try Firestore first
      final snapshot = await _db.collection('restaurants').get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Restaurant.fromJson(doc.data()))
            .toList();
      }
      
      // Fallback if collection is empty
      debugPrint('Firestore restaurants collection is empty, falling back to sample data');
      return await loadSampleRestaurants();
    } catch (e) {
      debugPrint('Error loading from Firestore: $e, falling back to sample data');
      return await loadSampleRestaurants();
    }
  }

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

  Future<List<Map<String, dynamic>>> loadVideos() async {
    try {
      final snapshot = await _db.collection('videos').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error loading videos from Firestore: $e');
      return [];
    }
  }
}
