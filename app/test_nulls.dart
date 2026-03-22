import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/data/sample_restaurants.jsonl');
  final lines = file.readAsLinesSync();
  final line = lines[26]; // Line 27
  final json = jsonDecode(line);
  
  print('Restaurant keys with null:');
  json.forEach((k, v) {
    if (v == null) print(k);
  });
  
  if (json['visits'] != null) {
    print('Visits keys with null:');
    for (var visit in json['visits']) {
      visit.forEach((k, v) {
        if (v == null) print('  $k');
      });
    }
  }
  
  if (json['dishes'] != null) {
    print('Dishes keys with null:');
    for (var dish in json['dishes']) {
      dish.forEach((k, v) {
        if (v == null) print('  $k');
      });
    }
  }
}
