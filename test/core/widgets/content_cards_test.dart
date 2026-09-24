import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

import 'pump_themed.dart';

const _coverKey = Key('cover');
const _cover = ColoredBox(key: _coverKey, color: AppColors.blueTint);

/// Content width of the cards in Figma (393 − 2 × 16).
const _width = 361.0;

void _expectTitle(WidgetTester tester, String title) {
  final style = tester.widget<Text>(find.text(title)).style;
  final titleLarge = Theme.of(tester.element(find.text(title)))
      .textTheme
      .titleLarge;
  expect(style?.fontSize, titleLarge?.fontSize);
  expect(style?.fontWeight, titleLarge?.fontWeight);
}

void _expectActionLink(WidgetTester tester, String label) {
  expect(find.text(label), findsOneWidget);
  final arrow = tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded));
  expect(arrow.size, 16);
  expect(
    tester.getCenter(find.byIcon(Icons.arrow_forward_rounded)).dx,
    greaterThan(tester.getCenter(find.text(label)).dx),
  );
}

void _expectDescription(WidgetTester tester, String text) {
  final style = tester.widget<Text>(find.text(text)).style;
  expect(style?.fontSize, 12);
  expect(style?.fontWeight, FontWeight.w400);
  expect(style?.color, AppColors.softBlack);
}

/// Checks the 0.5px basicBlack top divider and the spacing/md gaps: from
/// the line to [top] and from [bottom] to the card's bottom edge.
void _expectTopDivider(
  WidgetTester tester, {
  required Type card,
  required Finder top,
  required Finder bottom,
}) {
  final cardRect = tester.getRect(find.byType(card));
  final dividerFinder = find.descendant(
    of: find.byType(card),
    matching: find.byType(Divider),
  );
  expect(dividerFinder, findsOneWidget);
  final divider = tester.widget<Divider>(dividerFinder);
  expect(divider.thickness, 0.5);
  expect(divider.color, AppColors.basicBlack);

  final line = tester.getRect(dividerFinder);
  expect(line.top, cardRect.top);
  expect(line.width, cardRect.width);
  expect(tester.getTopLeft(top).dy - line.bottom, AppSpacing.md);
  expect(cardRect.bottom - tester.getBottomLeft(bottom).dy, AppSpacing.md);
}

Future<void> _expectTapAnywhere(
  WidgetTester tester,
  Widget Function(VoidCallback) build,
  List<Finder> targets,
) async {
  var taps = 0;
  await pumpThemed(tester, build(() => taps++), width: _width);
  for (final target in targets) {
    await tester.tap(target);
  }
  expect(taps, targets.length);
}

void main() {
  group('MeditationCard', () {
    MeditationCard card({VoidCallback? onTap}) => MeditationCard(
      title: 'Visioning – образ будущего',
      cover: _cover,
      duration: '25 минут',
      description: 'Описание медитации',
      actionLabel: 'Начать',
      onTap: onTap,
    );

    testWidgets('title, duration, description and action link', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectTitle(tester, 'Visioning – образ будущего');
      expect(find.text('25 минут'), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.watch_later)).size, 16);
      _expectDescription(tester, 'Описание медитации');
      _expectActionLink(tester, 'Начать');
    });

    testWidgets('138px cover on the left with a centered play icon', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);

      final cover = tester.getRect(find.byKey(_coverKey));
      expect(cover.size, const Size.square(MeditationCard.coverSize));
      final play = find.byIcon(Icons.play_arrow_rounded);
      expect(tester.getCenter(play), cover.center);
      expect(tester.widget<Icon>(play).size, 24);
      expect(tester.widget<Icon>(play).color, AppColors.background);
      expect(
        tester.getTopLeft(find.byIcon(Icons.watch_later)).dx,
        greaterThan(cover.right),
      );
    });

    testWidgets('has no divider', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('tap anywhere calls onTap', (tester) async {
      await _expectTapAnywhere(tester, (onTap) => card(onTap: onTap), [
        find.text('Начать'),
        find.byKey(_coverKey),
        find.text('Visioning – образ будущего'),
      ]);
    });
  });

  group('ArticleListCard', () {
    ArticleListCard card({VoidCallback? onTap}) => ArticleListCard(
      title: 'Стресс, неудовлетворенность, одиночество',
      cover: _cover,
      date: 'Март, 2025',
      description: 'Откуда они берутся',
      actionLabel: 'Читать',
      onTap: onTap,
    );

    testWidgets('title, date, description and action link', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectTitle(tester, 'Стресс, неудовлетворенность, одиночество');
      expect(find.text('Март, 2025'), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.calendar_month)).size, 16);
      _expectDescription(tester, 'Откуда они берутся');
      _expectActionLink(tester, 'Читать');
    });

    testWidgets('138x110 cover on the right, without a play icon', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);

      final cover = tester.getRect(find.byKey(_coverKey));
      expect(cover.size, ArticleListCard.coverSize);
      expect(
        tester.getTopRight(find.text('Март, 2025')).dx,
        lessThan(cover.left),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('top divider with spacing/md gaps', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectTopDivider(
        tester,
        card: ArticleListCard,
        top: find.text('Стресс, неудовлетворенность, одиночество'),
        bottom: find.byKey(_coverKey),
      );
    });

    testWidgets('tap anywhere calls onTap', (tester) async {
      await _expectTapAnywhere(tester, (onTap) => card(onTap: onTap), [
        find.text('Читать'),
        find.byKey(_coverKey),
      ]);
    });
  });

  group('ToolListCard', () {
    ToolListCard card({VoidCallback? onTap}) => ToolListCard(
      title: 'Выражение гнева',
      description: 'Описание инструмента',
      tag: 'выражение',
      actionLabel: 'Читать',
      onTap: onTap,
    );

    testWidgets('title, description with a tag badge and action link', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);

      _expectTitle(tester, 'Выражение гнева');
      _expectDescription(tester, 'Описание инструмента');
      _expectActionLink(tester, 'Читать');
      expect(
        tester.getTopLeft(find.text('выражение')).dx,
        greaterThan(tester.getTopRight(find.text('Описание инструмента')).dx),
      );
    });

    testWidgets('tag is a tinted AppBadge without an arrow', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      final badge = tester.widget<AppBadge>(find.byType(AppBadge));
      expect(badge.label, 'выражение');
      expect(badge.variant, AppBadgeVariant.tinted);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('top divider with spacing/md gaps', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectTopDivider(
        tester,
        card: ToolListCard,
        top: find.text('Выражение гнева'),
        bottom: find.byIcon(Icons.arrow_forward_rounded),
      );
    });

    testWidgets('has no cover or meta icons', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      expect(find.byType(Icon), findsOneWidget); // the action arrow
    });

    testWidgets('tap anywhere calls onTap', (tester) async {
      await _expectTapAnywhere(tester, (onTap) => card(onTap: onTap), [
        find.text('Читать'),
        find.text('выражение'),
      ]);
    });
  });

  group('ThemeListCard', () {
    ThemeListCard card({bool isExpanded = false, VoidCallback? onTap}) =>
        ThemeListCard(
          title: 'Границы',
          subtitle: 'сложности в отношениях / границы',
          cover: _cover,
          body: 'Первый абзац.\nВторой абзац.',
          actionLabel: 'Читать',
          isExpanded: isExpanded,
          onTap: onTap,
        );

    testWidgets('folded: title, + icon and subtitle only', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectTitle(tester, 'Границы');
      final subtitle = tester.widget<Text>(
        find.text('сложности в отношениях / границы'),
      );
      expect(subtitle.style?.fontSize, 12);
      expect(subtitle.style?.color, AppColors.basicBlack);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.add)).size,
        ThemeListCard.expandIconSize,
      );
      expect(find.byIcon(Icons.remove), findsNothing);
      expect(find.byKey(_coverKey), findsNothing);
      expect(find.text('Читать'), findsNothing);
    });

    testWidgets('expanded: – icon, 130px cover, body and action link', (
      tester,
    ) async {
      await pumpThemed(tester, card(isExpanded: true), width: _width);

      expect(find.byIcon(Icons.add), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.remove)).size,
        ThemeListCard.collapseIconSize,
      );
      expect(
        tester.getSize(find.byKey(_coverKey)),
        const Size.square(ThemeListCard.coverSize),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      _expectDescription(tester, 'Первый абзац.\nВторой абзац.');
      _expectActionLink(tester, 'Читать');
      expect(
        tester.getTopLeft(find.byKey(_coverKey)).dy,
        greaterThan(
          tester
              .getBottomLeft(find.text('сложности в отношениях / границы'))
              .dy,
        ),
      );
    });

    testWidgets('header icon sits right of the title', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      expect(
        tester.getTopRight(find.byIcon(Icons.add)).dx,
        closeTo(_width, 0.01),
      );
      expect(
        tester.getTopLeft(find.byIcon(Icons.add)).dy -
            tester.getTopLeft(find.text('Границы')).dy,
        12,
      );
    });

    testWidgets('top divider with spacing/md gaps in both states', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);
      _expectTopDivider(
        tester,
        card: ThemeListCard,
        top: find.text('Границы'),
        bottom: find.text('сложности в отношениях / границы'),
      );

      await pumpThemed(tester, card(isExpanded: true), width: _width);
      _expectTopDivider(
        tester,
        card: ThemeListCard,
        top: find.text('Границы'),
        bottom: find.byKey(_coverKey),
      );
    });

    testWidgets('tap calls onTap in both states', (tester) async {
      await _expectTapAnywhere(tester, (onTap) => card(onTap: onTap), [
        find.text('Границы'),
      ]);
      await _expectTapAnywhere(
        tester,
        (onTap) => card(isExpanded: true, onTap: onTap),
        [find.byKey(_coverKey), find.text('Читать')],
      );
    });
  });
}
