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
    // Do not auto-request on build to avoid Safari silent denial.
    // User must tap "Enable Location" button which calls refresh().
    return null;
  }

  void refresh() {
    state = const AsyncValue.loading();
    LocationService().getCurrentPosition().then((pos) {
      state = AsyncValue.data(pos);
    }).catchError((err, stackTrace) {
      state = AsyncValue.error(err, stackTrace);
    });
  }
}

@riverpod
Future<List<Restaurant>> nearbyRestaurants(NearbyRestaurantsRef ref) async {
  final restaurants = await ref.watch(restaurantListProvider.future);
  final userPos = await ref.watch(userLocationProvider.future);

  if (userPos == null) {
    return [];
  }

  // Filter restaurants that have lat/lng AND are still open (don't recommend closed ones)
  final validRestaurants = restaurants
      .where((r) => r.latitude != null && r.longitude != null && r.stillOpen != false)
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
