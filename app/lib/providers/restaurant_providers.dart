import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/restaurant_models.dart';
import '../services/data_service.dart';

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
Future<List<Restaurant>> filteredRestaurants(FilteredRestaurantsRef ref) async {
  final restaurants = await ref.watch(restaurantListProvider.future);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return restaurants;
  }

  return restaurants.where((r) {
    final nameMatch = r.name.toLowerCase().contains(query);
    final cityMatch = r.city.toLowerCase().contains(query);
    final stateMatch = r.state.toLowerCase().contains(query);
    final cuisineMatch = r.cuisineType.toLowerCase().contains(query);
    final dishMatch = r.dishes.any(
      (d) => d.dishName.toLowerCase().contains(query),
    );

    return nameMatch || cityMatch || stateMatch || cuisineMatch || dishMatch;
  }).toList();
}
