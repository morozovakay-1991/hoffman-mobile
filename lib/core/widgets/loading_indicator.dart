import 'package:flutter/material.dart';

/// Centered progress spinner; its color comes from
/// `ThemeData.progressIndicatorTheme`.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
