import 'package:flutter/foundation.dart';

/// Resolves the backend API base URL.
///
/// Resolution order:
/// 1. `--dart-define=API_BASE_URL=...` — always wins when provided. This is
///    the only supported way to point the app at a physical device / staging
///    backend.
/// 2. A platform-based local-dev default, used only when no `--dart-define`
///    is supplied — reachable exclusively from an emulator/simulator running
///    on the same machine as the backend.
abstract final class ApiBaseUrl {
  static const String _dartDefine = String.fromEnvironment('API_BASE_URL');

  // TODO: подставить реальный staging URL, когда он появится. До этого
  // staging-сборки и физические устройства обязаны передавать
  // --dart-define=API_BASE_URL=<url> при сборке — локальные дефолты ниже
  // (10.0.2.2 / localhost) с них недостижимы.
  static const String _stagingPlaceholder = 'https://staging.hoffman.example.com';

  /// Returns the resolved base URL. [platform] is exposed only for testing;
  /// production code should call this with no arguments.
  static String resolve({TargetPlatform? platform}) {
    if (_dartDefine.isNotEmpty) {
      return _dartDefine;
    }

    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8000',
      TargetPlatform.iOS => 'http://localhost:8000',
      _ => _stagingPlaceholder,
    };
  }
}
