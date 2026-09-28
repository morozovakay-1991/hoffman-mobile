import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

/// A page with one button that opens the sheet and records its result.
Future<List<bool>> _pumpOpener(WidgetTester tester) async {
  final results = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showConfirmSheet(
                context,
                message: 'Выйти из аккаунта?',
                confirmLabel: 'Выйти',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  group('ConfirmSheet', () {
    testWidgets('title, message, then "Отменить" above the confirm button', (
      tester,
    ) async {
      await _pumpOpener(tester);

      expect(find.text(ConfirmSheet.defaultTitle), findsOneWidget);
      expect(find.text('Выйти из аккаунта?'), findsOneWidget);

      final cancel = find.descendant(
        of: find.byKey(ConfirmSheet.cancelKey),
        matching: find.byType(AppButton),
      );
      final confirm = find.descendant(
        of: find.byKey(ConfirmSheet.confirmKey),
        matching: find.byType(AppButton),
      );
      expect(tester.widget<AppButton>(cancel).label, 'Отменить');
      expect(
        tester.widget<AppButton>(cancel).variant,
        AppButtonVariant.primary,
      );
      expect(tester.widget<AppButton>(confirm).label, 'Выйти');
      expect(
        tester.widget<AppButton>(confirm).variant,
        AppButtonVariant.secondary,
      );
      expect(
        tester.getTopLeft(cancel).dy,
        lessThan(tester.getTopLeft(confirm).dy),
      );
      expect(tester.getSize(confirm).width, ConfirmSheet.buttonWidth);
    });

    testWidgets('confirm resolves to true and closes the sheet', (
      tester,
    ) async {
      final results = await _pumpOpener(tester);

      await tester.tap(find.byKey(ConfirmSheet.confirmKey));
      await tester.pumpAndSettle();

      expect(results, [true]);
      expect(find.byType(ConfirmSheet), findsNothing);
    });

    testWidgets('"Отменить" resolves to false', (tester) async {
      final results = await _pumpOpener(tester);

      await tester.tap(find.byKey(ConfirmSheet.cancelKey));
      await tester.pumpAndSettle();

      expect(results, [false]);
    });

    testWidgets('a tap on the barrier resolves to false', (tester) async {
      final results = await _pumpOpener(tester);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(find.byType(ConfirmSheet), findsNothing);
    });
  });
}
