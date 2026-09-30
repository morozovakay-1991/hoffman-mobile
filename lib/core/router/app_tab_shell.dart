import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoffman/core/router/app_routes.dart';
import 'package:hoffman/core/widgets/app_tab_bar.dart';

/// Screens of the bottom tabs (Figma 982:2025), in bar order.
enum AppTab {
  home(
    AppRoutes.home,
    AppTabBarItem(icon: Icons.home_rounded, label: 'Главная'),
  ),
  articles(
    AppRoutes.articles,
    AppTabBarItem(icon: Icons.article_rounded, label: 'Статьи'),
  ),
  meditations(
    AppRoutes.meditations,
    AppTabBarItem(icon: Icons.play_circle_rounded, label: 'Медитации'),
  ),
  tools(
    AppRoutes.tools,
    AppTabBarItem(icon: Icons.build_rounded, label: 'Инструменты'),
    otherSections: [AppRoutes.topics],
  ),
  diary(
    AppRoutes.diary,
    AppTabBarItem(icon: Icons.menu_book_rounded, label: 'Дневник'),
  );

  AppTab(this.route, this.item, {this.otherSections = const []});

  final String route;
  final AppTabBarItem item;

  /// Sections that are not the tab's list but belong to it, like the topics
  /// of [tools] (ТЗ 5.5–5.6: one menu item for both).
  final List<String> otherSections;

  static AppTab? of(String location) {
    for (final tab in values) {
      if (tab.route == location) return tab;
    }
    return null;
  }

  /// The tab whose section [location] belongs to: its list, one of its
  /// [otherSections] or a screen under them (`/meditations/42` →
  /// [meditations], `/topics/7` → [tools]). `null` for the screens of no
  /// tab, such as the profile.
  static AppTab? sectionOf(String location) {
    for (final tab in values) {
      for (final section in [tab.route, ...tab.otherSections]) {
        if (location == section || location.startsWith('$section/')) {
          return tab;
        }
      }
    }
    return null;
  }
}

/// Shell of the signed-in screens: the current screen above [AppTabBar].
/// Tabs are switched with `go`, so each tab starts from its own list;
/// content and profile screens are pushed inside the shell, keeping the bar.
class AppTabShell extends StatelessWidget {
  const AppTabShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The tab screens scroll under the blurred bar; their MediaQuery
      // bottom padding covers its height.
      extendBody: true,
      // The screens are Scaffolds themselves and make room for the keyboard
      // on their own; resizing here too would shrink them twice.
      resizeToAvoidBottomInset: false,
      body: child,
      bottomNavigationBar: AppTabBar(
        items: [for (final tab in AppTab.values) tab.item],
        currentIndex: AppTab.sectionOf(location)?.index ?? -1,
        onTap: (i) => context.go(AppTab.values[i].route),
      ),
    );
  }
}
