// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: Column(
          children: [
            const _BlueHeader(title: 'Leaderboard', showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _TopUser(
                        rank: 2,
                        name: 'Tammana batiya...',
                        points: '40 pts',
                        imagePath: 'assets/images/tammana.jpg',
                      ),
                      _TopUser(
                        rank: 1,
                        name: 'Nora fathi',
                        points: '43 pts',
                        imagePath: 'assets/images/nora.jpg',
                        isTop: true,
                      ),
                      _TopUser(
                        rank: 3,
                        name: 'Alina Amir',
                        points: '38 pts',
                        imagePath: 'assets/images/alina.jpg',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4EA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: const [
                        _RankRow(
                          rank: 4,
                          name: 'Sofia Ansari',
                          points: '36 pts',
                        ),
                        _RankRow(
                          rank: 5,
                          name: 'Sonam Kapoor',
                          points: '35 pts',
                        ),
                        _RankRow(
                          rank: 6,
                          name: 'You',
                          points: '34 pts',
                          highlight: true,
                        ),
                        _RankRow(
                          rank: 7,
                          name: 'Sonam Bajwa',
                          points: '33 pts',
                        ),
                        _RankRow(rank: 8, name: 'Lina Khan', points: '32 pts'),
                        _RankRow(
                          rank: 9,
                          name: 'Anita Hassanandani',
                          points: '31 pts',
                        ),
                        _RankRow(
                          rank: 10,
                          name: 'Sara Ali Khan',
                          points: '30 pts',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D3DBB),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const _HomeBottomNav(selected: 'Leaderboard'),
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const _BlueHeader({required this.title, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1D3DBB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          if (showBack)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _TopUser extends StatelessWidget {
  final int rank;
  final String name;
  final String points;
  final String imagePath;
  final bool isTop;

  const _TopUser({
    required this.rank,
    required this.name,
    required this.points,
    required this.imagePath,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isTop ? 72.0 : 64.0;
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTop ? const Color(0xFF1D3DBB) : Colors.white,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
            Positioned(
              bottom: -2,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF1D3DBB),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          points,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String name;
  final String points;
  final bool highlight;

  const _RankRow({
    required this.rank,
    required this.name,
    required this.points,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? const Color(0xFF1D3DBB) : Colors.white;
    final fg = highlight ? Colors.white : const Color(0xFF374151);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 14,
            backgroundColor: highlight
                ? Colors.white.withOpacity(0.2)
                : const Color(0xFFEAEFFD),
            child: Icon(
              Icons.person,
              size: 14,
              color: highlight ? Colors.white : const Color(0xFF1D3DBB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            points,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  final String selected;

  const _HomeBottomNav({required this.selected});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home,
              label: 'Home',
              selected: selected == 'Home',
              onTap: () => Get.toNamed('/home'),
            ),
            _NavItem(
              icon: Icons.restaurant_menu,
              label: 'Food Log',
              selected: selected == 'Food Log',
              onTap: () => Get.toNamed('/food-logging'),
            ),
            const SizedBox(width: 24),
            _NavItem(
              icon: Icons.flag,
              label: 'Challenges',
              selected: selected == 'Challenges',
              onTap: () => Get.toNamed('/challenges'),
            ),
            _NavItem(
              icon: Icons.leaderboard,
              label: 'Leaderboard',
              selected: selected == 'Leaderboard',
              onTap: () => Get.toNamed('/leaderboard'),
            ),
            _NavItem(
              icon: Icons.menu_book,
              label: 'Guides',
              selected: selected == 'Guides',
              onTap: () => Get.toNamed('/guides'),
            ),
            _NavItem(
              icon: Icons.settings,
              label: 'Settings',
              selected: selected == 'Settings',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1D3DBB) : const Color(0xFFB0B7C3);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
