// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nearbyRestaurantsHash() => r'7b1d9faa3e37c61a2195238e412bfff386655979';

/// See also [nearbyRestaurants].
@ProviderFor(nearbyRestaurants)
final nearbyRestaurantsProvider =
    AutoDisposeFutureProvider<List<Restaurant>>.internal(
      nearbyRestaurants,
      name: r'nearbyRestaurantsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$nearbyRestaurantsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NearbyRestaurantsRef = AutoDisposeFutureProviderRef<List<Restaurant>>;
String _$userLocationHash() => r'fcb2f9e1b1a45d8705f384c9d15f300eb0dbdca1';

/// See also [UserLocation].
@ProviderFor(UserLocation)
final userLocationProvider =
    AutoDisposeAsyncNotifierProvider<UserLocation, Position?>.internal(
      UserLocation.new,
      name: r'userLocationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userLocationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserLocation = AutoDisposeAsyncNotifier<Position?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
