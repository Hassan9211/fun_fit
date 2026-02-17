// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/app_colors.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_button.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _defaultProfileImageUrl =
      'https://instagram.fbhv1-1.fna.fbcdn.net/v/t51.2885-19/472294191_1105393394457686_554111962204078586_n.jpg?efg=eyJ2ZW5jb2RlX3RhZyI6InByb2ZpbGVfcGljLmRqYW5nby4xMDgwLmMyIn0&_nc_ht=instagram.fbhv1-1.fna.fbcdn.net&_nc_cat=102&_nc_oc=Q6cZ2QFPco5nXp9cXZCormOpxSR_IStByEK7TtzKIix18azp0fhLpjo-OmRwB5YRM2MgfBk&_nc_ohc=43gHM-x_W18Q7kNvwELfwN1&_nc_gid=TYaa_VlHXwocm-WkhQhxgQ&edm=AP4sbd4BAAAA&ccb=7-5&oh=00_AfsvBghJkIPr-6Tg34sElr5wVYnz4kXunkzZfQcCIUq_5A&oe=6990B0AD&_nc_sid=7a9f4b';
  String _profileImagePath = '';

  static const _categoryImages = <String, String>{
    'Yoga': 'assets/images/yoga.jpg',
    'Pilates': 'assets/images/pilates.jpg',
    'Weightlifting': 'assets/images/weightlifting.jpg',
    'Calisthenics': 'assets/images/Calisthenics.jpg',
    'Stretching & Mobility': 'assets/images/Stretching & Mobility.jpg',
  };

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path') ?? '';
    if (!mounted) return;
    setState(() => _profileImagePath = imagePath);
  }

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
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((label) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: AppButton(
                        label: label,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        backgroundColor: AppColors.primary,
                        borderRadius: 12,
                        fontWeight: FontWeight.w600,
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

  void _showNotificationsSheet(BuildContext context) {
    const notifications = [
      _NotificationData(
        title: 'Challenge completed',
        icon: Icons.emoji_events_outlined,
      ),
      _NotificationData(
        title: 'New task available',
        icon: Icons.task_alt_outlined,
      ),
      _NotificationData(
        title: 'You spent 2 hours today',
        icon: Icons.timer_outlined,
      ),
    ];

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: const Color(0x33000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textTitleFor(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...notifications.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimaryFor(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocalProfileImage =
        _profileImagePath.isNotEmpty && File(_profileImagePath).existsSync();
    final ImageProvider avatarImage = hasLocalProfileImage
        ? FileImage(File(_profileImagePath))
        : const NetworkImage(_defaultProfileImageUrl);

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    AnimatedReveal(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(hPadding, 36, hPadding, 28),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
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
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    await Get.toNamed(Routes.profile);
                                    await _loadProfileImage();
                                  },
                                  borderRadius: BorderRadius.circular(22),
                                  child: CircleAvatar(
                                    backgroundImage: avatarImage,
                                    radius: isDesktop ? 20 : 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _showNotificationsSheet(context),
                                  child: Container(
                                    width: isDesktop ? 40 : 36,
                                    height: isDesktop ? 40 : 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_none,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
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
                                      Expanded(
                                        child: Text(
                                          'Choose Random Challenge',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondaryFor(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => _showWorkoutPopup(context),
                                        child: const Icon(
                                          Icons.info_outline,
                                          size: 18,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  AppButton(
                                    label: 'Start Random Challenge',
                                    onPressed: () {},
                                    width: double.infinity,
                                    height: 44,
                                    backgroundColor: AppColors.primary,
                                    borderRadius: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedReveal(
                        delay: const Duration(milliseconds: 120),
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
                                          AppColors.transparentPrimary,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () {},
            child: const Icon(Icons.add, color: Colors.white),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Home'),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'View all',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedFor(context),
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
            colors: [Color(0xAA0F172A), AppColors.transparentPrimary],
          ),
        ),
        child: Center(
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationData {
  final String title;
  final IconData icon;

  const _NotificationData({required this.title, required this.icon});
}





