import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/home/index.dart';

import '../../core/widgets/pump_themed.dart';

/// Screen width in Figma.
const _screenWidth = 393.0;

/// Content width of a card in Figma node 1:957: 8 × 38 + 7 × 8.
const _figmaContent = 360.0;

void main() {
  group('AppGrid', () {
    test('Figma 1:957 sizes at 360px: 38px columns, 8px gutters', () {
      expect(AppGrid.column(_figmaContent), closeTo(38, 1e-9));
      expect(AppGrid.gutter(_figmaContent), closeTo(8, 1e-9));
      expect(AppGrid.boundary(_figmaContent, 5), closeTo(230, 1e-9));
      expect(AppGrid.span(_figmaContent, 3), closeTo(130, 1e-9));
      expect(AppGrid.span(_figmaContent, 8), closeTo(_figmaContent, 1e-9));
    });

    test('span and boundary are columns plus gutters', () {
      const width = 361.0;
      for (var n = 1; n <= AppGrid.columns; n++) {
        expect(
          AppGrid.span(width, n),
          closeTo(
            n * AppGrid.column(width) + (n - 1) * AppGrid.gutter(width),
            1e-9,
          ),
        );
        expect(
          AppGrid.boundary(width, n),
          closeTo(AppGrid.span(width, n) + AppGrid.gutter(width), 1e-9),
        );
      }
    });
  });

  group('HomeFeaturedItem', () {
    Future<void> pump(
      WidgetTester tester, {
      required String actionLabel,
      double width = _screenWidth,
      String? subtitle,
      String description = 'Описание медитации',
    }) {
      return pumpThemed(
        tester,
        HomeFeaturedItem(
          title: 'Утренняя медитация',
          subtitle: subtitle,
          description: description,
          trailing: const HomeMetaLabel(
            icon: Icons.watch_later,
            text: '25 минут',
          ),
          actionLabel: actionLabel,
          onTap: () {},
        ),
        width: width,
      );
    }

    Rect descriptionRect(WidgetTester tester) => tester.getRect(
      find
          .ancestor(
            of: find.text('Описание медитации'),
            matching: find.byType(SizedBox),
          )
          .first,
    );

    testWidgets('Figma 1:957 at 360px of content: 230px description, 130px '
        'button', (tester) async {
      await pump(
        tester,
        actionLabel: 'Начать',
        width: _figmaContent + 2 * AppGrid.margin,
      );

      expect(descriptionRect(tester).width, closeTo(230, 0.01));
      expect(tester.getSize(find.byType(AppButton)).width, closeTo(130, 0.01));
    });

    testWidgets('description up to column 6, detail hugs the right edge', (
      tester,
    ) async {
      await pump(tester, actionLabel: 'Начать');
      const content = _screenWidth - 2 * AppGrid.margin;

      final description = descriptionRect(tester);
      expect(description.left, AppGrid.margin);
      expect(description.width, closeTo(content * 23 / 180 * 5, 0.01));

      final detail = tester.getRect(find.byType(HomeMetaLabel));
      expect(detail.right, closeTo(_screenWidth - AppGrid.margin, 0.01));
      // Its natural size: icon, gap and text, nothing more.
      expect(
        detail.width,
        closeTo(
          HomeMetaLabel.iconSize +
              AppSpacing.xs +
              tester.getSize(find.text('25 минут')).width,
          0.01,
        ),
      );
      expect(detail.left, greaterThan(description.right));
    });

    for (final label in ['Начать', 'Читать', 'Читать дальше и подробнее']) {
      testWidgets('button is 3 columns wide whatever the label: "$label"', (
        tester,
      ) async {
        await pump(tester, actionLabel: label);
        const content = _screenWidth - 2 * AppGrid.margin;

        final button = tester.getRect(find.byType(AppButton));
        expect(button.left, AppGrid.margin);
        expect(button.width, closeTo(content * 65 / 180, 0.01));
        expect(button.height, HomeFeaturedItem.buttonHeight);
      });
    }
    testWidgets('subtitle is 6 columns wide, as on the section cover', (
      tester,
    ) async {
      await pump(tester, actionLabel: 'Читать', subtitle: 'Я и мои границы');
      const content = _screenWidth - 2 * AppGrid.margin;

      final subtitle = find.text('Я$nbspи$nbspмои границы');
      expect(subtitle, findsOneWidget);
      expect(HomeFeaturedItem.subtitleColumns, 6);
      expect(
        tester
            .getSize(
              find
                  .ancestor(of: subtitle, matching: find.byType(SizedBox))
                  .first,
            )
            .width,
        closeTo(AppGrid.span(content, 6), 0.01),
      );
    });

    testWidgets('description ties one-letter words to the next one', (
      tester,
    ) async {
      await pump(
        tester,
        actionLabel: 'Читать',
        description: 'Работа с гневом и обидой',
      );

      expect(find.text('Работа с$nbspгневом и$nbspобидой'), findsOneWidget);
    });
  });

  group('HomeCoverImage', () {
    Future<void> pump(WidgetTester tester, HomeCoverImage image) =>
        tester.pumpWidget(
          MaterialApp(
            home: Center(child: SizedBox.square(dimension: 100, child: image)),
          ),
        );

    testWidgets('without a URL or a fallback: the placeholder', (tester) async {
      await pump(tester, const HomeCoverImage(url: null));

      expect(find.byType(HomeCoverPlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(
        tester.getSize(find.byType(HomeCoverPlaceholder)),
        const Size.square(100),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(HomeCoverPlaceholder),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        AppColors.blueTint,
      );
    });

    testWidgets('without a URL, with a fallback: the stock image', (
      tester,
    ) async {
      await pump(
        tester,
        const HomeCoverImage(url: null, fallback: HomeScreen.meditationsCover),
      );

      expect(find.byType(HomeCoverPlaceholder), findsNothing);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        const AssetImage(HomeScreen.meditationsCover),
      );
    });
  });

  group('HomeSectionCover', () {
    const statusBar = 47.0;

    Future<void> pump(
      WidgetTester tester, {
      required bool underStatusBar,
      String title = HomeText.meditations,
      String seeAllLabel = HomeText.seeAll,
      VoidCallback? onSeeAll,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(_screenWidth, 800),
              padding: EdgeInsets.only(top: statusBar),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: _screenWidth,
                  child: HomeSectionCover(
                    title: title,
                    subtitle: HomeText.meditationsSubtitle,
                    onSeeAll: onSeeAll,
                    seeAllLabel: seeAllLabel,
                    underStatusBar: underStatusBar,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (final (title, label) in [
      (HomeText.meditations, HomeText.seeAll),
      (HomeText.tools, 'темы'),
      (HomeText.topics, 'инструменты'),
      (HomeText.articles, HomeText.seeAll),
      (HomeText.diary, HomeText.seeAll),
    ]) {
      final name = title.replaceAll('\n', ' ');
      testWidgets('"$label" badge centered on the first line of "$name"', (
        tester,
      ) async {
        await pump(
          tester,
          underStatusBar: false,
          title: title,
          seeAllLabel: label,
          onSeeAll: () {},
        );

        final titleText = find.text(title);
        final style = tester.widget<Text>(titleText).style!;
        final lineHeight = style.fontSize! * style.height!;
        final firstLineCenter =
            tester.getTopLeft(titleText).dy + lineHeight / 2;
        final badge = tester.getRect(find.byType(AppBadge));
        expect(badge.center.dy, closeTo(firstLineCenter, 0.01));
        // Not pinned to the title's top edge.
        expect(badge.top, greaterThan(tester.getTopLeft(titleText).dy));
      });
    }

    testWidgets('subtitle is 6 columns wide', (tester) async {
      await pump(tester, underStatusBar: false);

      const content = _screenWidth - 2 * AppGrid.margin;
      final subtitle = find.text(bindShortWords(HomeText.meditationsSubtitle));
      expect(HomeSectionCover.subtitleColumns, 6);
      expect(tester.getRect(subtitle).left, AppGrid.margin);
      expect(
        tester.getSize(subtitle).width,
        lessThanOrEqualTo(AppGrid.span(content, 6) + 0.01),
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(of: subtitle, matching: find.byType(SizedBox))
                  .first,
            )
            .width,
        closeTo(AppGrid.span(content, 6), 0.01),
      );
    });

    testWidgets('subtitle ties one-letter words to the next one', (
      tester,
    ) async {
      await pump(tester, underStatusBar: false);

      // "Практики для осознания, проживания и восстановления".
      final text = tester
          .widget<Text>(
            find.descendant(
              of: find.byType(HomeSectionCover),
              matching: find.textContaining('восстановления'),
            ),
          )
          .data!;
      expect(text, contains('и$nbspвосстановления'));
      expect(text, isNot(contains(' и ')));
    });

    testWidgets('in a feed: 350px tall, text 32px below its top', (
      tester,
    ) async {
      await pump(tester, underStatusBar: false);

      final cover = tester.getRect(find.byType(HomeSectionCover));
      expect(cover.height, HomeSectionCover.height);
      expect(
        tester.getTopLeft(find.text(HomeText.meditations)).dy - cover.top,
        AppSpacing.xl,
      );
    });

    testWidgets('under the status bar: image from the screen top, text '
        'below the status bar', (tester) async {
      await pump(tester, underStatusBar: true);

      final cover = tester.getRect(find.byType(HomeSectionCover));
      expect(cover.top, 0);
      expect(cover.height, statusBar + HomeSectionCover.height);
      expect(
        tester.getTopLeft(find.text(HomeText.meditations)).dy,
        statusBar + AppSpacing.xl,
      );
    });
  });
}
