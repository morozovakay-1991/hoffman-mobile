import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/network/api_base_url.dart';

void main() {
  group('ApiBaseUrl.resolve', () {
    test('defaults to 10.0.2.2 for Android when no dart-define is set', () {
      expect(
        ApiBaseUrl.resolve(platform: TargetPlatform.android),
        'http://10.0.2.2:8000',
      );
    });

    test('defaults to localhost for iOS when no dart-define is set', () {
      expect(
        ApiBaseUrl.resolve(platform: TargetPlatform.iOS),
        'http://localhost:8000',
      );
    });
  });
}
