import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'helpers/app_harness.dart';

/// Runs before every test file: registers Golos Text so text is measured
/// and rendered with the app font (see [loadAppFonts]). Runtime fetching is
/// off so google_fonts never reaches for the network in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await loadAppFonts();
  await testMain();
}
