import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

void main() {
  group('AppTabBar', () {
    const items = [
      AppTabBarItem(icon: Icons.home, label: 'Главная'),
      AppTabBarItem(icon: Icons.headphones, label: 'Медитации'),
      AppTabBarItem(icon: Icons.person, label: 'Профиль'),
    ];

    Future<void> pump(WidgetTester tester, int currentIndex) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            bottomNavigationBar: AppTabBar(
              items: items,
              currentIndex: currentIndex,
              onTap: (_) {},
            ),
          ),
        ),
      );
    }

    Color? colorOf(WidgetTester tester, IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;

    test('unselected tabs take the Blue tint token', () {
      expect(AppTabBar.unselectedColor, AppColors.blueTint);
      expect(AppTabBar.selectedColor, AppColors.basicBlack);
    });

    testWidgets('the open tab is black, the others blue tint', (tester) async {
      await pump(tester, 1);

      expect(colorOf(tester, Icons.home), AppColors.blueTint);
      expect(colorOf(tester, Icons.headphones), AppColors.basicBlack);
      expect(colorOf(tester, Icons.person), AppColors.blueTint);
    });

    testWidgets('no open tab: every icon is blue tint, none grey', (
      tester,
    ) async {
      await pump(tester, -1);

      for (final item in items) {
        final color = colorOf(tester, item.icon);
        expect(color, AppColors.blueTint);
        expect(color, isNot(AppColors.softBlack));
        expect(color, isNot(AppColors.grey));
      }
    });
  });
}
