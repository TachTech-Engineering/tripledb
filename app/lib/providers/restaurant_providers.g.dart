// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredRestaurantsHash() =>
    r'fc869df8a4de4c525bf173c1d11d09ad26951997';

/// See also [filteredRestaurants].
@ProviderFor(filteredRestaurants)
final filteredRestaurantsProvider =
    AutoDisposeFutureProvider<List<Restaurant>>.internal(
      filteredRestaurants,
      name: r'filteredRestaurantsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredRestaurantsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredRestaurantsRef = AutoDisposeFutureProviderRef<List<Restaurant>>;
String _$restaurantListHash() => r'37215e6a82dba960626901682742167a0daf140b';

/// See also [RestaurantList].
@ProviderFor(RestaurantList)
final restaurantListProvider =
    AutoDisposeAsyncNotifierProvider<RestaurantList, List<Restaurant>>.internal(
      RestaurantList.new,
      name: r'restaurantListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$restaurantListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RestaurantList = AutoDisposeAsyncNotifier<List<Restaurant>>;
String _$searchQueryHash() => r'446383cb599327bea368f8da496260b05a5f9bec';

/// See also [SearchQuery].
@ProviderFor(SearchQuery)
final searchQueryProvider =
    AutoDisposeNotifierProvider<SearchQuery, String>.internal(
      SearchQuery.new,
      name: r'searchQueryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$searchQueryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SearchQuery = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
