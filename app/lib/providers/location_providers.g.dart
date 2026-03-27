// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$nearbyRestaurantsHash() => r'83895f78d7b1a0db351add31246cff30304d9c92';

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
String _$userLocationHash() => r'88190ea2c54c6d7e146ec54aa4ab433fca44d726';

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
