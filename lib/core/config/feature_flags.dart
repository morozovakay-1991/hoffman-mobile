import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags and remote settings served by Firebase Remote Config.
abstract class FeatureFlags {
  /// `registration_enabled`: when false the Login screen hides the sign-up
  /// link and the router blocks `/register`.
  Future<bool> registrationEnabled();

  /// `admin_contact_url`: the administrator's Telegram link, opened by
  /// "Написать администратору" on the "Статус не подтвержден" screen.
  Future<String> adminContactUrl();
}

/// Build-time fallback for `admin_contact_url`:
/// `--dart-define=ADMIN_CONTACT_URL=https://t.me/<account>`.
// TODO(verification): the real administrator Telegram link is not known yet.
// Set `admin_contact_url` in Remote Config (or ADMIN_CONTACT_URL at build
// time) once it is, and replace this placeholder.
const String adminContactUrlFallback = String.fromEnvironment(
  'ADMIN_CONTACT_URL',
  defaultValue: 'https://t.me/hoffman_admin_placeholder',
);

/// [FeatureFlags] backed by Firebase Remote Config.
///
/// Falls back to [defaults] whenever Firebase is not initialized (e.g. no
/// `GoogleService-Info.plist` / `google-services.json` yet) or the fetch
/// fails or times out, so a missing config never blocks the app start.
class RemoteConfigFeatureFlags implements FeatureFlags {
  RemoteConfigFeatureFlags({this.fetchTimeout = const Duration(seconds: 5)});

  static const String registrationEnabledKey = 'registration_enabled';
  static const String adminContactUrlKey = 'admin_contact_url';

  static const Map<String, Object> defaults = {
    registrationEnabledKey: true,
    adminContactUrlKey: adminContactUrlFallback,
  };

  final Duration fetchTimeout;
  Future<FirebaseRemoteConfig?>? _config;

  @override
  Future<bool> registrationEnabled() async {
    final config = await (_config ??= _activate());
    if (config == null) return defaults[registrationEnabledKey]! as bool;
    return config.getBool(registrationEnabledKey);
  }

  @override
  Future<String> adminContactUrl() async {
    final config = await (_config ??= _activate());
    final url = config?.getString(adminContactUrlKey).trim() ?? '';
    return url.isEmpty ? adminContactUrlFallback : url;
  }

  Future<FirebaseRemoteConfig?> _activate() async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final config = FirebaseRemoteConfig.instance;
      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: fetchTimeout,
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await config.setDefaults(defaults);
      await config.fetchAndActivate().timeout(fetchTimeout);
      return config;
    } on Object catch (error) {
      debugPrint('Remote Config unavailable, using defaults: $error');
      return null;
    }
  }
}

final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => RemoteConfigFeatureFlags(),
);

/// Resolved `admin_contact_url`. Never errors — see
/// [RemoteConfigFeatureFlags].
final adminContactUrlProvider = FutureProvider<String>(
  (ref) => ref.watch(featureFlagsProvider).adminContactUrl(),
);

/// Resolved `registration_enabled` flag. Never errors — see
/// [RemoteConfigFeatureFlags].
final registrationEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(featureFlagsProvider).registrationEnabled(),
);
