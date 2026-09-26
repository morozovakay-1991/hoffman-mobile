import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] outside the app (browser, Telegram, …). Resolves to `false`
/// when no app can handle it.
typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);

/// [ExternalUrlLauncher] backed by url_launcher. Overridden in tests.
final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      // url_launcher throws PlatformException for unsupported schemes.
      return false;
    }
  },
);
