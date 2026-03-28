import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/cookie_consent_service.dart';
import '../services/analytics_service.dart';

part 'cookie_provider.g.dart';

@riverpod
CookieConsentService cookieService(Ref ref) {
  return CookieConsentService();
}

@riverpod
AnalyticsService analyticsService(Ref ref) {
  return AnalyticsService();
}

@riverpod
class HasConsented extends _$HasConsented {
  @override
  bool build() {
    final service = ref.watch(cookieServiceProvider);
    return service.hasConsented;
  }

  void set(bool value) => state = value;
}
