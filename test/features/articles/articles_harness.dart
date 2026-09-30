import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/services/text_sharer.dart';

import '../../helpers/app_harness.dart';
import '../home/home_harness.dart';

export '../home/home_harness.dart';

/// Launches the app (on home) with [env] and opens [location]: switches to
/// it when it is a tab, pushes it otherwise.
Future<ProviderContainer> openAt(
  WidgetTester tester,
  TestEnvironment env,
  String location,
) async {
  final container = await pumpApp(tester, env);
  final router = container.read(appRouterProvider);
  if (AppTab.of(location) != null) {
    router.go(location);
  } else {
    unawaited(router.push(location));
  }
  await tester.pumpAndSettle();
  return container;
}

/// What the share sheet got.
typedef SharedText = ({String text, String? subject, Rect? origin});

/// [homeEnv] with [routes] whose share sheet adds to [shared] instead.
TestEnvironment shareEnv(
  List<SharedText> shared, [
  Map<String, FakeResponse> routes = const {},
]) {
  final base = homeEnv(routes);
  return TestEnvironment(
    token: 'token',
    backend: base.backend,
    extraOverrides: [
      textSharerProvider.overrideWithValue((text, {subject, origin}) async {
        shared.add((text: text, subject: subject, origin: origin));
      }),
    ],
  );
}
