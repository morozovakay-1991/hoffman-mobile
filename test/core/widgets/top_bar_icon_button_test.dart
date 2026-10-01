import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/services/text_sharer.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';
import 'package:hoffman/features/meditations/index.dart';

const _screenWidth = 393.0;

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        textSharerProvider.overrideWithValue(
          (text, {subject, origin}) async {},
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: _screenWidth, child: child),
          ),
        ),
      ),
    ),
  );
}

/// The 24×24 box the glyph is drawn in.
Rect _glyphBox(WidgetTester tester, IconData icon) =>
    tester.getRect(find.byIcon(icon));

void main() {
  group('TopBarIconButton', () {
    testWidgets('a 24×24 glyph centered in a 40px tap square', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: TopBarIconButton(
            icon: Icons.chevron_left,
            tooltip: 'Назад',
            color: AppColors.background,
            onPressed: () => taps++,
          ),
        ),
      );

      final button = tester.getRect(find.byType(TopBarIconButton));
      final glyph = _glyphBox(tester, Icons.chevron_left);
      expect(button.size, const Size.square(40));
      expect(glyph.size, const Size.square(24));
      expect(glyph.center, button.center);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.chevron_left)).color,
        AppColors.background,
      );
      expect(find.byTooltip('Назад'), findsOneWidget);

      // The whole square is tappable, not only the glyph.
      await tester.tapAt(button.topLeft + const Offset(2, 2));
      expect(taps, 1);
    });
  });

  group('MeditationTopBar — Figma 2:211 back / 2:236 share', () {
    testWidgets('40px row, both glyphs 24×24, 16px from the edges, on one '
        'center line', (tester) async {
      await _pump(
        tester,
        MeditationTopBar(
          onBack: () {},
          trailing: const ShareButton(text: 'Текст'),
        ),
      );

      final bar = tester.getRect(find.byType(MeditationTopBar));
      final back = _glyphBox(tester, MeditationTopBar.backIcon);
      final share = _glyphBox(tester, ShareButton.icon);

      expect(bar.height, 40);
      expect(back.size, const Size.square(24));
      expect(share.size, const Size.square(24));
      expect(back.left - bar.left, AppSpacing.md);
      expect(bar.right - share.right, AppSpacing.md);
      expect(back.center.dy, share.center.dy);
      expect(back.center.dy, bar.center.dy);
    });

    testWidgets('the share glyph is Figma `sharing`, not the iOS box-arrow', (
      tester,
    ) async {
      await _pump(
        tester,
        MeditationTopBar(
          onBack: () {},
          trailing: const ShareButton(text: 'Текст'),
        ),
      );

      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsNothing);
    });
  });
}
