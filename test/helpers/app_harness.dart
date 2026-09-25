import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/config/feature_flags.dart';
import 'package:hoffman/core/network/index.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/onboarding/index.dart';
import 'package:hoffman/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory [TokenStorage].
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> writeAccessToken(String token) async => this.token = token;

  @override
  Future<void> deleteAccessToken() async => token = null;
}

class FakeFeatureFlags implements FeatureFlags {
  FakeFeatureFlags({this.registration = true});

  bool registration;

  @override
  Future<bool> registrationEnabled() async => registration;
}

/// A canned backend response.
class FakeResponse {
  const FakeResponse(this.status, [this.body, this.headers = const {}]);

  /// hoffman-backend's error shape, `{error: {code, message, fields}}`.
  factory FakeResponse.error(
    int status,
    String code, {
    Map<String, List<String>> fields = const {},
    Map<String, String> headers = const {},
  }) {
    return FakeResponse(status, {
      'error': {'code': code, 'message': code, 'fields': fields},
    }, headers);
  }

  final int status;
  final Object? body;
  final Map<String, String> headers;
}

const Map<String, Object> testUserJson = {
  'id': 1,
  'name': 'Kate',
  'email': 'kate@example.com',
  'created_at': '2026-09-25T10:00:00Z',
};

const FakeResponse authSuccess = FakeResponse(200, {
  'user': testUserJson,
  'token': 'new-token',
});

/// [HttpClientAdapter] answering `'METHOD /path'` keys from [routes]; an
/// unknown route answers 404. Records every request in [requests].
class FakeBackend implements HttpClientAdapter {
  FakeBackend([Map<String, FakeResponse>? routes]) : routes = {...?routes};

  final Map<String, FakeResponse> routes;
  final List<RequestOptions> requests = [];

  /// When set, every request fails as if the device were offline.
  bool offline = false;

  List<RequestOptions> requestsTo(String route) => requests
      .where((r) => '${r.method} ${r.path}' == route)
      .toList(growable: false);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    final response =
        routes['${options.method} ${options.path}'] ??
        FakeResponse.error(404, 'NOT_FOUND');
    return ResponseBody.fromString(
      response.body == null ? '' : jsonEncode(response.body),
      response.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final h in response.headers.entries) h.key: [h.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Everything the app talks to, faked.
class TestEnvironment {
  TestEnvironment({
    FakeBackend? backend,
    String? token,
    bool registrationEnabled = true,
    this.onboardingSeen = true,
  }) : backend = backend ?? FakeBackend(),
       tokenStorage = FakeTokenStorage(token),
       flags = FakeFeatureFlags(registration: registrationEnabled);

  final FakeBackend backend;
  final FakeTokenStorage tokenStorage;
  final FakeFeatureFlags flags;
  final bool onboardingSeen;

  List<Override> get overrides => [
    tokenStorageProvider.overrideWithValue(tokenStorage),
    featureFlagsProvider.overrideWithValue(flags),
    // The real DioClient (base URL, AuthInterceptor, logging) over the fake
    // transport.
    dioProvider.overrideWith((ref) {
      return DioClient(
        dio: Dio()..httpClientAdapter = backend,
        tokenStorage: ref.watch(tokenStorageProvider),
        onLogout: () => ref.read(sessionExpiredProvider.notifier).notify(),
      ).dio;
    }),
  ];

  ProviderContainer createContainer() {
    SharedPreferences.setMockInitialValues({
      OnboardingRepository.seenKey: onboardingSeen,
    });
    return ProviderContainer.test(overrides: overrides);
  }
}

/// iPhone 15 viewport (393×852, 49px status bar, 34px home indicator) —
/// the Figma frame size.
void useFigmaViewport(WidgetTester tester, {double pixelRatio = 3}) {
  tester.view
    ..physicalSize = const Size(393, 852) * pixelRatio
    ..devicePixelRatio = pixelRatio
    ..padding = FakeViewPadding(top: 49 * pixelRatio, bottom: 34 * pixelRatio);
  addTearDown(tester.view.reset);
}

/// Pumps the whole app ([HoffmanApp]) and lets the splash finish, so the
/// test starts wherever the app would route on launch.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  TestEnvironment env, {
  bool skipSplash = true,
}) async {
  useFigmaViewport(tester);
  final container = env.createContainer();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HoffmanApp()),
  );
  if (skipSplash) await finishSplash(tester);
  return container;
}

Future<void> finishSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(SplashScreen.totalDuration);
  await tester.pumpAndSettle();
}

/// Location of the topmost page, including pushed ones (a `push` leaves the
/// match list's `uri` on the page underneath).
String currentPath(ProviderContainer container) => container
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .last
    .matchedLocation;

/// The [TextField] inside the auth field with [key].
Finder fieldIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(TextField));

/// The tappable [AppButton] inside the submit button with [key] (the key
/// sits on a full-width row, so tapping it directly would miss).
Finder buttonIn(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(AppButton));

/// The error message currently shown under the auth field with [key].
String? errorOf(WidgetTester tester, Key key) => tester
    .widget<AppTextField>(
      find.descendant(of: find.byKey(key), matching: find.byType(AppTextField)),
    )
    .errorText;

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Registers the app font (Golos Text 400/500/600, the weights the auth
/// screens use) under the family names google_fonts generates, so goldens
/// render real glyphs instead of the test font's boxes. The TTFs in
/// `test/fonts` are the exact files google_fonts downloads at runtime.
Future<void> loadAppFonts() async {
  const files = {
    'GolosText_regular': 'GolosText-Regular.ttf',
    'GolosText_500': 'GolosText-Medium.ttf',
    'GolosText_600': 'GolosText-SemiBold.ttf',
  };
  for (final MapEntry(key: family, value: file) in files.entries) {
    final bytes = File('test/fonts/$file').readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
