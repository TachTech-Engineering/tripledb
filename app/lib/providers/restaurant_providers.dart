import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/restaurant_models.dart';
import '../services/data_service.dart';
import 'location_providers.dart';

part 'restaurant_providers.g.dart';

@riverpod
class RestaurantList extends _$RestaurantList {
  @override
  Future<List<Restaurant>> build() async {
    return DataService().loadRestaurants();
  }
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }
}

@riverpod
class ShowClosed extends _$ShowClosed {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }
}

@riverpod
Future<List<Restaurant>> filteredRestaurants(Ref ref) async {
  final restaurants = await ref.watch(restaurantListProvider.future);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return restaurants;
  }

  var results = restaurants.where((r) {
    final nameMatch = r.name.toLowerCase().contains(query);
    final currentNameMatch = r.googleCurrentName?.toLowerCase().contains(query) ?? false;
    final cityMatch = r.city.toLowerCase().contains(query);
    final stateMatch = r.state.toLowerCase().contains(query);
    final cuisineMatch = r.cuisineType.toLowerCase().contains(query);
    final dishMatch = r.dishes.any(
      (d) => d.dishName.toLowerCase().contains(query),
    );

    return nameMatch || currentNameMatch || cityMatch || stateMatch || cuisineMatch || dishMatch;
  }).toList();

  // Proximity tiebreaker: sort results by distance if user location is available
  final userPos = ref.watch(userLocationProvider).value;
  if (userPos != null) {
    results.sort((a, b) {
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;
      final distA = haversineDistanceMiles(
        userPos.latitude, userPos.longitude, a.latitude!, a.longitude!,
      );
      final distB = haversineDistanceMiles(
        userPos.latitude, userPos.longitude, b.latitude!, b.longitude!,
      );
      return distA.compareTo(distB);
    });
  }

  return results;
}
