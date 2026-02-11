import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_colors.dart';

class HomeBottomNav extends StatelessWidget {
  final String selected;

  const HomeBottomNav({
    required this.selected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final iconSize = compact ? 18.0 : 20.0;
        final fontSize = compact ? 9.0 : 10.0;

        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: compact ? 62 : 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NavItem(
                  icon: Icons.home,
                  label: 'Home',
                  selected: selected == 'Home',
                  onTap: () => Get.toNamed('/home'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                NavItem(
                  icon: Icons.restaurant_menu,
                  label: 'Food Log',
                  selected: selected == 'Food Log',
                  onTap: () => Get.toNamed('/food-logging'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                NavItem(
                  icon: Icons.flag,
                  label: 'Challenges',
                  selected: selected == 'Challenges',
                  onTap: () => Get.toNamed('/challenges'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                NavItem(
                  icon: Icons.leaderboard,
                  label: 'Leaderboard',
                  selected: selected == 'Leaderboard',
                  onTap: () => Get.toNamed('/leaderboard'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                NavItem(
                  icon: Icons.menu_book,
                  label: 'Guides',
                  selected: selected == 'Guides',
                  onTap: () => Get.toNamed('/guides'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  selected: selected == 'Settings',
                  onTap: () {},
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
              ],
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
    final color = selected ? AppColors.primary : AppColors.navUnselected;
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
