// lib/services/cookie_consent_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html; // Web-only

class CookieConsentService {
  static const String _cookieName = 'tripledb_consent';
  static const int _expiryDays = 365;

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

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
      final trimmed = cookie.trim();
      final idx = trimmed.indexOf('=');
      if (idx < 0) continue;
      final name = trimmed.substring(0, idx).trim();
      if (name != _cookieName) continue;
      try {
        final value = trimmed.substring(idx + 1).trim();
        final decoded = Uri.decodeComponent(value);
        final parsed = Map<String, dynamic>.from(jsonDecode(decoded));
        // Validate structure: must have 'essential' key
        if (!parsed.containsKey('essential')) return null;
        return parsed.map((k, v) => MapEntry(k, v == true));
      } catch (_) {
        return null; // Malformed cookie — treat as no consent
      }
    }
    return null;
  }

  /// Format a DateTime as RFC 1123 (required for cookie expires attribute)
  static String _toRfc1123(DateTime dt) {
    final utc = dt.toUtc();
    final weekday = _weekdays[utc.weekday - 1];
    final month = _months[utc.month - 1];
    final day = utc.day.toString().padLeft(2, '0');
    final hour = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final sec = utc.second.toString().padLeft(2, '0');
    return '$weekday, $day $month ${utc.year} $hour:$min:$sec GMT';
  }

  void _writeCookie() {
    if (!kIsWeb) return;

    final value = Uri.encodeComponent(jsonEncode(_current));
    final expiry = DateTime.now().add(const Duration(days: _expiryDays));
    final expires = _toRfc1123(expiry);

    // Only set Secure flag on HTTPS (Secure cookies are silently rejected on HTTP)
    final isSecure = html.window.location.protocol == 'https:';
    final secureFlag = isSecure ? '; Secure' : '';

    html.document.cookie =
        '$_cookieName=$value; expires=$expires; path=/; SameSite=Lax$secureFlag';
  }
}
