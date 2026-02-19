import 'package:flutter/material.dart';

import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/home_bottom_nav.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _tab = 0;

  final List<_Leader> _all = const [
    _Leader(1, 'Nora fathi', 43, 'assets/images/nora.jpg'),
    _Leader(2, 'Tammana batiya', 40, 'assets/images/tammana.jpg'),
    _Leader(3, 'Alina Amir', 38, 'assets/images/alina.jpg'),
    _Leader(4, 'Sofia Ansari', 36, 'assets/images/yoga.jpg'),
    _Leader(5, 'Sonam Kapoor', 35, 'assets/images/pilates.jpg'),
    _Leader(6, 'Hassan Raza', 34, 'assets/images/situp.jpg', me: true),
    _Leader(7, 'Sonam Bajwa', 33, 'assets/images/weightlifting.jpg'),
    _Leader(8, 'Lina Khan', 32, 'assets/images/Calisthenics.jpg'),
    _Leader(9, 'Ahmed Raza', 31, 'assets/images/pushup.jpg'),
  ];

  final List<_Leader> _men = const [
    _Leader(1, 'Sofia Ansari', 36, 'assets/images/yoga.jpg'),
    _Leader(2, 'Sonam Kapoor', 35, 'assets/images/pilates.jpg'),
    _Leader(3, 'Hassan Raza', 34, 'assets/images/situp.jpg', me: true),
    _Leader(4, 'Lina Khan', 32, 'assets/images/Calisthenics.jpg'),
    _Leader(5, 'Anita Hassanandani', 31, 'assets/images/pushup.jpg'),
  ];

  final List<_Leader> _women = const [
    _Leader(1, 'Nora fathi', 43, 'assets/images/nora.jpg'),
    _Leader(2, 'Tammana batiya', 40, 'assets/images/tammana.jpg'),
    _Leader(3, 'Alina Amir', 38, 'assets/images/alina.jpg'),
    _Leader(4, 'Sonam Bajwa', 33, 'assets/images/weightlifting.jpg'),
  ];

  List<_Leader> get _current {
    switch (_tab) {
      case 1:
        return _men;
      case 2:
        return _women;
      default:
        return _all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _current;
    final top = data.take(3).toList();
    final rest = data.skip(3).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Leaderboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1100;
          final isTablet = width >= 700 && width < 1100;
          final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 14.0);
          final contentMaxWidth =
              isDesktop ? 1180.0 : (isTablet ? 820.0 : double.infinity);
          final topRowSpacing = isDesktop ? 18.0 : (isTablet ? 14.0 : 8.0);
          final topRadius = isDesktop ? 58.0 : (isTablet ? 50.0 : 42.0);
          final otherRadius = isDesktop ? 48.0 : (isTablet ? 42.0 : 34.0);
          final topNameWidth = isDesktop ? 170.0 : (isTablet ? 140.0 : 98.0);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: ListView(
                padding:
                    EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 90),
                children: [
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 60),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          _tabButton(0, 'All'),
                          _tabButton(1, 'Men'),
                          _tabButton(2, 'Women'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (top.length == 3)
                    AnimatedReveal(
                      delay: const Duration(milliseconds: 120),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _TopUser(
                              leader: top[1],
                              rank: 2,
                              radius: otherRadius,
                              nameWidth: topNameWidth,
                            ),
                          ),
                          SizedBox(width: topRowSpacing),
                          Expanded(
                            child: _TopUser(
                              leader: top[0],
                              rank: 1,
                              radius: topRadius,
                              nameWidth: topNameWidth,
                            ),
                          ),
                          SizedBox(width: topRowSpacing),
                          Expanded(
                            child: _TopUser(
                              leader: top[2],
                              rank: 3,
                              radius: otherRadius,
                              nameWidth: topNameWidth,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 180),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.successPaleFor(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: rest
                            .map(
                              (e) => _RankRow(
                                leader: e,
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const HomeBottomNav(selected: 'Leaderboard'),
    );
  }

  Widget _tabButton(int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopUser extends StatelessWidget {
  final _Leader leader;
  final int rank;
  final double radius;
  final double nameWidth;

  const _TopUser({
    required this.leader,
    required this.rank,
    required this.radius,
    required this.nameWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundImage: AssetImage(leader.image),
              ),
            ),
            Positioned(
              bottom: -2,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: nameWidth,
          child: Text(
            leader.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '${leader.points} pts',
          style: TextStyle(
            color: AppColors.textSecondaryFor(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  final _Leader leader;
  final bool isDesktop;
  final bool isTablet;

  const _RankRow({
    required this.leader,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = leader.me;
    final bg = highlight ? AppColors.primary : AppColors.surface(context);
    final fg = highlight ? Colors.white : AppColors.textPrimaryFor(context);
    final verticalPad = isDesktop ? 14.0 : (isTablet ? 12.0 : 10.0);
    final avatarRadius = isDesktop ? 16.0 : 14.0;
    final nameSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: verticalPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${leader.rank}',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
          CircleAvatar(radius: avatarRadius, backgroundImage: AssetImage(leader.image)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              leader.name,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: nameSize,
              ),
            ),
          ),
          Text(
            '${leader.points} pts',
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Leader {
  final int rank;
  final String name;
  final int points;
  final String image;
  final bool me;

  const _Leader(
    this.rank,
    this.name,
    this.points,
    this.image, {
    this.me = false,
  });
}
