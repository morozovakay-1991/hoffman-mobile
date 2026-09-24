import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/dev/widgets_showcase_screen.dart';

/// Dev entry point for the widget showcase:
/// `flutter run -t lib/main_showcase.dart`.
void main() {
  runApp(
    MaterialApp(
      title: 'Hoffman widgets',
      theme: AppTheme.light,
      home: const WidgetsShowcaseScreen(),
    ),
  );
}
