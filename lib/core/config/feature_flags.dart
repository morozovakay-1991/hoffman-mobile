import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature flags served by Firebase Remote Config.
abstract class FeatureFlags {
  /// `registration_enabled`: when false the Login screen hides the sign-up
  /// link and the router blocks `/register`.
  Future<bool> registrationEnabled();
}

/// [FeatureFlags] backed by Firebase Remote Config.
///
/// Falls back to [defaults] whenever Firebase is not initialized (e.g. no
/// `GoogleService-Info.plist` / `google-services.json` yet) or the fetch
/// fails or times out, so a missing config never blocks the app start.
class RemoteConfigFeatureFlags implements FeatureFlags {
  RemoteConfigFeatureFlags({this.fetchTimeout = const Duration(seconds: 5)});

  static const String registrationEnabledKey = 'registration_enabled';

  static const Map<String, Object> defaults = {registrationEnabledKey: true};

  final Duration fetchTimeout;
  Future<FirebaseRemoteConfig?>? _config;

  @override
  Future<bool> registrationEnabled() async {
    final config = await (_config ??= _activate());
    if (config == null) return defaults[registrationEnabledKey]! as bool;
    return config.getBool(registrationEnabledKey);
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

/// Resolved `registration_enabled` flag. Never errors — see
/// [RemoteConfigFeatureFlags].
final registrationEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(featureFlagsProvider).registrationEnabled(),
);
