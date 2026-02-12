import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/app_colors.dart';
import '../widget/app_button.dart';
import '../widget/home_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _defaultName = 'Hassan Raza';
  static const String _defaultProfileImageUrl =
      'https://instagram.fbhv1-1.fna.fbcdn.net/v/t51.2885-19/472294191_1105393394457686_554111962204078586_n.jpg?efg=eyJ2ZW5jb2RlX3RhZyI6InByb2ZpbGVfcGljLmRqYW5nby4xMDgwLmMyIn0&_nc_ht=instagram.fbhv1-1.fna.fbcdn.net&_nc_cat=102&_nc_oc=Q6cZ2QFPco5nXp9cXZCormOpxSR_IStByEK7TtzKIix18azp0fhLpjo-OmRwB5YRM2MgfBk&_nc_ohc=43gHM-x_W18Q7kNvwELfwN1&_nc_gid=TYaa_VlHXwocm-WkhQhxgQ&edm=AP4sbd4BAAAA&ccb=7-5&oh=00_AfsvBghJkIPr-6Tg34sElr5wVYnz4kXunkzZfQcCIUq_5A&oe=6990B0AD&_nc_sid=7a9f4b';

  final ImagePicker _imagePicker = ImagePicker();
  bool _loading = true;
  String _savedName = '';
  String _profileImagePath = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
      );
      final name = prefs.getString('profile_name') ?? '';
      final imagePath = prefs.getString('profile_image_path') ?? '';
      if (!mounted) return;
      setState(() {
        _savedName = name;
        _profileImagePath = imagePath;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveName(String value) async {
    final name = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', name);
    if (!mounted) return;
    setState(() => _savedName = name);
  }

  Future<void> _pickProfileImage() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', file.path);
    setState(() => _profileImagePath = file.path);
  }

  Future<void> _showNameEditDialog() async {
    final controller = TextEditingController(
      text: _savedName.isEmpty ? _defaultName : _savedName,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(controller.text),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _saveName(result);
  }

  void _showNotificationsSheet() {
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
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTitle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...notifications.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.appBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(item.icon, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
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
    final displayName = _savedName.isEmpty ? _defaultName : _savedName;
    final ImageProvider profileImage = _profileImagePath.isNotEmpty
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

        return Scaffold(
          backgroundColor: AppColors.appBackground,
          body: SafeArea(top: false, bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    _WelcomeHeader(
                      name: displayName,
                      imageProvider: profileImage,
                      onNameTap: _showNameEditDialog,
                      onImageTap: _pickProfileImage,
                      onNotificationTap: _showNotificationsSheet,
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: EdgeInsets.fromLTRB(
                                hPadding,
                                20,
                                hPadding,
                                24,
                              ),
                              children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Current Challenges',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 12),
                              _ChallengeTile(
                                title: 'Push Up',
                                subtitle: '100 Push up a day',
                                time: '5:00 min',
                                progress: 0.45,
                                imagePath: 'assets/images/pushup.jpg',
                              ),
                              _ChallengeTile(
                                title: 'Sit Up',
                                subtitle: '20 Sit up a day',
                                time: '4:30 min',
                                progress: 0.70,
                                imagePath: 'assets/images/situp.jpg',
                              ),
                              _ChallengeTile(
                                title: 'Knee Push Up',
                                subtitle: '20 Sit up a day',
                                time: '3:00 min',
                                progress: 0.35,
                                imagePath: 'assets/images/knee pushup.jpg',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Recommended Meal',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/nutbutter.jpg',
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomLeft,
                                      end: Alignment.topRight,
                                      colors: [
                                        Color(0xAA0F172A),
                                        Color(0x000F172A),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                left: 16,
                                bottom: 16,
                                child: Text(
                                  'Nut Butter Toast With Boiled Eggs',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
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
            backgroundColor: AppColors.primary,
            onPressed: () {},
            child: const Icon(Icons.add, color: AppColors.white),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: ''),
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String name;
  final ImageProvider imageProvider;
  final VoidCallback onNameTap;
  final VoidCallback onImageTap;
  final VoidCallback onNotificationTap;

  const _WelcomeHeader({
    required this.name,
    required this.imageProvider,
    required this.onNameTap,
    required this.onImageTap,
    required this.onNotificationTap,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onNameTap,
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onImageTap,
            child: CircleAvatar(radius: 18, backgroundImage: imageProvider),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onNotificationTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_none,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationData {
  final String title;
  final IconData icon;

  const _NotificationData({required this.title, required this.icon});
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
              const Icon(Icons.sync, size: 16, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
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





