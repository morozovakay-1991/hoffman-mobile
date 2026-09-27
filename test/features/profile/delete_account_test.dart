import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/index.dart';

import '../../helpers/app_harness.dart';
import 'profile_harness.dart';

Future<ProviderContainer> _open(WidgetTester tester, TestEnvironment env) =>
    openProfile(tester, env, location: AppRoutes.profileDeleteAccount);

Future<void> _tapDelete(WidgetTester tester) =>
    tapAndSettle(tester, buttonIn(DeleteAccountScreen.deleteAccountKey));

void main() {
  group('755:3939 — "Запросить удаление данных"', () {
    testWidgets('sends the request; the user stays signed in', (tester) async {
      final env = profileEnv({
        deletionRequest: const FakeResponse(201, {
          'deletion_request': {
            'status': 'pending',
            'reason': null,
            'scheduled_for': '2026-10-27T10:00:00Z',
            'completed_at': null,
          },
        }),
      });
      final container = await _open(tester, env);

      expect(find.textContaining('до 30 дней'), findsOneWidget);
      await tapAndSettle(
        tester,
        buttonIn(DeleteAccountScreen.requestDeletionKey),
      );

      expect(env.backend.requestsTo(deletionRequest), hasLength(1));
      expect(find.text(ProfileText.deletionRequested), findsOneWidget);
      expect(currentPath(container), AppRoutes.profileDeleteAccount);
      expect(env.tokenStorage.token, 'token');
    });

    testWidgets('an already pending request is reported', (tester) async {
      await _open(
        tester,
        profileEnv({
          deletionRequest: FakeResponse.error(
            422,
            'DELETION_ALREADY_REQUESTED',
          ),
        }),
      );

      await tapAndSettle(
        tester,
        buttonIn(DeleteAccountScreen.requestDeletionKey),
      );

      expect(find.text(ProfileText.deletionAlreadyRequested), findsOneWidget);
    });
  });

  group('1000:2891 → 753:3884 — "Удалить аккаунт"', () {
    testWidgets('asks first; "Отменить" deletes nothing', (tester) async {
      final env = profileEnv();
      final container = await _open(tester, env);

      await _tapDelete(tester);
      expect(find.text(ConfirmSheet.defaultTitle), findsOneWidget);
      expect(find.text(DeleteAccountScreen.confirmMessage), findsOneWidget);

      await tapAndSettle(tester, find.byKey(ConfirmSheet.cancelKey));

      expect(env.backend.requestsTo(deleteProfile), isEmpty);
      expect(currentPath(container), AppRoutes.profileDeleteAccount);
      expect(env.tokenStorage.token, 'token');
    });

    testWidgets('confirmed: DELETE /profile, the token is dropped and '
        '"Ваш аккаунт удален" is shown', (tester) async {
      final env = profileEnv({deleteProfile: const FakeResponse(204)});
      final container = await _open(tester, env);

      await _tapDelete(tester);
      await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));

      expect(env.backend.requestsTo(deleteProfile), hasLength(1));
      // The backend has already revoked it: no /auth/logout round trip.
      expect(env.backend.requestsTo(logout), isEmpty);
      expect(env.tokenStorage.token, isNull);
      expect(
        container.read(authControllerProvider).value,
        const Unauthenticated(),
      );
      expect(currentPath(container), AppRoutes.accountDeleted);
      expect(find.byType(AccountDeletedScreen), findsOneWidget);
      expect(find.text('Ваш аккаунт удален'), findsOneWidget);
    });

    testWidgets('"Войти" and "Зарегистрироваться" lead to the auth screens', (
      tester,
    ) async {
      final env = profileEnv({deleteProfile: const FakeResponse(204)});
      final container = await _open(tester, env);
      await _tapDelete(tester);
      await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));

      await tapAndSettle(tester, buttonIn(AccountDeletedScreen.registerKey));
      expect(currentPath(container), AppRoutes.register);

      container.read(appRouterProvider).go(AppRoutes.accountDeleted);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, buttonIn(AccountDeletedScreen.loginKey));
      expect(currentPath(container), AppRoutes.login);
    });

    testWidgets('registration off: no "Зарегистрироваться"', (tester) async {
      final env = profileEnv({deleteProfile: const FakeResponse(204)});
      env.flags.registration = false;
      await _open(tester, env);
      await _tapDelete(tester);
      await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));

      expect(find.byKey(AccountDeletedScreen.loginKey), findsOneWidget);
      expect(find.byKey(AccountDeletedScreen.registerKey), findsNothing);
    });

    testWidgets('offline: the account and session stay, with a message', (
      tester,
    ) async {
      final env = profileEnv();
      final container = await _open(tester, env);
      env.backend.offline = true;

      await _tapDelete(tester);
      await tapAndSettle(tester, find.byKey(ConfirmSheet.confirmKey));

      expect(find.text(AuthErrorText.network), findsOneWidget);
      expect(currentPath(container), AppRoutes.profileDeleteAccount);
      expect(env.tokenStorage.token, 'token');
    });
  });

  testWidgets('"Политика конфиденциальности" opens the privacy document', (
    tester,
  ) async {
    final env = profileEnv({
      legalDocument('privacy'): const FakeResponse(200, {
        'data': {
          'title': 'Политика конфиденциальности',
          'body': '<p>Текст</p>',
        },
      }),
    });
    final container = await _open(tester, env);

    await tapAndSettle(
      tester,
      find.byKey(DeleteAccountScreen.privacyPolicyKey),
    );

    expect(currentPath(container), '/profile/legal/privacy');
    expect(find.text('Политика конфиденциальности'), findsOneWidget);
  });
}
