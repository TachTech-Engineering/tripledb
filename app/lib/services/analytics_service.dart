// lib/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _enabled = false;

  /// Call this ONCE on app start, BEFORE any events
  Future<void> initialize({required bool analyticsConsent}) async {
    _enabled = analyticsConsent;
    await _analytics.setConsent(
      analyticsStorageConsentGranted: analyticsConsent,
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
  }

  /// Update consent (e.g., user changes cookie preferences)
  Future<void> updateConsent(bool granted) async {
    _enabled = granted;
    await _analytics.setConsent(
      analyticsStorageConsentGranted: granted,
    );
  }

  /// Track page view
  Future<void> logPageView(String pageName) async {
    if (!_enabled) return;
    await _analytics.logScreenView(screenName: pageName);
  }

  /// Track search
  Future<void> logSearch(String term, int resultCount) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'search', parameters: {
      'search_term': term,
      'result_count': resultCount,
    });
  }

  /// Track restaurant detail view
  Future<void> logViewRestaurant(String id, String name) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'view_restaurant', parameters: {
      'restaurant_id': id,
      'restaurant_name': name,
    });
  }

  /// Track filter toggle
  Future<void> logFilterToggle(String filterName, bool enabled) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'filter_toggle', parameters: {
      'filter_name': filterName,
      'enabled': enabled.toString(),
    });
  }

  /// Track external link tap
  Future<void> logExternalLink(String linkType) async {
    if (!_enabled) return;
    await _analytics.logEvent(name: 'external_link', parameters: {
      'link_type': linkType,
    });
  }

  /// Track consent response
  Future<void> logConsentGiven(Map<String, bool> prefs) async {
    // Always log consent events (even if analytics denied, this is considered essential for transparency)
    await _analytics.logEvent(name: 'consent_given', parameters: {
      'analytics': (prefs['analytics'] ?? false).toString(),
      'preferences': (prefs['preferences'] ?? false).toString(),
    });
  }
}
