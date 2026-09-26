import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';

import '../../helpers/app_harness.dart';

const _me = 'GET /api/v1/auth/me';
const _submit = 'POST /api/v1/verification/submit';
const _status = 'GET /api/v1/verification/status';

FakeResponse _request(
  String status, {
  String lastName = 'Иванова',
  String firstName = 'Анна',
  String phone = '+79990000000',
}) {
  return FakeResponse(200, {
    'verification_request': {
      'id': 1,
      'status': status,
      'last_name': lastName,
      'first_name': firstName,
      'phone': phone,
      'is_duplicate': false,
      'reviewed_at': null,
      'created_at': '2026-09-25T10:00:00Z',
      'updated_at': '2026-09-25T10:00:00Z',
    },
  });
}

const FakeResponse _noRequest = FakeResponse(200, {
  'verification_request': null,
});

/// A signed-in user on the "Вы выпускник?" screen.
Future<ProviderContainer> _openQuestion(
  WidgetTester tester,
  TestEnvironment env,
) async {
  final container = await pumpApp(tester, env);
  container.read(appRouterProvider).go(AppRoutes.verification);
  await tester.pumpAndSettle();
  expect(find.byType(GraduateQuestionScreen), findsOneWidget);
  return container;
}

Future<ProviderContainer> _openForm(
  WidgetTester tester,
  TestEnvironment env,
) async {
  final container = await _openQuestion(tester, env);
  await tapAndSettle(tester, buttonIn(GraduateQuestionScreen.yesKey));
  expect(currentPath(container), AppRoutes.verificationForm);
  return container;
}

Future<void> _fill(
  WidgetTester tester, {
  String lastName = 'Иванова',
  String firstName = 'Анна',
  String phone = '+79990000000',
  bool acceptConsents = true,
}) async {
  await tester.enterText(
    fieldIn(GraduateFormScreen.lastNameFieldKey),
    lastName,
  );
  await tester.enterText(
    fieldIn(GraduateFormScreen.firstNameFieldKey),
    firstName,
  );
  await tester.enterText(fieldIn(GraduateFormScreen.phoneFieldKey), phone);
  await tester.pump();
  if (acceptConsents) {
    await tapAndSettle(tester, find.byKey(const ValueKey('consent-privacy')));
    await tapAndSettle(
      tester,
      find.byKey(const ValueKey('consent-personal-data')),
    );
  }
}

Future<void> _tapSubmit(WidgetTester tester) =>
    tapAndSettle(tester, buttonIn(GraduateFormScreen.submitKey));

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(fieldIn(key)).controller!.text;

TestEnvironment _env(Map<String, FakeResponse> routes) => TestEnvironment(
  token: 'token',
  backend: FakeBackend({
    _me: const FakeResponse(200, {'user': testUserJson}),
    _status: _noRequest,
    ...routes,
  }),
);

void main() {
  group('139:5310 — "Вы выпускник Процесса Хоффмана?"', () {
    // Registration → here is covered by register_screen_test.
    testWidgets('offers only "Да" / "Нет" — no skip option by design', (
      tester,
    ) async {
      await _openQuestion(tester, _env({}));

      expect(find.text('Вы выпускник Процесса Хоффмана?'), findsOneWidget);
      expect(find.text('Да'), findsOneWidget);
      expect(find.text('Нет'), findsOneWidget);
      expect(find.textContaining('Пропустить'), findsNothing);
    });

    testWidgets('"Нет" goes straight home without a request or message', (
      tester,
    ) async {
      final env = _env({});
      final container = await _openQuestion(tester, env);

      await tapAndSettle(tester, buttonIn(GraduateQuestionScreen.noKey));

      expect(currentPath(container), AppRoutes.home);
      expect(env.backend.requestsTo(_submit), isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('"Да" opens the form; back returns to the question', (
      tester,
    ) async {
      final env = _env({});
      final container = await _openForm(tester, env);

      await tapAndSettle(tester, find.byTooltip('Back'));

      expect(currentPath(container), AppRoutes.verification);
    });
  });

  group('139:5303 — "Данные выпускника"', () {
    testWidgets('empty fields: an error under each, nothing is sent', (
      tester,
    ) async {
      final env = _env({_submit: _request('confirmed')});
      await _openForm(tester, env);
      await _fill(tester, lastName: '', firstName: ' ', phone: '   ');

      await _tapSubmit(tester);

      expect(
        errorOf(tester, GraduateFormScreen.lastNameFieldKey),
        AuthErrorText.lastNameRequired,
      );
      expect(
        errorOf(tester, GraduateFormScreen.firstNameFieldKey),
        AuthErrorText.nameRequired,
      );
      expect(
        errorOf(tester, GraduateFormScreen.phoneFieldKey),
        AuthErrorText.phoneRequired,
      );
      expect(env.backend.requestsTo(_submit), isEmpty);
    });

    testWidgets("typing clears that field's error only", (tester) async {
      final env = _env({});
      await _openForm(tester, env);
      await _tapSubmit(tester);

      await tester.enterText(
        fieldIn(GraduateFormScreen.lastNameFieldKey),
        'Иванова',
      );
      await tester.pump();

      expect(errorOf(tester, GraduateFormScreen.lastNameFieldKey), isNull);
      expect(
        errorOf(tester, GraduateFormScreen.phoneFieldKey),
        AuthErrorText.phoneRequired,
      );
    });

    testWidgets('consents are required', (tester) async {
      final env = _env({_submit: _request('confirmed')});
      await _openForm(tester, env);
      await _fill(tester, acceptConsents: false);

      await _tapSubmit(tester);

      expect(find.text(AuthErrorText.consentRequired), findsOneWidget);
      expect(env.backend.requestsTo(_submit), isEmpty);
    });

    testWidgets('confirmed → 139:5307 → "На главную" → /home', (tester) async {
      final env = _env({_submit: _request('confirmed')});
      final container = await _openForm(tester, env);
      await _fill(tester, lastName: ' Иванова ', phone: ' +79990000000 ');

      await _tapSubmit(tester);

      expect(env.backend.requestsTo(_submit).single.data, {
        'last_name': 'Иванова',
        'first_name': 'Анна',
        'phone': '+79990000000',
      });
      expect(currentPath(container), AppRoutes.verificationConfirmed);
      expect(find.text('Статус подтвержден'), findsOneWidget);

      await tapAndSettle(tester, buttonIn(GraduateConfirmedScreen.homeKey));
      expect(currentPath(container), AppRoutes.home);
    });

    for (final status in ['pending', 'rejected', 'something_new']) {
      testWidgets('$status → 139:5306 "Статус не подтвержден"', (tester) async {
        final env = _env({_submit: _request(status)});
        final container = await _openForm(tester, env);
        await _fill(tester);

        await _tapSubmit(tester);

        expect(currentPath(container), AppRoutes.verificationNotConfirmed);
        expect(find.text('Статус не подтвержден'), findsOneWidget);
      });
    }

    testWidgets('offline: message, stays on the form, can resend', (
      tester,
    ) async {
      final env = _env({_submit: _request('confirmed')});
      final container = await _openForm(tester, env);
      await _fill(tester);
      env.backend.offline = true;

      await _tapSubmit(tester);

      expect(find.text(AuthErrorText.network), findsOneWidget);
      expect(currentPath(container), AppRoutes.verificationForm);
      expect(
        tester
            .widget<AppButton>(buttonIn(GraduateFormScreen.submitKey))
            .onPressed,
        isNotNull,
      );

      env.backend.offline = false;
      await _tapSubmit(tester);
      expect(currentPath(container), AppRoutes.verificationConfirmed);
    });

    testWidgets('429: "try again in N minutes" from Retry-After', (
      tester,
    ) async {
      final env = _env({
        _submit: const FakeResponse(429, null, {'retry-after': '60'}),
      });
      await _openForm(tester, env);
      await _fill(tester);

      await _tapSubmit(tester);

      expect(
        find.text(
          AuthErrorText.tooManyAttemptsWait(const Duration(minutes: 1)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('422 marks the fields the backend rejected', (tester) async {
      final env = _env({
        _submit: FakeResponse.error(
          422,
          'VALIDATION_ERROR',
          fields: {
            'phone': ['The phone field must not be greater than 32.'],
          },
        ),
      });
      await _openForm(tester, env);
      await _fill(tester);

      await _tapSubmit(tester);

      expect(
        errorOf(tester, GraduateFormScreen.phoneFieldKey),
        AuthErrorText.checkField,
      );
      expect(errorOf(tester, GraduateFormScreen.lastNameFieldKey), isNull);
    });

    testWidgets('prefills from GET /verification/status', (tester) async {
      final env = _env({
        _status: _request('rejected', lastName: 'Петрова', phone: '+7111'),
      });
      await _openForm(tester, env);

      expect(env.backend.requestsTo(_status), isNotEmpty);
      expect(_text(tester, GraduateFormScreen.lastNameFieldKey), 'Петрова');
      expect(_text(tester, GraduateFormScreen.firstNameFieldKey), 'Анна');
      expect(_text(tester, GraduateFormScreen.phoneFieldKey), '+7111');
    });

    testWidgets('status failing offline leaves the form empty and usable', (
      tester,
    ) async {
      final env = _env({
        _status: FakeResponse.error(500, 'SERVER_ERROR'),
        _submit: _request('confirmed'),
      });
      final container = await _openForm(tester, env);

      expect(_text(tester, GraduateFormScreen.lastNameFieldKey), isEmpty);
      await _fill(tester);
      await _tapSubmit(tester);
      expect(currentPath(container), AppRoutes.verificationConfirmed);
    });
  });

  group('139:5306 — "Статус не подтвержден"', () {
    Future<ProviderContainer> openNotConfirmed(
      WidgetTester tester,
      TestEnvironment env,
    ) async {
      final container = await _openForm(tester, env);
      await _fill(tester, lastName: 'Иванов');
      await _tapSubmit(tester);
      expect(currentPath(container), AppRoutes.verificationNotConfirmed);
      return container;
    }

    testWidgets('"Попробовать снова" reopens the form with the sent data', (
      tester,
    ) async {
      final env = _env({_submit: _request('pending', lastName: 'Иванов')});
      final container = await openNotConfirmed(tester, env);
      // The backend now reports the request that was just sent.
      env.backend.routes[_status] = _request('pending', lastName: 'Иванов');

      await tapAndSettle(tester, buttonIn(GraduateNotConfirmedScreen.retryKey));

      expect(currentPath(container), AppRoutes.verificationForm);
      expect(_text(tester, GraduateFormScreen.lastNameFieldKey), 'Иванов');
      expect(_text(tester, GraduateFormScreen.phoneFieldKey), '+79990000000');
    });

    testWidgets('"Написать администратору" opens the configured link', (
      tester,
    ) async {
      final env = _env({_submit: _request('pending')});
      await openNotConfirmed(tester, env);

      await tapAndSettle(
        tester,
        buttonIn(GraduateNotConfirmedScreen.contactAdminKey),
      );

      expect(env.launchedUrls, [Uri.parse(FakeFeatureFlags.adminUrl)]);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('link that cannot be opened shows a message', (tester) async {
      final env = _env({_submit: _request('pending')})..launchSucceeds = false;
      await openNotConfirmed(tester, env);

      await tapAndSettle(
        tester,
        buttonIn(GraduateNotConfirmedScreen.contactAdminKey),
      );

      expect(find.text(GraduateNotConfirmedScreen.linkError), findsOneWidget);
    });
  });

  testWidgets("another account never sees the previous one's request", (
    tester,
  ) async {
    final env = _env({
      _status: _request('confirmed', lastName: 'Первая'),
      'POST /api/v1/auth/logout': const FakeResponse(204),
      'POST /api/v1/auth/login': const FakeResponse(200, {
        'user': {
          'id': 2,
          'name': 'Other',
          'email': 'other@example.com',
          'created_at': '2026-09-25T10:00:00Z',
        },
        'token': 'other-token',
      }),
    });
    final container = await pumpApp(tester, env);
    final seen = <AsyncValue<VerificationRequest?>>[];
    container.listen(
      currentVerificationProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );
    await tester.pumpAndSettle();
    expect(seen.last.value?.lastName, 'Первая');

    // Network calls run inside the test's fake async zone, so they are
    // started without awaiting and driven by pumpAndSettle.
    unawaited(container.read(authControllerProvider.notifier).logout());
    await tester.pumpAndSettle();
    expect(seen.last.value, isNull);

    env.backend.routes[_status] = _noRequest;
    seen.clear();
    unawaited(
      container
          .read(authControllerProvider.notifier)
          .login(email: 'other@example.com', password: 'secret1!'),
    );
    await tester.pumpAndSettle();

    expect(seen, isNotEmpty);
    // Not even while loading: the first account's data never shows up.
    expect(seen.map((s) => s.value?.lastName), everyElement(isNull));
    expect(seen.last.hasValue, isTrue);
  });
}
