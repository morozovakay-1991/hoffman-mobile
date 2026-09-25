import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

/// Runs before every test file: registers Golos Text so text is measured
/// and rendered with the app font (see [loadAppFonts]).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppFonts();
  await testMain();
}
