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

/// The cover is an [AppGrid.span] of 3 columns, square.
void _expectGridCover(Size size) {
  final side = AppGrid.span(_width, 3);
  expect(size.width, closeTo(side, 0.01));
  expect(size.height, closeTo(side, 0.01));
}

void _expectDescription(WidgetTester tester, String text) {
  final style = tester.widget<Text>(find.text(text)).style;
  expect(style?.fontSize, 12);
  expect(style?.fontWeight, FontWeight.w400);
  expect(style?.color, AppColors.softBlack);
}

/// A list card draws no divider and no padding of its own (the
/// [ContentCardList] holds both): [top] starts at the card's top edge and
/// [bottom] ends at its bottom edge.
void _expectFlush(
  WidgetTester tester, {
  required Type card,
  required Finder top,
  required Finder bottom,
}) {
  final cardRect = tester.getRect(find.byType(card));
  expect(
    find.descendant(of: find.byType(card), matching: find.byType(Divider)),
    findsNothing,
  );
  expect(tester.getTopLeft(top).dy, cardRect.top);
  expect(tester.getTopLeft(top).dx, cardRect.left);
  expect(tester.getBottomLeft(bottom).dy, cardRect.bottom);
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

    testWidgets('3-column cover on the left with a centered play icon', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);

      final cover = tester.getRect(find.byKey(_coverKey));
      _expectGridCover(cover.size);
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

    testWidgets('3-column square cover on the right, without a play icon', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);

      final cover = tester.getRect(find.byKey(_coverKey));
      _expectGridCover(cover.size);
      expect(
        tester.getTopRight(find.text('Март, 2025')).dx,
        lessThan(cover.left),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('no divider or padding of its own', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectFlush(
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

    testWidgets('no badge by default', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      expect(find.byType(AppBadge), findsNothing);
    });

    testWidgets('a badge sits after the date, left of the cover', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const ArticleListCard(
          title: 'Стресс',
          cover: _cover,
          date: 'Сентябрь, 2025',
          description: 'Откуда они берутся',
          actionLabel: 'Читать',
          badge: 'новое',
        ),
        width: _width,
      );

      final badge = find.widgetWithText(AppBadge, 'новое');
      expect(badge, findsOneWidget);
      expect(tester.widget<AppBadge>(badge).variant, AppBadgeVariant.tinted);
      expect(
        tester.getTopLeft(badge).dx,
        greaterThan(tester.getTopRight(find.text('Сентябрь, 2025')).dx),
      );
      expect(
        tester.getTopRight(badge).dx,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(_coverKey)).dx),
      );
      expect(tester.takeException(), isNull);
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

    testWidgets('no divider or padding of its own', (tester) async {
      await pumpThemed(tester, card(), width: _width);

      _expectFlush(
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

    testWidgets('no cover: the description starts at the left edge', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);

      final cardRect = tester.getRect(find.byType(ToolListCard));
      expect(find.byType(ClipRect), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(
        tester.getTopLeft(find.text('Описание инструмента')).dx,
        cardRect.left,
      );
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
        find.text(bindShortWords('сложности в отношениях / границы')),
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

    testWidgets('expanded: – icon, 3-column cover, body and action link', (
      tester,
    ) async {
      await pumpThemed(tester, card(isExpanded: true), width: _width);

      expect(find.byIcon(Icons.add), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.remove)).size,
        ThemeListCard.collapseIconSize,
      );
      _expectGridCover(tester.getSize(find.byKey(_coverKey)));
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      _expectDescription(tester, 'Первый абзац.\nВторой абзац.');
      _expectActionLink(tester, 'Читать');
      expect(
        tester.getTopLeft(find.byKey(_coverKey)).dy,
        greaterThan(
          tester
              .getBottomLeft(
                find.text(bindShortWords('сложности в отношениях / границы')),
              )
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

    testWidgets('no divider or padding of its own, in both states', (
      tester,
    ) async {
      await pumpThemed(tester, card(), width: _width);
      _expectFlush(
        tester,
        card: ThemeListCard,
        top: find.text('Границы'),
        bottom: find.text(bindShortWords('сложности в отношениях / границы')),
      );

      await pumpThemed(tester, card(isExpanded: true), width: _width);
      _expectFlush(
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

  group('locked content', () {
    final cards = <String, Widget Function({required bool isLocked})>{
      'MeditationCard': ({required isLocked}) => MeditationCard(
        title: 'Утренняя медитация',
        cover: _cover,
        duration: '25 минут',
        description: 'Описание',
        actionLabel: 'Начать',
        isLocked: isLocked,
      ),
      'ArticleListCard': ({required isLocked}) => ArticleListCard(
        title: 'Утренняя медитация',
        cover: _cover,
        date: 'Март, 2025',
        description: 'Описание',
        actionLabel: 'Читать',
        isLocked: isLocked,
      ),
    };

    for (final MapEntry(key: name, value: build) in cards.entries) {
      testWidgets('$name: a lock after the title only when locked', (
        tester,
      ) async {
        await pumpThemed(tester, build(isLocked: false), width: _width);
        expect(find.byType(LockedMark), findsNothing);

        await pumpThemed(tester, build(isLocked: true), width: _width);
        expect(find.byType(LockedMark), findsOneWidget);
        expect(
          tester.getCenter(find.byType(LockedMark)).dx,
          greaterThan(tester.getCenter(find.text('Утренняя медитация')).dx),
        );
        expect(
          tester.widget<Icon>(find.byIcon(Icons.lock)).semanticLabel,
          LockedMark.semanticLabel,
        );
      });
    }
  });

  testWidgets('ToolListCard: no badge without a tag', (tester) async {
    await pumpThemed(
      tester,
      const ToolListCard(
        title: 'Выражение гнева',
        description: 'Описание',
        tag: null,
        actionLabel: 'Читать',
      ),
      width: _width,
    );

    expect(find.byType(AppBadge), findsNothing);
  });

  testWidgets('ThemeListCard: onActionTap takes the action link, onTap the '
      'rest of the card', (tester) async {
    var cardTaps = 0;
    var actionTaps = 0;
    await pumpThemed(
      tester,
      ThemeListCard(
        title: 'Границы',
        subtitle: 'Подзаголовок',
        cover: _cover,
        body: 'Текст',
        actionLabel: 'Читать',
        isExpanded: true,
        onTap: () => cardTaps++,
        onActionTap: () => actionTaps++,
      ),
      width: _width,
    );

    await tester.tap(find.text('Читать'));
    expect((cardTaps, actionTaps), (0, 1));

    await tester.tap(find.text('Границы'));
    expect((cardTaps, actionTaps), (1, 1));
  });

  group('AppGrid layout', () {
    // The Figma width and a narrow phone (360 − 2 × 16).
    const widths = [_width, 328.0];
    const tolerance = 0.01;
    const arrow = Icons.arrow_forward_rounded;

    Rect cardRect(WidgetTester tester, Type card) =>
        tester.getRect(find.byType(card));

    for (final width in widths) {
      group('at ${width}px', () {
        final cover = AppGrid.span(width, 3);
        final boundary = AppGrid.boundary(width, 4);

        testWidgets('MeditationCard: 3-column cover, then a 1-column gap, '
            'details span 4 columns to the right edge', (tester) async {
          await pumpThemed(
            tester,
            const MeditationCard(
              title: 'Visioning – образ будущего',
              cover: _cover,
              duration: '25 минут',
              description: 'Описание медитации',
              actionLabel: 'Начать',
            ),
            width: width,
          );
          final card = cardRect(tester, MeditationCard);

          final coverRect = tester.getRect(find.byKey(_coverKey));
          expect(coverRect.left, closeTo(card.left, tolerance));
          expect(coverRect.width, closeTo(cover, tolerance));
          expect(coverRect.height, closeTo(cover, tolerance));
          for (final start in [
            find.byIcon(Icons.watch_later),
            find.text('Описание медитации'),
            find.text('Начать'),
          ]) {
            expect(
              tester.getTopLeft(start).dx - card.left,
              closeTo(boundary, tolerance),
            );
          }
          expect(
            card.right - boundary - card.left,
            closeTo(AppGrid.span(width, 4), tolerance),
          );
          expect(
            tester.getTopRight(find.byIcon(arrow)).dx,
            closeTo(card.right, tolerance),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('ThemeListCard expanded: 3-column cover, then a '
            '1-column gap, details span 4 columns to the right edge', (
          tester,
        ) async {
          await pumpThemed(
            tester,
            const ThemeListCard(
              title: 'Границы',
              subtitle: 'сложности в отношениях / границы',
              cover: _cover,
              body: 'Первый абзац.\nВторой абзац.',
              actionLabel: 'Читать',
              isExpanded: true,
            ),
            width: width,
          );
          final card = cardRect(tester, ThemeListCard);

          final coverRect = tester.getRect(find.byKey(_coverKey));
          expect(coverRect.left, closeTo(card.left, tolerance));
          expect(coverRect.width, closeTo(cover, tolerance));
          expect(coverRect.height, closeTo(cover, tolerance));
          for (final start in [
            find.text('Первый абзац.\nВторой абзац.'),
            find.text('Читать'),
          ]) {
            expect(
              tester.getTopLeft(start).dx - card.left,
              closeTo(boundary, tolerance),
            );
          }
          expect(
            tester.getTopRight(find.byIcon(arrow)).dx,
            closeTo(card.right, tolerance),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('ArticleListCard: the link arrow and the badge end at '
            'the 4-column boundary, 3-column square cover at the right edge', (
          tester,
        ) async {
          await pumpThemed(
            tester,
            const ArticleListCard(
              title: 'Стресс',
              cover: _cover,
              date: 'Март, 2025',
              description: 'Откуда они берутся и как с ними обходиться',
              actionLabel: 'Читать',
              badge: 'новое',
            ),
            width: width,
          );
          final card = cardRect(tester, ArticleListCard);

          expect(
            tester.getTopRight(find.byIcon(arrow)).dx - card.left,
            closeTo(boundary, tolerance),
          );
          expect(
            tester.getTopRight(find.byType(AppBadge)).dx - card.left,
            closeTo(boundary, tolerance),
          );
          expect(
            tester
                    .getTopRight(
                      find.text(
                        bindShortWords(
                          'Откуда они берутся и как с ними обходиться',
                        ),
                      ),
                    )
                    .dx -
                card.left,
            lessThanOrEqualTo(boundary + tolerance),
          );
          final coverRect = tester.getRect(find.byKey(_coverKey));
          expect(coverRect.right, closeTo(card.right, tolerance));
          expect(coverRect.width, closeTo(cover, tolerance));
          expect(coverRect.height, closeTo(cover, tolerance));
          expect(tester.takeException(), isNull);
        });

        testWidgets('ToolListCard: the link arrow ends at the 4-column '
            'boundary', (tester) async {
          await pumpThemed(
            tester,
            const ToolListCard(
              title: 'Выражение гнева',
              description: 'Описание инструмента',
              tag: 'выражение',
              actionLabel: 'Читать',
            ),
            width: width,
          );
          final card = cardRect(tester, ToolListCard);

          expect(
            tester.getTopLeft(find.text('Читать')).dx,
            closeTo(card.left, tolerance),
          );
          expect(
            tester.getTopRight(find.byIcon(arrow)).dx - card.left,
            closeTo(boundary, tolerance),
          );
          expect(tester.takeException(), isNull);
        });
      });
    }
  });

  group('ContentCardList', () {
    /// Screen width in Figma: the list runs edge to edge.
    const screenWidth = 393.0;
    const cardHeight = 50.0;
    Widget card(String key) => SizedBox(key: ValueKey(key), height: cardHeight);

    testWidgets('dividers only between the cards, 16px on both sides', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        ContentCardList(children: [card('a'), card('b'), card('c')]),
        width: screenWidth,
      );

      final list = tester.getRect(find.byType(ContentCardList));
      final cards = [
        for (final key in ['a', 'b', 'c'])
          tester.getRect(find.byKey(ValueKey(key))),
      ];
      final dividers = find.byType(ContentDivider);
      expect(dividers, findsNWidgets(2));
      final lines = [
        for (var i = 0; i < 2; i++) tester.getRect(dividers.at(i)),
      ];

      // spacing/xl above the first card and below the last, no line there.
      expect(cards.first.top - list.top, AppSpacing.xl);
      expect(list.bottom - cards.last.bottom, AppSpacing.xl);
      for (var i = 0; i < lines.length; i++) {
        expect(lines[i].top - cards[i].bottom, AppSpacing.md);
        expect(cards[i + 1].top - lines[i].bottom, AppSpacing.md);
        // Full width line, inset cards.
        expect(lines[i].left, 0);
        expect(lines[i].width, screenWidth);
      }
      for (final rect in cards) {
        expect(rect.left, AppGrid.margin);
        expect(rect.right, screenWidth - AppGrid.margin);
      }

      final divider = tester.widget<Divider>(find.byType(Divider).first);
      expect(divider.thickness, ContentDivider.thickness);
      expect(divider.color, AppColors.basicBlack);
    });

    testWidgets('a single card: no divider at all', (tester) async {
      await pumpThemed(
        tester,
        ContentCardList(children: [card('a')]),
        width: screenWidth,
      );

      expect(find.byType(ContentDivider), findsNothing);
      expect(
        tester.getSize(find.byType(ContentCardList)).height,
        AppSpacing.xl + cardHeight + AppSpacing.xl,
      );
    });

    testWidgets('top and bottom are configurable', (tester) async {
      await pumpThemed(
        tester,
        ContentCardList(top: AppSpacing.lg, bottom: 0, children: [card('a')]),
        width: screenWidth,
      );

      final list = tester.getRect(find.byType(ContentCardList));
      final rect = tester.getRect(find.byKey(const ValueKey('a')));
      expect(rect.top - list.top, AppSpacing.lg);
      expect(rect.bottom, list.bottom);
    });

    testWidgets('no cards: takes no space', (tester) async {
      await pumpThemed(
        tester,
        const ContentCardList(children: []),
        width: screenWidth,
      );

      expect(tester.getSize(find.byType(ContentCardList)).height, 0);
    });
  });

  group(
    'ContentCardList with real cards: 16px from the line to the content',
    () {
      /// Screen width in Figma: the list runs edge to edge.
      const screenWidth = 393.0;

      /// Two cards titled `Первая` / `Вторая` and the finders of the elements
      /// that can end a card (the lowest one is its visual bottom). The
      /// action link is its label and the 16px arrow, the taller of the two.
      final link = find.byIcon(Icons.arrow_forward_rounded);
      final cases = <String, (Widget Function(String title), List<Finder>)>{
        'MeditationCard': (
          (title) => MeditationCard(
            title: title,
            cover: const ColoredBox(color: AppColors.blueTint),
            duration: '25 минут',
            description: 'Описание',
            actionLabel: 'Начать',
          ),
          [find.text('Начать'), link, find.byType(ColoredBox)],
        ),
        'ArticleListCard': (
          (title) => ArticleListCard(
            title: title,
            cover: const ColoredBox(color: AppColors.blueTint),
            date: 'Март, 2025',
            description: 'Описание',
            actionLabel: 'Читать',
          ),
          [find.text('Читать'), link, find.byType(ColoredBox)],
        ),
        'ToolListCard': (
          (title) => ToolListCard(
            title: title,
            description: 'Описание',
            tag: 'выражение',
            actionLabel: 'Читать',
          ),
          [find.text('Читать'), link],
        ),
        'ThemeListCard folded': (
          (title) => ThemeListCard(
            title: title,
            subtitle: 'Подзаголовок',
            cover: const ColoredBox(color: AppColors.blueTint),
            body: 'Текст',
            actionLabel: 'Читать',
          ),
          [find.text('Подзаголовок')],
        ),
        'ThemeListCard expanded': (
          (title) => ThemeListCard(
            title: title,
            subtitle: 'Подзаголовок',
            cover: const ColoredBox(color: AppColors.blueTint),
            body: 'Текст',
            actionLabel: 'Читать',
            isExpanded: true,
          ),
          [find.text('Читать'), link, find.byType(ColoredBox)],
        ),
      };

      for (final MapEntry(key: name, value: (build, enders)) in cases.entries) {
        testWidgets('$name: last element → line = line → next title = 16px', (
          tester,
        ) async {
          await pumpThemed(
            tester,
            ContentCardList(children: [build('Первая'), build('Вторая')]),
            width: screenWidth,
          );

          final first = find.byType(ContentCardList).first;
          final firstCard = find
              .descendant(
                of: first,
                matching: find.byWidgetPredicate(
                  (w) => w.runtimeType == build('').runtimeType,
                ),
              )
              .first;
          final contentBottom = [
            for (final finder in enders)
              for (final element
                  in find
                      .descendant(of: firstCard, matching: finder)
                      .evaluate())
                tester
                    .getRect(find.byElementPredicate((e) => e == element))
                    .bottom,
          ].reduce((a, b) => a > b ? a : b);
          final line = tester.getRect(find.byType(ContentDivider));
          final nextTitleTop = tester.getTopLeft(find.text('Вторая')).dy;

          final below = line.top - contentBottom;
          final above = nextTitleTop - line.bottom;
          final gaps = 'content → line $below, line → title $above';
          // The cover is a fractional AppGrid span: compare with a tolerance.
          expect(below, closeTo(AppSpacing.md, 1e-9), reason: gaps);
          expect(above, closeTo(AppSpacing.md, 1e-9), reason: gaps);
        });
      }
    },
  );

  group('card layout: 24px title → content, 16px inside the content', () {
    const short = 'Коротко';
    final long = List.filled(12, 'Длинное описание карточки.').join(' ');

    /// The row that holds [text] (the meta row or the action link).
    Rect rowOf(WidgetTester tester, String text) => tester.getRect(
      find.ancestor(of: find.text(text), matching: find.byType(Row)).first,
    );
    double titleBottom(WidgetTester tester, String title) =>
        tester.getBottomLeft(find.text(title)).dy;
    Rect coverOf(WidgetTester tester) => tester.getRect(find.byKey(_coverKey));
    Rect cardOf(WidgetTester tester, Type type) =>
        tester.getRect(find.byType(type));

    /// [rects] top to bottom, each [_contentGap] below the previous one.
    void expectContentGaps(List<Rect> rects) {
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].top - rects[i - 1].bottom, AppSpacing.md);
      }
    }

    group('MeditationCard', () {
      Widget build(String description) => MeditationCard(
        title: 'Медитация',
        cover: _cover,
        duration: '25 минут',
        description: description,
        actionLabel: 'Начать',
      );

      testWidgets('24px title → content, 16px between the duration, the '
          'description and the link, text top = cover top', (tester) async {
        await pumpThemed(tester, build(short), width: _width);

        final meta = rowOf(tester, '25 минут');
        final link = rowOf(tester, 'Начать');
        final description = tester.getRect(find.text(short));
        expect(meta.top - titleBottom(tester, 'Медитация'), AppSpacing.lg);
        expect(
          coverOf(tester).top - titleBottom(tester, 'Медитация'),
          AppSpacing.lg,
        );
        expectContentGaps([meta, description, link]);
        expect(meta.top, coverOf(tester).top);
      });

      testWidgets('bottom: the cover under a short text, the link under a '
          'long one', (tester) async {
        await pumpThemed(tester, build(short), width: _width);
        expect(
          rowOf(tester, 'Начать').bottom,
          lessThan(coverOf(tester).bottom),
        );
        expect(cardOf(tester, MeditationCard).bottom, coverOf(tester).bottom);

        await pumpThemed(tester, build(long), width: _width);
        expect(
          rowOf(tester, 'Начать').bottom,
          greaterThan(coverOf(tester).bottom),
        );
        expect(
          cardOf(tester, MeditationCard).bottom,
          rowOf(tester, 'Начать').bottom,
        );
      });
    });

    group('ArticleListCard', () {
      Widget build(String description) => ArticleListCard(
        title: 'Статья',
        cover: _cover,
        date: 'Март, 2025',
        description: description,
        actionLabel: 'Читать',
      );

      testWidgets('24px title → content, 16px between the date, the '
          'description and the link, text top = cover top', (tester) async {
        await pumpThemed(tester, build(short), width: _width);

        final meta = rowOf(tester, 'Март, 2025');
        final link = rowOf(tester, 'Читать');
        final description = tester.getRect(find.text(short));
        expect(meta.top - titleBottom(tester, 'Статья'), AppSpacing.lg);
        expect(
          coverOf(tester).top - titleBottom(tester, 'Статья'),
          AppSpacing.lg,
        );
        expectContentGaps([meta, description, link]);
        expect(meta.top, coverOf(tester).top);
      });

      testWidgets('bottom: the cover under a short text, the link under a '
          'long one', (tester) async {
        await pumpThemed(tester, build(short), width: _width);
        expect(
          rowOf(tester, 'Читать').bottom,
          lessThan(coverOf(tester).bottom),
        );
        expect(cardOf(tester, ArticleListCard).bottom, coverOf(tester).bottom);

        await pumpThemed(tester, build(long), width: _width);
        expect(
          rowOf(tester, 'Читать').bottom,
          greaterThan(coverOf(tester).bottom),
        );
        expect(
          cardOf(tester, ArticleListCard).bottom,
          rowOf(tester, 'Читать').bottom,
        );
      });
    });

    group('ToolListCard', () {
      Widget build(String description) => ToolListCard(
        title: 'Инструмент',
        description: description,
        tag: 'выражение',
        actionLabel: 'Читать',
      );

      for (final (name, text) in [('short', short), ('long', long)]) {
        testWidgets('$name text: 24px title → content, 16px description '
            'row → link, the link is the bottom', (tester) async {
          await pumpThemed(tester, build(text), width: _width);

          final description = tester.getRect(find.text(text));
          final badge = tester.getRect(find.byType(AppBadge));
          final link = rowOf(tester, 'Читать');
          expect(
            description.top - titleBottom(tester, 'Инструмент'),
            AppSpacing.lg,
          );
          // The badge sits on the description's first line.
          expect(badge.top, description.top);
          // The description row ends with the lower of the text and the
          // badge (a one-line text is shorter than the badge).
          final row = description.expandToInclude(badge);
          expectContentGaps([row, link]);
          expect(cardOf(tester, ToolListCard).bottom, link.bottom);
        });
      }

      testWidgets('no cover', (tester) async {
        await pumpThemed(tester, build(short), width: _width);

        expect(find.byType(ClipRect), findsNothing);
        expect(find.byType(Image), findsNothing);
      });
    });

    group('ThemeListCard expanded', () {
      Widget build(String body) => ThemeListCard(
        title: 'Тема',
        subtitle: 'Подзаголовок',
        cover: _cover,
        body: body,
        actionLabel: 'Читать',
        isExpanded: true,
      );

      testWidgets('24px header → content, 16px body → link, text top = '
          'cover top', (tester) async {
        await pumpThemed(tester, build(short), width: _width);

        final header = tester.getBottomLeft(find.text('Подзаголовок')).dy;
        final body = tester.getRect(find.text(short));
        expect(body.top - header, AppSpacing.lg);
        expect(coverOf(tester).top - header, AppSpacing.lg);
        expectContentGaps([body, rowOf(tester, 'Читать')]);
        expect(body.top, coverOf(tester).top);
      });

      testWidgets('bottom: the cover under a short text, the link under a '
          'long one', (tester) async {
        await pumpThemed(tester, build(short), width: _width);
        expect(cardOf(tester, ThemeListCard).bottom, coverOf(tester).bottom);

        await pumpThemed(tester, build(long), width: _width);
        expect(
          cardOf(tester, ThemeListCard).bottom,
          rowOf(tester, 'Читать').bottom,
        );
      });
    });
  });
}
