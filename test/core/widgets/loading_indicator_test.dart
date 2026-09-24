import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

void main() {
  testWidgets('centers a spinner colored by progressIndicatorTheme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: AppColors.fireRed,
          ),
        ),
        home: const Scaffold(body: LoadingIndicator()),
      ),
    );

    final spinner = find.byType(CircularProgressIndicator);
    expect(spinner, findsOneWidget);
    expect(
      find.ancestor(of: spinner, matching: find.byType(Center)),
      findsWidgets,
    );
    expect(
      tester.getCenter(spinner),
      tester.getCenter(find.byType(LoadingIndicator)),
    );

    final paint = find.descendant(
      of: spinner,
      matching: find.byType(CustomPaint),
    );
    expect(paint, paints..arc(color: AppColors.fireRed));
  });
}
