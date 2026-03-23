// ignore_for_file: avoid_print, unused_catch_stack
import 'dart:convert';
import 'dart:io';
import 'lib/models/restaurant_models.dart';

void main() {
  final file = File('assets/data/sample_restaurants.jsonl');
  final lines = file.readAsLinesSync();
  int i = 0;
  for (final line in lines) {
    i++;
    if (line.trim().isEmpty) continue;
    try {
      final json = jsonDecode(line);
      Restaurant.fromJson(json);
    } catch (e, st) {
      print('Error on line $i: $e');
      break;
    }
  }
}
