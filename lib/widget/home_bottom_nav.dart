import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_colors.dart';
import 'getx.dart';

class HomeBottomNav extends StatelessWidget {
  final String selected;

  const HomeBottomNav({
    required this.selected,
    super.key,
  });

  void _go(String tabLabel, String routeName) {
    if (selected == tabLabel) return;
    Get.offNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 420;
        final isTablet = width >= 700 && width < 1100;
        final isDesktop = width >= 1100;
        final iconSize = compact
            ? 21.0
            : isDesktop
            ? 24.0
            : isTablet
            ? 22.0
            : 21.0;
        final fontSize = compact
            ? 10.0
            : isDesktop
            ? 11.0
            : isTablet
            ? 10.5
            : 10.0;
        final navHeight = compact
            ? 62.0
            : isDesktop
            ? 74.0
            : isTablet
            ? 70.0
            : 68.0;
        final contentMaxWidth = isDesktop
            ? 960.0
            : isTablet
            ? 820.0
            : width;

        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: navHeight,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NavItem(
                      icon: Icons.home,
                      label: 'Home',
                      selected: selected == 'Home',
                      onTap: () => _go('Home', Routes.home),
                      iconSize: iconSize,
                      fontSize: fontSize,
                      showLabel: !compact,
                    ),
                    NavItem(
                      icon: Icons.restaurant_menu,
                      label: 'Food Log',
                      selected: selected == 'Food Log',
                      onTap: () => _go('Food Log', Routes.foodLogging),
                      iconSize: iconSize,
                      fontSize: fontSize,
                      showLabel: !compact,
                    ),
                    NavItem(
                      icon: Icons.flag,
                      label: 'Challenges',
                      selected: selected == 'Challenges',
                      onTap: () => _go('Challenges', Routes.challenges),
                      iconSize: iconSize,
                      fontSize: fontSize,
                      showLabel: !compact,
                    ),
                    NavItem(
                      icon: Icons.leaderboard,
                      label: 'Leaderboard',
                      selected: selected == 'Leaderboard',
                      onTap: () => _go('Leaderboard', Routes.leaderboard),
                      iconSize: iconSize,
                      fontSize: fontSize,
                      showLabel: !compact,
                    ),
                    NavItem(
                      icon: Icons.menu_book,
                      label: 'Guides',
                      selected: selected == 'Guides',
                      onTap: () => _go('Guides', Routes.guides),
                      iconSize: iconSize,
                      fontSize: fontSize,
                      showLabel: !compact,
                    ),
                    NavItem(
                      icon: Icons.settings,
                      label: 'Settings',
                      selected: selected == 'Settings',
                      onTap: () => _go('Settings', Routes.settings),
                      iconSize: iconSize,
                      fontSize: fontSize,
                      showLabel: !compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;
  final bool showLabel;

  const NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconSize = 20,
    this.fontSize = 10,
    this.showLabel = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.navUnselectedFor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            if (showLabel) const SizedBox(height: 4),
            if (showLabel)
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

