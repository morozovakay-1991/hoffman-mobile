import 'package:flutter/material.dart';

/// Generic stand-in for a screen that hasn't been built yet. Shows the
/// screen name (and any route path parameters) so routing can be exercised
/// end-to-end before real screens exist.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key, this.pathParameters = const {}});

  final String title;
  final Map<String, String> pathParameters;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (pathParameters.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  pathParameters.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
