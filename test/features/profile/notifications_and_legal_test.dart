import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/features/profile/index.dart';

import '../../helpers/app_harness.dart';
import 'profile_harness.dart';

IconData? _toggleIcon(WidgetTester tester, NotificationCategory category) {
  return tester
      .widget<Icon>(
        find.descendant(
          of: find.byKey(NotificationsScreen.toggleKey(category)),
          matching: find.byType(Icon),
        ),
      )
      .icon;
}

FakeResponse _settings(Map<String, bool> changed) => FakeResponse(200, {
  'notification_settings': {
    'push_enabled': true,
    'email_enabled': true,
    'marketing_enabled': false,
    'daily_practices_enabled': true,
    'new_articles_enabled': true,
    'system_enabled': false,
    ...changed,
  },
});

const FakeResponse _documents = FakeResponse(200, {
  'data': [
    {
      'slug': 'license',
      'title': 'Лицензионное соглашение',
      'updated_at': '2026-09-01T00:00:00Z',
    },
    {
      'slug': 'privacy',
      'title': 'Политика конфиденциальности',
      'updated_at': '2026-09-01T00:00:00Z',
    },
    {
      'slug': 'terms',
      'title': 'Условия использования',
      'updated_at': '2026-09-01T00:00:00Z',
    },
  ],
});

const FakeResponse _license = FakeResponse(200, {
  'data': {
    'title': 'Лицензионное соглашение',
    'body':
        '<p>Первый абзац.</p><ul><li>Пункт списка</li></ul>'
        '<ol><li>Нумерованный пункт</li></ol>',
  },
});

void main() {
  group('642:3433 — notifications', () {
    Future<ProviderContainer> open(WidgetTester tester, TestEnvironment env) =>
        openProfile(tester, env, location: AppRoutes.profileNotifications);

    testWidgets('three categories, switched as in the profile', (tester) async {
      await open(tester, profileEnv());

      for (final label in NotificationsScreen.labels.values) {
        expect(find.text(label), findsOneWidget);
      }
      expect(
        _toggleIcon(tester, NotificationCategory.dailyPractices),
        Icons.toggle_on,
      );
      expect(
        _toggleIcon(tester, NotificationCategory.newArticles),
        Icons.toggle_on,
      );
      expect(
        _toggleIcon(tester, NotificationCategory.system),
        Icons.toggle_off,
      );
    });

    testWidgets('never-changed settings (null) are all on', (tester) async {
      await open(
        tester,
        profileEnv({
          getProfile: FakeResponse(200, {
            'profile': profileJson(notifications: null),
          }),
        }),
      );

      for (final category in NotificationCategory.values) {
        expect(_toggleIcon(tester, category), Icons.toggle_on);
      }
    });

    testWidgets('a tap saves just that category', (tester) async {
      final env = profileEnv({
        patchNotifications: _settings({'system_enabled': true}),
      });
      await open(tester, env);

      await tapAndSettle(
        tester,
        find.byKey(NotificationsScreen.toggleKey(NotificationCategory.system)),
      );

      expect(lastBody(env, patchNotifications), {'system_enabled': true});
      expect(_toggleIcon(tester, NotificationCategory.system), Icons.toggle_on);
    });

    testWidgets('a failed save flips the switch back with a message', (
      tester,
    ) async {
      final env = profileEnv();
      await open(tester, env);
      env.backend.offline = true;

      await tapAndSettle(
        tester,
        find.byKey(
          NotificationsScreen.toggleKey(NotificationCategory.newArticles),
        ),
      );

      expect(
        _toggleIcon(tester, NotificationCategory.newArticles),
        Icons.toggle_on,
      );
      expect(find.text(AuthErrorText.network), findsOneWidget);
    });

    testWidgets('offline load: a message and a working retry', (tester) async {
      final env = profileEnv();
      final container = await pumpApp(tester, env);
      env.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.profileNotifications);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
      expect(find.text(AuthErrorText.network), findsOneWidget);

      env.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));

      expect(find.byType(ErrorStateWidget), findsNothing);
      expect(find.text('Ежедневные практики'), findsOneWidget);
    });
  });

  group('642:3358 / 642:3400 — legal documents', () {
    testWidgets('lists the documents and opens one by slug', (tester) async {
      final env = profileEnv({
        legalList: _documents,
        legalDocument('license'): _license,
      });
      final container = await openProfile(
        tester,
        env,
        location: AppRoutes.profileLegal,
      );

      for (final title in [
        'Политика конфиденциальности',
        'Условия использования',
        'Лицензионное соглашение',
      ]) {
        expect(find.widgetWithText(ProfileMenuTile, title), findsOneWidget);
      }

      await tapAndSettle(
        tester,
        find.widgetWithText(ProfileMenuTile, 'Лицензионное соглашение'),
      );

      expect(currentPath(container), '/profile/legal/license');
      expect(env.backend.requestsTo(legalDocument('license')), hasLength(1));
      expect(find.byType(Html), findsOneWidget);
      expect(find.textContaining('Первый абзац.'), findsOneWidget);
      expect(find.textContaining('Пункт списка'), findsOneWidget);
      expect(find.textContaining('Нумерованный пункт'), findsOneWidget);

      await tapAndSettle(tester, find.byTooltip('Back'));
      expect(currentPath(container), AppRoutes.profileLegal);
    });

    testWidgets('an unknown slug: "Документ не найден"', (tester) async {
      await openProfile(
        tester,
        profileEnv(),
        location: AppRoutes.profileLegalDocument('gone'),
      );

      expect(find.text(ProfileText.documentNotFound), findsOneWidget);
    });

    testWidgets('offline list: a message and a working retry', (tester) async {
      final env = profileEnv({legalList: _documents});
      final container = await pumpApp(tester, env);
      env.backend.offline = true;
      container.read(appRouterProvider).go(AppRoutes.profileLegal);
      await tester.pumpAndSettle();

      expect(find.text(AuthErrorText.network), findsOneWidget);

      env.backend.offline = false;
      await tapAndSettle(tester, find.text('Повторить'));

      expect(
        find.widgetWithText(ProfileMenuTile, 'Условия использования'),
        findsOneWidget,
      );
    });

    testWidgets('no documents yet: an empty state', (tester) async {
      await openProfile(
        tester,
        profileEnv({
          legalList: const FakeResponse(200, {'data': <Object>[]}),
        }),
        location: AppRoutes.profileLegal,
      );

      expect(find.text(LegalDocumentsScreen.emptyMessage), findsOneWidget);
    });
  });
}
