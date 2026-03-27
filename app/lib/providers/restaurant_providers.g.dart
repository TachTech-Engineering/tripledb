// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$filteredRestaurantsHash() =>
    r'34720c1c973f595621129aa409036981ce8e5b10';

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
String _$restaurantListHash() => r'd02ee08b474a50de3aa2cd3f1bcadbd5aaed7c25';

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
String _$showClosedHash() => r'0c197b8fbf754a640bab72168c491bcd526d080d';

/// See also [ShowClosed].
@ProviderFor(ShowClosed)
final showClosedProvider =
    AutoDisposeNotifierProvider<ShowClosed, bool>.internal(
      ShowClosed.new,
      name: r'showClosedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$showClosedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ShowClosed = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
