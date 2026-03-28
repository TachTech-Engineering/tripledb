// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserLocation)
final userLocationProvider = UserLocationProvider._();

final class UserLocationProvider
    extends $AsyncNotifierProvider<UserLocation, Position?> {
  UserLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLocationHash();

  @$internal
  @override
  UserLocation create() => UserLocation();
}

String _$userLocationHash() => r'88190ea2c54c6d7e146ec54aa4ab433fca44d726';

abstract class _$UserLocation extends $AsyncNotifier<Position?> {
  FutureOr<Position?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Position?>, Position?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Position?>, Position?>,
              AsyncValue<Position?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(NearbyCount)
final nearbyCountProvider = NearbyCountProvider._();

final class NearbyCountProvider extends $NotifierProvider<NearbyCount, int> {
  NearbyCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyCountHash();

  @$internal
  @override
  NearbyCount create() => NearbyCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$nearbyCountHash() => r'a032de0f304e02ab02b3143c2e91ca301a8d1164';

abstract class _$NearbyCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(nearbyRestaurants)
final nearbyRestaurantsProvider = NearbyRestaurantsProvider._();

final class NearbyRestaurantsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NearbyRestaurant>>,
          List<NearbyRestaurant>,
          FutureOr<List<NearbyRestaurant>>
        >
    with
        $FutureModifier<List<NearbyRestaurant>>,
        $FutureProvider<List<NearbyRestaurant>> {
  NearbyRestaurantsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyRestaurantsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyRestaurantsHash();

  @$internal
  @override
  $FutureProviderElement<List<NearbyRestaurant>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NearbyRestaurant>> create(Ref ref) {
    return nearbyRestaurants(ref);
  }
}

String _$nearbyRestaurantsHash() => r'28e99458b82cfe5035586f02d33dd9950d4489e9';
