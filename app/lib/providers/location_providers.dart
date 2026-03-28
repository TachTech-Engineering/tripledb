import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/restaurant_models.dart';
import '../services/location_service.dart';
import 'restaurant_providers.dart';

part 'location_providers.g.dart';

double haversineDistanceMiles(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusMiles = 3958.8;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusMiles * c;
}

double _toRadians(double degrees) => degrees * pi / 180;

bool _hasValidLocation(Restaurant r) {
  if (r.latitude == null || r.longitude == null) return false;
  if (r.city.isEmpty || r.state.isEmpty) return false;
  const invalidValues = ['unknown', 'none', 'n/a', 'null'];
  if (invalidValues.contains(r.city.toLowerCase())) return false;
  if (invalidValues.contains(r.state.toLowerCase())) return false;
  return true;
}

class NearbyRestaurant {
  final Restaurant restaurant;
  final double distanceMiles;

  NearbyRestaurant({required this.restaurant, required this.distanceMiles});

  String get formattedDistance {
    if (distanceMiles < 1) return '${(distanceMiles * 5280).round()} ft';
    if (distanceMiles < 10) return '${distanceMiles.toStringAsFixed(1)} mi';
    if (distanceMiles < 100) return '${distanceMiles.round()} mi';
    return '${distanceMiles.round()}+ mi';
  }
}

@riverpod
class UserLocation extends _$UserLocation {
  @override
  Future<Position?> build() async {
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
class NearbyCount extends _$NearbyCount {
  @override
  int build() => 15;

  void showMore() => state = 50;
}

@riverpod
Future<List<NearbyRestaurant>> nearbyRestaurants(Ref ref) async {
  final restaurants = await ref.watch(restaurantListProvider.future);
  final userPos = await ref.watch(userLocationProvider.future);
  final count = ref.watch(nearbyCountProvider);

  if (userPos == null) {
    return [];
  }

  final validRestaurants = restaurants
      .where((r) => r.stillOpen != false && _hasValidLocation(r))
      .toList();

  final nearby = validRestaurants.map((r) {
    final distance = haversineDistanceMiles(
      userPos.latitude,
      userPos.longitude,
      r.latitude!,
      r.longitude!,
    );
    return NearbyRestaurant(restaurant: r, distanceMiles: distance);
  }).toList()
    ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

  // Deduplicate by restaurant_id and normalized name (keeps closest)
  final seenIds = <String>{};
  final seenNames = <String>{};
  final deduped = <NearbyRestaurant>[];
  for (final nr in nearby) {
    final id = nr.restaurant.id;
    final normalizedName = nr.restaurant.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (seenIds.add(id) && seenNames.add(normalizedName)) {
      deduped.add(nr);
    }
  }

  return deduped.take(count).toList();
}
