// lib/services/cookie_consent_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Web-only

class CookieConsentService {
  static const String _cookieName = 'tripledb_consent';
  static const int _expiryDays = 365;

  // Default: all optional categories OFF (GDPR-compliant)
  static const Map<String, bool> _defaults = {
    'essential': true, // Always on, not toggleable
    'analytics': false, // Firebase Analytics — opt-in
    'preferences': false, // Dark mode, location, search history — opt-in
  };

  Map<String, bool> _current = {};
  bool _initialized = false;

  CookieConsentService();

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    try {
      _current = _readCookie() ?? {};
    } catch (_) {
      _current = {}; // Fail gracefully — treat as first visit
    }
  }

  /// Whether the consent banner has been shown (cookie exists)
  bool get hasConsented {
    _ensureInitialized();
    return _current.isNotEmpty;
  }

  /// Check consent for a specific category
  bool hasConsent(String category) {
    _ensureInitialized();
    if (category == 'essential') return true;
    return _current[category] ?? _defaults[category] ?? false;
  }

  /// Get all current preferences
  Map<String, bool> get currentPreferences {
    _ensureInitialized();
    return Map.from(_defaults)..addAll(_current);
  }

  /// Accept all cookies
  void acceptAll() {
    _current = {'essential': true, 'analytics': true, 'preferences': true};
    _writeCookie();
  }

  /// Decline all optional cookies
  void declineAll() {
    _current = {'essential': true, 'analytics': false, 'preferences': false};
    _writeCookie();
  }

  /// Set custom preferences
  void setPreferences(Map<String, bool> prefs) {
    _current = {'essential': true, ...prefs};
    _current['essential'] = true; // Force essential on
    _writeCookie();
  }

  Map<String, bool>? _readCookie() {
    if (!kIsWeb) return null;
    
    final cookies = html.document.cookie ?? '';
    for (final cookie in cookies.split(';')) {
      final parts = cookie.trim().split('=');
      if (parts.length == 2 && parts[0].trim() == _cookieName) {
        try {
          final decoded = Uri.decodeComponent(parts[1]);
          return Map<String, bool>.from(jsonDecode(decoded));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  void _writeCookie() {
    if (!kIsWeb) return;

    final value = Uri.encodeComponent(jsonEncode(_current));
    final expiry = DateTime.now().add(const Duration(days: _expiryDays));
    final expires = expiry.toUtc().toIso8601String();
    
    // Set cookie with security flags
    html.document.cookie =
        '$_cookieName=$value; expires=$expires; path=/; SameSite=Lax; Secure';
  }
}
