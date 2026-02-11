// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categoryImages = <String, String>{
    'Yoga': 'assets/images/yoga.jpg',
    'Pilates': 'assets/images/pilates.jpg',
    'Weightlifting': 'assets/images/weightlifting.jpg',
    'Calisthenics': 'assets/images/Calisthenics.jpg',
    'Stretching & Mobility': 'assets/images/Stretching & Mobility.jpg',
  };

  void _showWorkoutPopup(BuildContext context) {
    const items = [
      'Yoga',
      'Pilates',
      'Weightlifting',
      'Calisthenics',
      'Stretching & Mobility',
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Workout Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D3DBB),
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((label) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D3DBB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

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
        final titleSize = isDesktop
            ? 28.0
            : isTablet
            ? 24.0
            : 22.0;
        final subtitleSize = isDesktop ? 14.0 : 13.0;
        final headerRadius = isDesktop ? 26.0 : 22.0;
        final categoryCardWidth = isDesktop
            ? 160.0
            : isTablet
            ? 140.0
            : 120.0;
        final categoryCardHeight = isDesktop
            ? 150.0
            : isTablet
            ? 140.0
            : 130.0;
        final mealHeight = isDesktop
            ? 200.0
            : isTablet
            ? 180.0
            : 160.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F5FB),
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D3DBB),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(headerRadius),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome to',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: subtitleSize,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Fitness',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => Get.toNamed('/profile'),
                                borderRadius: BorderRadius.circular(22),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    'https://instagram.fbhv1-1.fna.fbcdn.net/v/t51.2885-19/472294191_1105393394457686_554111962204078586_n.jpg?efg=eyJ2ZW5jb2RlX3RhZyI6InByb2ZpbGVfcGljLmRqYW5nby4xMDgwLmMyIn0&_nc_ht=instagram.fbhv1-1.fna.fbcdn.net&_nc_cat=102&_nc_oc=Q6cZ2QFPco5nXp9cXZCormOpxSR_IStByEK7TtzKIix18azp0fhLpjo-OmRwB5YRM2MgfBk&_nc_ohc=43gHM-x_W18Q7kNvwELfwN1&_nc_gid=TYaa_VlHXwocm-WkhQhxgQ&edm=AP4sbd4BAAAA&ccb=7-5&oh=00_AfsvBghJkIPr-6Tg34sElr5wVYnz4kXunkzZfQcCIUq_5A&oe=6990B0AD&_nc_sid=7a9f4b',
                                  ),
                                  radius: isDesktop ? 20 : 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: isDesktop ? 40 : 36,
                                height: isDesktop ? 40 : 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2949C8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_none,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'Choose Random Challenge',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF47516B),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showWorkoutPopup(context),
                                      child: const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Color(0xFF1D3DBB),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D3DBB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: const Text(
                                      'Start Random Challenge',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          hPadding,
                          20,
                          hPadding,
                          90,
                        ),
                        children: [
                          _SectionHeader(
                            title: 'Workout Category',
                            onTap: () => _showWorkoutPopup(context),
                          ),
                          const SizedBox(height: 12),
                          if (isDesktop)
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                              children: [
                                _CategoryCard(
                                  title: 'Yoga',
                                  imagePath: _categoryImages['Yoga'],
                                  margin: EdgeInsets.zero,
                                ),
                                _CategoryCard(
                                  title: 'Pilates',
                                  imagePath: _categoryImages['Pilates'],
                                  margin: EdgeInsets.zero,
                                ),
                                _CategoryCard(
                                  title: 'Weightlifting',
                                  imagePath: _categoryImages['Weightlifting'],
                                  margin: EdgeInsets.zero,
                                ),
                                _CategoryCard(
                                  title: 'Calisthenics',
                                  imagePath: _categoryImages['Calisthenics'],
                                  margin: EdgeInsets.zero,
                                ),
                                _CategoryCard(
                                  title: 'Stretching & Mobility',
                                  imagePath:
                                      _categoryImages['Stretching & Mobility'],
                                  margin: EdgeInsets.zero,
                                ),
                              ],
                            )
                          else
                            SizedBox(
                              height: categoryCardHeight,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _CategoryCard(
                                    title: 'Yoga',
                                    imagePath: _categoryImages['Yoga'],
                                    width: categoryCardWidth,
                                    height: categoryCardHeight,
                                  ),
                                  _CategoryCard(
                                    title: 'Pilates',
                                    imagePath: _categoryImages['Pilates'],
                                    width: categoryCardWidth,
                                    height: categoryCardHeight,
                                  ),
                                  _CategoryCard(
                                    title: 'Weightlifting',
                                    imagePath: _categoryImages['Weightlifting'],
                                    width: categoryCardWidth,
                                    height: categoryCardHeight,
                                  ),
                                  _CategoryCard(
                                    title: 'Calisthenics',
                                    imagePath: _categoryImages['Calisthenics'],
                                    width: categoryCardWidth,
                                    height: categoryCardHeight,
                                  ),
                                  _CategoryCard(
                                    title: 'Stretching & Mobility',
                                    imagePath:
                                        _categoryImages['Stretching & Mobility'],
                                    width: categoryCardWidth,
                                    height: categoryCardHeight,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 22),
                          const _SectionHeader(title: 'Recommended Meal'),
                          const SizedBox(height: 12),
                          Container(
                            height: mealHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              image: const DecorationImage(
                                image: AssetImage(
                                  'assets/images/healthy bowl.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                        colors: [
                                          Color(0xAA1D3DBB),
                                          Color(0x001D3DBB),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Positioned(
                                  left: 16,
                                  bottom: 16,
                                  child: Text(
                                    'Healthy Bowl',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
            backgroundColor: const Color(0xFF1D3DBB),
            onPressed: () {},
            child: const Icon(Icons.add, color: Colors.white),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const _HomeBottomNav(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionHeader({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: const Text(
            'View all',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A94A6),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String? imagePath;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const _CategoryCard({
    required this.title,
    this.imagePath,
    this.width,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 120,
      height: height,
      margin: margin ?? const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: imagePath != null
            ? DecorationImage(image: AssetImage(imagePath!), fit: BoxFit.cover)
            : null,
        gradient: imagePath == null
            ? const LinearGradient(
                colors: [Color(0xFFBFD3FF), Color(0xFF82A5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xAA0F172A), Color(0x001D3DBB)],
          ),
        ),
        child: Center(
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav();

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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home,
                  label: 'Home',
                  selected: true,
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                _NavItem(
                  icon: Icons.restaurant_menu,
                  label: 'Food Log',
                  onTap: () => Get.toNamed('/food-logging'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                const SizedBox(width: 24),
                _NavItem(
                  icon: Icons.flag,
                  label: 'Challenges',
                  onTap: () => Get.toNamed('/challenges'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                _NavItem(
                  icon: Icons.leaderboard,
                  label: 'Leaderboard',
                  onTap: () => Get.toNamed('/leaderboard'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                _NavItem(
                  icon: Icons.menu_book,
                  label: 'Guides',
                  onTap: () => Get.toNamed('/guides'),
                  iconSize: iconSize,
                  fontSize: fontSize,
                  showLabel: !compact,
                ),
                _NavItem(
                  icon: Icons.settings,
                  label: 'Settings',
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double iconSize;
  final double fontSize;
  final bool showLabel;

  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.iconSize = 20,
    this.fontSize = 10,
    this.showLabel = true,
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
