import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/config/feature_flags.dart';

void main() {
  test('registration_enabled defaults to true without Firebase', () async {
    // No Firebase.initializeApp() in tests, as in builds without
    // GoogleService-Info.plist / google-services.json.
    expect(await RemoteConfigFeatureFlags().registrationEnabled(), isTrue);
    expect(
      RemoteConfigFeatureFlags.defaults[RemoteConfigFeatureFlags
          .registrationEnabledKey],
      isTrue,
    );
  });

  test(
    'admin_contact_url falls back to the placeholder without Firebase',
    () async {
      expect(
        await RemoteConfigFeatureFlags().adminContactUrl(),
        adminContactUrlFallback,
      );
      expect(Uri.parse(adminContactUrlFallback).host, 't.me');
    },
  );
}
