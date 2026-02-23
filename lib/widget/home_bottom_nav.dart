import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 7,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            Expanded(
              child: _BottomItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: selected == 'Home',
                onTap: () => _go('Home', Routes.home),
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.fastfood_outlined,
                label: 'Food Log',
                selected: selected == 'Food Log',
                onTap: () => _go('Food Log', Routes.foodLogging),
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.fitness_center_outlined,
                label: 'Challenges',
                selected: selected == 'Challenges',
                onTap: () => _go('Challenges', Routes.challenges),
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _BottomItem(
                icon: Icons.bar_chart_rounded,
                label: 'Leaderboard',
                selected: selected == 'Leaderboard',
                onTap: () => _go('Leaderboard', Routes.leaderboard),
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.description_outlined,
                label: 'Guides',
                selected: selected == 'Guides',
                onTap: () => _go('Guides', Routes.guides),
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: selected == 'Settings',
                onTap: () => _go('Settings', Routes.settings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.black : const Color(0xFFB0B3B8);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
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
