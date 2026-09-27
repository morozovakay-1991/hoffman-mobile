import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/profile/index.dart';
import 'package:hoffman/main.dart';

import '../../helpers/app_harness.dart';
import 'profile_harness.dart';

// Goldens at the Figma frame size (393×852 @1x), as in auth_goldens_test.
// Record them in the Linux container CI runs on (see the README section
// "Golden tests"), not on macOS — glyph rendering differs between them.

const FakeResponse _documents = FakeResponse(200, {
  'data': [
    {'slug': 'license', 'title': 'Лицензионное соглашение'},
    {'slug': 'privacy', 'title': 'Политика конфиденциальности'},
    {'slug': 'terms', 'title': 'Условия использования'},
  ],
});

const FakeResponse _license = FakeResponse(200, {
  'data': {
    'title': 'Лицензионное соглашение',
    'body':
        '<p>Lorem Ipsum is simply dummy text of the printing and typesetting '
        'industry. Lorem Ipsum has been the industry standard dummy text '
        'ever since the 1500s.</p>'
        '<ul><li>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed '
        'do eiusmod tempor incididunt ut labore et dolore magna aliqua.</li>'
        '<li>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</li>'
        '</ul><ol><li>Lorem ipsum dolor sit amet, consectetur adipiscing '
        'elit.</li><li>Sed do eiusmod tempor incididunt ut labore.</li></ol>',
  },
});

/// The whole app at @1x, signed in, on [location] pushed over the profile.
Future<ProviderContainer> _open(
  WidgetTester tester,
  String location, {
  Map<String, FakeResponse> routes = const {},
}) async {
  useFigmaViewport(tester, pixelRatio: 1);
  final container = profileEnv({
    legalList: _documents,
    legalDocument('license'): _license,
    patchEmail: const FakeResponse(200, {'message': 'sent'}),
    ...routes,
  }).createContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const HoffmanApp()),
  );
  await finishSplash(tester);
  final router = container.read(appRouterProvider)..go(AppRoutes.profile);
  await tester.pumpAndSettle();
  if (location != AppRoutes.profile) {
    unawaited(router.push<Object?>(location));
    await tester.pumpAndSettle();
  }
  // Asset images decode outside the fake clock.
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(ProfileScreen.coverAsset),
      tester.element(find.byType(Navigator).first),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _expectGolden(String name) => expectLater(
  find.byType(HoffmanApp),
  matchesGoldenFile('goldens/$name.png'),
);

void main() {
  testWidgets('Profile, not verified — Figma 651:3334', (tester) async {
    await _open(tester, AppRoutes.profile);
    await _expectGolden('profile_not_verified');
  });

  testWidgets('Profile, verified — Figma 651:3729', (tester) async {
    await _open(
      tester,
      AppRoutes.profile,
      routes: {verificationStatus: verification('confirmed')},
    );
    await _expectGolden('profile_verified');
  });

  testWidgets('Sign out sheet — Figma 1000:3424', (tester) async {
    await _open(tester, AppRoutes.profile);
    await tapAndSettle(tester, find.widgetWithText(ProfileMenuTile, 'Выйти'));
    await _expectGolden('profile_sign_out_sheet');
  });

  testWidgets('Personal data — Figma 642:3311', (tester) async {
    await _open(tester, AppRoutes.profilePersonalData);
    await _expectGolden('profile_personal_data');
  });

  testWidgets('Name — Figma 642:3475', (tester) async {
    await _open(tester, AppRoutes.profileName);
    await _expectGolden('profile_name');
  });

  testWidgets('Email — Figma 642:3504', (tester) async {
    await _open(tester, AppRoutes.profileEmail);
    await _expectGolden('profile_email');
  });

  testWidgets('Email code — Figma 848:1330', (tester) async {
    await _open(tester, AppRoutes.profileEmail);
    await tester.enterText(
      fieldIn(EditEmailScreen.emailFieldKey),
      'example@gmail.com',
    );
    await tapAndSettle(tester, buttonIn(EditEmailScreen.submitKey));
    await _expectGolden('profile_email_code');
    await tester.pump(EmailCodeScreen.resendCooldown);
  });

  testWidgets('Password — Figma 642:3533', (tester) async {
    await _open(tester, AppRoutes.profilePassword);
    await _expectGolden('profile_password');
  });

  testWidgets('Notifications — Figma 642:3433', (tester) async {
    await _open(tester, AppRoutes.profileNotifications);
    await _expectGolden('profile_notifications');
  });

  testWidgets('Legal documents — Figma 642:3358', (tester) async {
    await _open(tester, AppRoutes.profileLegal);
    await _expectGolden('profile_legal');
  });

  testWidgets('Legal document — Figma 642:3400', (tester) async {
    await _open(tester, AppRoutes.profileLegalDocument('license'));
    await _expectGolden('profile_legal_document');
  });

  testWidgets('Delete account — Figma 755:3939', (tester) async {
    await _open(tester, AppRoutes.profileDeleteAccount);
    await _expectGolden('profile_delete_account');
  });

  testWidgets('Delete account sheet — Figma 1000:2891', (tester) async {
    await _open(tester, AppRoutes.profileDeleteAccount);
    await tapAndSettle(tester, buttonIn(DeleteAccountScreen.deleteAccountKey));
    expect(find.byType(ConfirmSheet), findsOneWidget);
    await _expectGolden('profile_delete_account_sheet');
  });

  testWidgets('Account deleted — Figma 753:3884', (tester) async {
    await _open(
      tester,
      AppRoutes.profileDeleteAccount,
      routes: {deleteProfile: const FakeResponse(204)},
    );
    await tapAndSettle(tester, buttonIn(DeleteAccountScreen.deleteAccountKey));
    await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));
    await _expectGolden('profile_account_deleted');
  });
}
