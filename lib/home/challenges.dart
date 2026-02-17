import 'package:flutter/material.dart';
import '../widget/app_colors.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_button.dart';
import '../widget/home_bottom_nav.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

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
        final categoryHeight = isDesktop
            ? 150.0
            : isTablet
            ? 140.0
            : 130.0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(top: false, bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    const AnimatedReveal(
                      child: _BlueHeader(
                        title: 'Challenges',
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(hPadding, 20, hPadding, 24),
                        children: [
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 80),
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Random Challenge',
                          style: TextStyle(
                            color: AppColors.textSecondaryFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/yoga.jpg',
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Color(0x990F172A),
                                        Color(0x000F172A),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: AppButton(
                                  label: 'Select Random Challenge',
                                  onPressed: () {},
                                  width: double.infinity,
                                  height: 36,
                                  backgroundColor: AppColors.primary,
                                  borderRadius: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedReveal(
                    delay: Duration(milliseconds: 140),
                    child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Workout Category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryFor(context),
                          ),
                        ),
                      ),
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMutedFor(context),
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedReveal(
                    delay: const Duration(milliseconds: 180),
                    child: SizedBox(
                      height: categoryHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _CategoryCard(
                            title: 'Yoga',
                            imagePath: 'assets/images/yoga.jpg',
                          ),
                          _CategoryCard(
                            title: 'Pilates',
                            imagePath: 'assets/images/pilates.jpg',
                          ),
                          _CategoryCard(
                            title: 'Calisthenics',
                            imagePath: 'assets/images/Calisthenics.jpg',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedReveal(
                    delay: Duration(milliseconds: 220),
                    child: Text(
                      'Current Challenges',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryFor(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const AnimatedReveal(
                    delay: Duration(milliseconds: 260),
                    child: _ChallengeTile(
                      title: 'Push Up',
                      subtitle: '100 Push up a day',
                      time: '5:00 min',
                      progress: 0.45,
                      imagePath: 'assets/images/pushup.jpg',
                    ),
                  ),
                  const AnimatedReveal(
                    delay: Duration(milliseconds: 300),
                    child: _ChallengeTile(
                      title: 'Sit Up',
                      subtitle: '20 Sit up a day',
                      time: '4:30 min',
                      progress: 0.70,
                      imagePath: 'assets/images/situp.jpg',
                    ),
                  ),
                  const AnimatedReveal(
                    delay: Duration(milliseconds: 340),
                    child: _ChallengeTile(
                      title: 'Knee Push Up',
                      subtitle: '20 Sit up a day',
                      time: '3:00 min',
                      progress: 0.35,
                      imagePath: 'assets/images/knee pushup.jpg',
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
          bottomNavigationBar: const HomeBottomNav(selected: 'Challenges'),
        );
      },
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final String title;

  const _BlueHeader({required this.title});

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
          const SizedBox(width: 34),
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

class _CategoryCard extends StatelessWidget {
  final String title;
  final String imagePath;

  const _CategoryCard({required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
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
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final double progress;
  final String imagePath;

  const _ChallengeTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.progress,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondaryFor(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Icon(
                Icons.sync,
                size: 16,
                color: AppColors.textSecondaryFor(context),
              ),
              const SizedBox(height: 8),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}









