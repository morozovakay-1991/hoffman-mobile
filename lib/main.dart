import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/dev/debug_grid.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } on Object catch (error) {
    // No GoogleService-Info.plist / google-services.json yet: Remote Config
    // flags fall back to their defaults (see RemoteConfigFeatureFlags).
    debugPrint('Firebase not initialized: $error');
  }
  try {
    // Meditations keep playing in the background, with the system media
    // controls.
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.hoffman.hoffman.channel.audio',
      androidNotificationChannelName: 'Медитации',
      androidNotificationOngoing: true,
    );
  } on Object catch (error) {
    debugPrint('Background audio not initialized: $error');
  }
  runApp(const ProviderScope(child: HoffmanApp(debugGrid: kDebugMode)));
}

class HoffmanApp extends ConsumerWidget {
  const HoffmanApp({super.key, this.debugGrid = false});

  /// Adds the Figma layout grid toggle ([DebugGridHost]) over every screen.
  /// Only `main()` turns it on, and only in debug builds: release builds
  /// compile it out, and tests (and their goldens) run without it.
  final bool debugGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Hoffman',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
      builder: debugGridBuilder(enabled: kDebugMode && debugGrid),
    );
  }
}
