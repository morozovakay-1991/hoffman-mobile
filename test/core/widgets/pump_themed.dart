import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';

/// Pumps [child] inside a [MaterialApp] with [AppTheme.light].
Future<void> pumpThemed(WidgetTester tester, Widget child, {double? width}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: width == null ? child : SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}
