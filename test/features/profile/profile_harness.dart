import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';

import '../../helpers/app_harness.dart';

const me = 'GET /api/v1/auth/me';
const logout = 'POST /api/v1/auth/logout';
const verificationStatus = 'GET /api/v1/verification/status';
const getProfile = 'GET /api/v1/profile';
const patchProfile = 'PATCH /api/v1/profile';
const patchEmail = 'PATCH /api/v1/profile/email';
const confirmEmail = 'POST /api/v1/profile/email/confirm';
const patchPassword = 'PATCH /api/v1/profile/password';
const patchNotifications = 'PATCH /api/v1/profile/notifications';
const deletionRequest = 'POST /api/v1/profile/deletion-request';
const deleteProfile = 'DELETE /api/v1/profile';
const legalList = 'GET /api/v1/legal-documents';
String legalDocument(String slug) => 'GET /api/v1/legal-documents/$slug';

/// Backend `ProfileResource`.
Map<String, Object?> profileJson({
  int id = 1,
  String name = 'Kate',
  String email = 'kate@example.com',
  Map<String, bool>? notifications = const {
    'push_enabled': true,
    'email_enabled': true,
    'marketing_enabled': false,
    'daily_practices_enabled': true,
    'new_articles_enabled': true,
    'system_enabled': false,
  },
}) {
  return {
    'id': id,
    'name': name,
    'email': email,
    'timezone': 'Europe/Moscow',
    'graduate_status': 'unverified',
    'email_verified_at': null,
    'notification_settings': ?notifications,
    'created_at': '2026-09-25T10:00:00Z',
  };
}

FakeResponse profileResponse({
  String name = 'Kate',
  String email = 'kate@example.com',
}) => FakeResponse(200, {'profile': profileJson(name: name, email: email)});

/// Backend `VerificationRequestResource`, or no request at all.
FakeResponse verification(String? status) => FakeResponse(200, {
  'verification_request': status == null
      ? null
      : {
          'id': 1,
          'status': status,
          'last_name': 'Иванова',
          'first_name': 'Анна',
          'phone': '+79990000000',
        },
});

/// A signed-in user with a profile and no verification request.
TestEnvironment profileEnv([Map<String, FakeResponse> routes = const {}]) {
  return TestEnvironment(
    token: 'token',
    backend: FakeBackend({
      me: const FakeResponse(200, {'user': testUserJson}),
      logout: const FakeResponse(200, {'message': 'ok'}),
      verificationStatus: verification(null),
      getProfile: profileResponse(),
      ...routes,
    }),
  );
}

/// Launches the app signed in and opens [location] (pushed over the
/// profile screen when it is not the profile itself, as the menus do).
Future<ProviderContainer> openProfile(
  WidgetTester tester,
  TestEnvironment env, {
  String location = AppRoutes.profile,
}) async {
  final container = await pumpApp(tester, env);
  final router = container.read(appRouterProvider)..go(AppRoutes.profile);
  await tester.pumpAndSettle();
  if (location != AppRoutes.profile) {
    unawaited(router.push<Object?>(location));
    await tester.pumpAndSettle();
  }
  return container;
}

/// The body sent with the last request to [route].
Map<String, dynamic> lastBody(TestEnvironment env, String route) =>
    env.backend.requestsTo(route).last.data as Map<String, dynamic>;
