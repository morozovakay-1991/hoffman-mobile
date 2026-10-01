import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/dev/debug_grid.dart';
import 'package:hoffman/features/auth/index.dart';
import 'package:hoffman/main.dart';

import '../helpers/app_harness.dart';

final Finder _toggle = find.byKey(DebugGridHost.toggleKey);
final Finder _grid = find.byType(GridOverlay);

/// A two-route app with [debugGridBuilder] as its builder.
Widget _app({required bool enabled, VoidCallback? onTap}) => MaterialApp(
  theme: AppTheme.light,
  builder: debugGridBuilder(enabled: enabled),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            onTap?.call();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Второй экран')),
              ),
            );
          },
          child: const Text('Дальше'),
        ),
      ),
    ),
  ),
);

void main() {
  group('release configuration (enabled: false, as kDebugMode is there)', () {
    test('no builder at all', () {
      expect(debugGridBuilder(enabled: false), isNull);
    });

    testWidgets('neither the toggle nor the grid is created', (tester) async {
      await tester.pumpWidget(_app(enabled: false));

      expect(find.byType(DebugGridHost), findsNothing);
      expect(_toggle, findsNothing);
      expect(_grid, findsNothing);
    });
  });

  group('debug', () {
    testWidgets('the toggle shows and hides the grid', (tester) async {
      await tester.pumpWidget(_app(enabled: true));

      expect(_toggle, findsOneWidget);
      expect(_grid, findsNothing);

      await tester.tap(_toggle);
      await tester.pump();
      expect(_grid, findsOneWidget);

      await tester.tap(_toggle);
      await tester.pump();
      expect(_grid, findsNothing);
    });

    testWidgets('the grid stays on across navigation and lets taps through', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_app(enabled: true, onTap: () => taps++));

      await tester.tap(_toggle);
      await tester.pump();
      // The grid covers the button, which still gets the tap.
      await tester.tap(find.text('Дальше'));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.text('Второй экран'), findsOneWidget);
      expect(_grid, findsOneWidget);
      expect(_toggle, findsOneWidget);
    });

    testWidgets('the grid covers the whole screen', (tester) async {
      await tester.pumpWidget(_app(enabled: true));
      await tester.tap(_toggle);
      await tester.pump();

      expect(
        tester.getRect(_grid),
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio,
      );
    });
  });

  group('GridOverlay.columnRects', () {
    const size = Size(393, 852);

    test('8 columns and 7 gutters between the 16px margins, by AppGrid', () {
      final rects = GridOverlay.columnRects(size, EdgeInsets.zero);
      const content = 393 - 2 * AppGrid.margin;

      expect(rects, hasLength(AppGrid.columns));
      expect(rects.first.left, AppGrid.margin);
      expect(rects.last.right, closeTo(size.width - AppGrid.margin, 1e-9));
      for (final rect in rects) {
        expect(rect.width, closeTo(AppGrid.column(content), 1e-9));
        expect(rect.top, 0);
        expect(rect.height, size.height);
      }
      for (var i = 1; i < rects.length; i++) {
        expect(
          rects[i].left - rects[i - 1].right,
          closeTo(AppGrid.gutter(content), 1e-9),
        );
      }
    });

    test('Figma 1:957: 38px columns, 8px gutters on 360px of content', () {
      final rects = GridOverlay.columnRects(
        const Size(360 + 2 * AppGrid.margin, 800),
        EdgeInsets.zero,
      );

      expect(rects.first.width, closeTo(38, 1e-9));
      expect(rects[1].left - rects[0].right, closeTo(8, 1e-9));
    });

    test('the margins start inside the horizontal safe area', () {
      const padding = EdgeInsets.only(left: 44, right: 44, top: 47);
      final rects = GridOverlay.columnRects(size, padding);

      expect(rects.first.left, 44 + AppGrid.margin);
      expect(rects.last.right, closeTo(393 - 44 - AppGrid.margin, 1e-9));
      // Still the full height: the top inset only moves the content.
      expect(rects.first.top, 0);
    });
  });

  group('HoffmanApp', () {
    testWidgets('without debugGrid (tests, goldens): no toggle', (
      tester,
    ) async {
      await pumpApp(tester, TestEnvironment());

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(_toggle, findsNothing);
    });

    testWidgets('debugGrid in a debug build: the toggle over the app', (
      tester,
    ) async {
      expect(kDebugMode, isTrue);
      useFigmaViewport(tester);
      final container = TestEnvironment().createContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const HoffmanApp(debugGrid: true),
        ),
      );
      await finishSplash(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.tap(_toggle);
      await tester.pump();
      expect(_grid, findsOneWidget);
    });
  });
}
