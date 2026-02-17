import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/app_colors.dart';
import '../widget/animated_reveal.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';
import '../widget/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showThemeOptions(BuildContext context) async {
    final themeController = Get.find<ThemeController>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Obx(() {
            final isDark = themeController.isDarkMode;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Choose Theme',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.light_mode_outlined),
                  title: const Text('Light'),
                  trailing: Icon(
                    isDark
                        ? Icons.radio_button_unchecked
                        : Icons.check_circle,
                  ),
                  onTap: () async {
                    await themeController.setLightTheme();
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark'),
                  trailing: Icon(
                    isDark
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                  onTap: () async {
                    await themeController.setDarkTheme();
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 6),
              ],
            );
          }),
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = (prefs.getString('auth_email') ?? '').trim();
    final displayEmail = savedEmail.isEmpty ? 'No email found' : savedEmail;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: Text('Logged in as: $displayEmail'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await prefs.remove('auth_email');
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                Get.offAllNamed(Routes.login);
              },
              child: const Text('Logout'),
            ),
          ],
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
                    const AnimatedReveal(child: _SettingsHeader()),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          hPadding,
                          16,
                          hPadding,
                          24,
                        ),
                        children: [
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 70),
                            child: _SettingsActionTile(
                              label: 'Themes',
                              icon: Icons.palette_outlined,
                              onTap: () => _showThemeOptions(context),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 90),
                            child: _SettingsActionTile(
                              label: 'Change Password',
                              icon: Icons.edit_outlined,
                              onTap: () => Get.toNamed(
                                Routes.forgotPassword,
                                arguments: {'asChangePassword': true},
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedReveal(
                            delay: const Duration(milliseconds: 160),
                            child: _SettingsActionTile(
                              label: 'Logout',
                              icon: Icons.logout,
                              onTap: () => _showLogoutDialog(context),
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
            child: const Icon(Icons.add, color: Colors.white),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Settings'),
        );
      },
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 34),
          const Expanded(
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: TextStyle(
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

class _SettingsActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              trailing ?? Icon(icon, color: AppColors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
