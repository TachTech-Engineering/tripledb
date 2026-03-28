// lib/widgets/cookie_consent_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/cookie_consent_service.dart';
import '../providers/cookie_provider.dart';
import '../providers/location_providers.dart';
import '../theme/app_theme.dart';

// We'll define providers later in Step 2, but let's assume they exist or use local state for now.
// For now, we'll pass the service instance or use a simple callback.

class CookieConsentBanner extends ConsumerStatefulWidget {
  final CookieConsentService cookieService;
  final VoidCallback onAction;

  const CookieConsentBanner({
    super.key,
    required this.cookieService,
    required this.onAction,
  });

  @override
  ConsumerState<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends ConsumerState<CookieConsentBanner> {
  bool _isVisible = true;

  void _hide() {
    setState(() {
      _isVisible = false;
    });
    widget.onAction();
  }

  Future<void> _applyConsent(Map<String, bool> prefs) async {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.updateConsent(prefs['analytics'] ?? false);
    analytics.logConsentGiven(prefs);

    // Request location BEFORE dismissing banner (widget must still be mounted)
    if (prefs['preferences'] == true) {
      await _requestLocation();
    }

    // NOW dismiss banner
    _hide();
  }

  Future<void> _requestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        ref.read(userLocationProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('Location request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 16,
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🍪', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We use cookies to improve your experience.',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Essential cookies keep the app working. Analytics cookies help us understand which features you use most.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppTheme.onSurfaceDark.withValues(alpha: 0.8) : AppTheme.onSurfaceLight.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        widget.cookieService.acceptAll();
                        _applyConsent({'essential': true, 'analytics': true, 'preferences': true});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Accept All'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        widget.cookieService.declineAll();
                        _applyConsent({'essential': true, 'analytics': false, 'preferences': false});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                        foregroundColor: isDark ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                    TextButton(
                      onPressed: () => _showCustomizeModal(context),
                      child: const Text('Customize'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCustomizeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CookieSettingsModal(
        cookieService: widget.cookieService,
        onSaved: _applyConsent,
      ),
    );
  }
}

class CookieSettingsModal extends ConsumerStatefulWidget {
  final CookieConsentService cookieService;
  final Future<void> Function(Map<String, bool>) onSaved;

  const CookieSettingsModal({
    super.key,
    required this.cookieService,
    required this.onSaved,
  });

  @override
  ConsumerState<CookieSettingsModal> createState() => _CookieSettingsModalState();
}

class _CookieSettingsModalState extends ConsumerState<CookieSettingsModal> {
  late Map<String, bool> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = Map.from(widget.cookieService.currentPreferences);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cookie Settings',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildToggle(
            'Essential',
            'Required for the app to function. Cannot be disabled.',
            _prefs['essential'] ?? true,
            null, // null = disabled
          ),
          _buildToggle(
            'Analytics',
            'Helps us improve the app by tracking feature usage.',
            _prefs['analytics'] ?? false,
            (val) => setState(() => _prefs['analytics'] = val),
          ),
          _buildToggle(
            'Preferences',
            'Remembers your settings, location for nearby restaurants, and recent searches.',
            _prefs['preferences'] ?? false,
            (val) => setState(() => _prefs['preferences'] = val),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                widget.cookieService.setPreferences(_prefs);
                // Request location BEFORE dismissing (v9.43 fix)
                // onSaved triggers _applyConsent which needs mounted widget
                await widget.onSaved(_prefs);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String subtitle, bool value, ValueChanged<bool>? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.secondary.withValues(alpha: 0.5),
            activeThumbColor: AppTheme.secondary,
          ),
        ],
      ),
    );
  }
}
