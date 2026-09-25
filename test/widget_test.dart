import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/router/index.dart';
import 'package:hoffman/features/auth/index.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('a returning signed-out user lands on Login after the splash', (
    tester,
  ) async {
    final container = await pumpApp(tester, TestEnvironment());

    expect(currentPath(container), AppRoutes.login);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
