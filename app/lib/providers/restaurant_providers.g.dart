// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RestaurantList)
final restaurantListProvider = RestaurantListProvider._();

final class RestaurantListProvider
    extends $AsyncNotifierProvider<RestaurantList, List<Restaurant>> {
  RestaurantListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restaurantListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restaurantListHash();

  @$internal
  @override
  RestaurantList create() => RestaurantList();
}

String _$restaurantListHash() => r'd02ee08b474a50de3aa2cd3f1bcadbd5aaed7c25';

abstract class _$RestaurantList extends $AsyncNotifier<List<Restaurant>> {
  FutureOr<List<Restaurant>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Restaurant>>, List<Restaurant>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Restaurant>>, List<Restaurant>>,
              AsyncValue<List<Restaurant>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'446383cb599327bea368f8da496260b05a5f9bec';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ShowClosed)
final showClosedProvider = ShowClosedProvider._();

final class ShowClosedProvider extends $NotifierProvider<ShowClosed, bool> {
  ShowClosedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showClosedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showClosedHash();

  @$internal
  @override
  ShowClosed create() => ShowClosed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showClosedHash() => r'0c197b8fbf754a640bab72168c491bcd526d080d';

abstract class _$ShowClosed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(filteredRestaurants)
final filteredRestaurantsProvider = FilteredRestaurantsProvider._();

final class FilteredRestaurantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Restaurant>>,
          List<Restaurant>,
          FutureOr<List<Restaurant>>
        >
    with $FutureModifier<List<Restaurant>>, $FutureProvider<List<Restaurant>> {
  FilteredRestaurantsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredRestaurantsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredRestaurantsHash();

  @$internal
  @override
  $FutureProviderElement<List<Restaurant>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Restaurant>> create(Ref ref) {
    return filteredRestaurants(ref);
  }
}

String _$filteredRestaurantsHash() =>
    r'db0960f13f03829b8d75339e20113071b70f61e1';
