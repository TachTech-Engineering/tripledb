import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/restaurant_models.dart';
import '../services/location_service.dart';
import 'restaurant_providers.dart';

part 'location_providers.g.dart';

@riverpod
class UserLocation extends _$UserLocation {
  @override
  Future<Position?> build() async {
    return LocationService().getCurrentPosition();
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

@riverpod
Future<List<Restaurant>> nearbyRestaurants(NearbyRestaurantsRef ref) async {
  final restaurants = await ref.watch(restaurantListProvider.future);
  final userPos = await ref.watch(userLocationProvider.future);

  if (userPos == null) {
    return [];
  }

  // Filter restaurants that have lat/lng
  final validRestaurants = restaurants
      .where((r) => r.latitude != null && r.longitude != null)
      .toList();

  // Sort by distance
  validRestaurants.sort((a, b) {
    final distA = LocationService().distanceBetween(
      userPos.latitude,
      userPos.longitude,
      a.latitude!,
      a.longitude!,
    );
    final distB = LocationService().distanceBetween(
      userPos.latitude,
      userPos.longitude,
      b.latitude!,
      b.longitude!,
    );
    return distA.compareTo(distB);
  });

  // Return top 3
  return validRestaurants.take(3).toList();
}
