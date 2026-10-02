import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';

/// A tab of [AppTabBar].
@immutable
class AppTabBarItem {
  const AppTabBarItem({required this.icon, required this.label});

  final IconData icon;

  /// Not drawn (the mockup shows icons only); read by screen readers.
  final String label;
}

/// Bottom tab bar, Figma `button/icon/menu` (node 982:2025): icons only,
/// equal-width buttons on a blurred half-transparent white strip with a
/// 0.5px black top border. The home indicator inset is added below.
///
/// Meant for `Scaffold.bottomNavigationBar` with `extendBody: true`, so the
/// content scrolls under the blur.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Button row height: the 81px Figma bar minus the 34px home indicator.
  static const double height = 47;
  static const double iconSize = 24;
  static const double borderWidth = 0.5;
  static const double blurSigma = 2;
  static const double backgroundOpacity = 0.5;

  static const Color selectedColor = AppColors.basicBlack;
  static const Color unselectedColor = AppColors.blueTint;

  final List<AppTabBarItem> items;

  /// `-1` when none of the tabs is open.
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: backgroundOpacity),
            border: const Border(top: BorderSide(width: borderWidth)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              height: height,
              child: Row(
                children: [
                  for (final (i, item) in items.indexed)
                    Expanded(
                      child: _TabButton(
                        item: item,
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppTabBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: Center(
          child: Icon(
            item.icon,
            size: AppTabBar.iconSize,
            color: selected
                ? AppTabBar.selectedColor
                : AppTabBar.unselectedColor,
          ),
        ),
      ),
    );
  }
}
