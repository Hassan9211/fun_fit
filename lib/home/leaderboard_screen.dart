// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widget/app_colors.dart';
import '../widget/home_bottom_nav.dart';
import '../widget/getx.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700 && width < 1100;
        final hPadding = isDesktop
            ? 36.0
            : isTablet
            ? 28.0
            : 20.0;
        final contentMaxWidth = isDesktop
            ? 1040.0
            : isTablet
            ? 900.0
            : width;

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          body: SafeArea(top: false, bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    _BlueHeader(
                      title: 'Leaderboard',
                      showBack: true,
                      onBackTap: () => Get.offNamed(Routes.home),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(hPadding, 20, hPadding, 24),
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
                      color: AppColors.successPale,
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
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () {},
            child: const Icon(Icons.add, color: AppColors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Leaderboard'),
        );
      },
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBackTap;

  const _BlueHeader({
    required this.title,
    this.showBack = false,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          if (showBack)
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: onBackTap ?? () => Navigator.of(context).pop(),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
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
                  color: isTop ? AppColors.primary : AppColors.white,
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
                backgroundColor: AppColors.primary,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: AppColors.white,
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
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
    final bg = highlight ? AppColors.primary : AppColors.white;
    final fg = highlight ? AppColors.white : AppColors.textPrimary;
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
                : AppColors.avatarBg,
            child: Icon(
              Icons.person,
              size: 14,
              color: highlight ? AppColors.white : AppColors.primary,
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





