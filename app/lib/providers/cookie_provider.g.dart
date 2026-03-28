// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cookieService)
final cookieServiceProvider = CookieServiceProvider._();

final class CookieServiceProvider
    extends
        $FunctionalProvider<
          CookieConsentService,
          CookieConsentService,
          CookieConsentService
        >
    with $Provider<CookieConsentService> {
  CookieServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookieServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookieServiceHash();

  @$internal
  @override
  $ProviderElement<CookieConsentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CookieConsentService create(Ref ref) {
    return cookieService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookieConsentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookieConsentService>(value),
    );
  }
}

String _$cookieServiceHash() => r'3978bf9c8d848076f597af4fec9046a9e83c346b';

@ProviderFor(analyticsService)
final analyticsServiceProvider = AnalyticsServiceProvider._();

final class AnalyticsServiceProvider
    extends
        $FunctionalProvider<
          AnalyticsService,
          AnalyticsService,
          AnalyticsService
        >
    with $Provider<AnalyticsService> {
  AnalyticsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsServiceHash();

  @$internal
  @override
  $ProviderElement<AnalyticsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsService create(Ref ref) {
    return analyticsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsService>(value),
    );
  }
}

String _$analyticsServiceHash() => r'a78e9020e79b5e99632cc4cee7e5f7156c672acd';

@ProviderFor(HasConsented)
final hasConsentedProvider = HasConsentedProvider._();

final class HasConsentedProvider extends $NotifierProvider<HasConsented, bool> {
  HasConsentedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasConsentedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasConsentedHash();

  @$internal
  @override
  HasConsented create() => HasConsented();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasConsentedHash() => r'a4362bec09ff530c0e4d22c747358ff7e6c93228';

abstract class _$HasConsented extends $Notifier<bool> {
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
