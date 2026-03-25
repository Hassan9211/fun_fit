import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fun_fit/settings/help_screen.dart';
import 'package:fun_fit/settings/language_preferences_screen.dart';
import 'package:fun_fit/settings/subscription_screen.dart';

import '../services/auth_session_storage.dart';
import '../widget/animated_reveal.dart';
import '../widget/app_colors.dart';
import '../widget/app_pull_to_refresh.dart';
import '../widget/app_section_header.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';
import '../widget/responsive_layout.dart';
import '../widget/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showThemeOptions(BuildContext context) async {
    final themeController = Get.find<ThemeController>();
    await showModalBottomSheet<void>(
      context: context,
      barrierColor: Colors.transparent,
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
                    isDark ? Icons.radio_button_unchecked : Icons.check_circle,
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
                    isDark ? Icons.check_circle : Icons.radio_button_unchecked,
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
    final savedEmail = await AuthSessionStorage.readEmail();
    final displayEmail = savedEmail.isEmpty ? 'No email found' : savedEmail;

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
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
                await AuthSessionStorage.clear();
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
        final info = ResponsiveInfo.fromConstraints(constraints);
        final contentMaxWidth = info.maxWidth(
          mobile: 400,
          tablet: 460,
          desktop: 520,
        );
        final isDark = AppColors.isDark(context);
        final avatarProvider = const AssetImage('assets/images/alina.jpg');
        Future<void> handleRefresh() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.cFF050505 : AppColors.cFF080808,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          body: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: Column(
                  children: [
                    AnimatedReveal(
                      child: AppSectionHeader(
                        title: 'Settings',
                        avatarProvider: avatarProvider,
                        onTapProfile: () {},
                        showAvatar: false,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cFF121212
                              : AppColors.cFFF2F2F2,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
                        child: AppPullToRefresh(
                          onRefresh: handleRefresh,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              info.value(mobile: 16, tablet: 18, desktop: 20),
                              16,
                              info.value(mobile: 16, tablet: 18, desktop: 20),
                              24,
                            ),
                            children: [
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 50),
                              child: _SettingsActionTile(
                                label: 'Profile Settings',
                                icon: Icons.edit_outlined,
                                onTap: () => Get.toNamed(Routes.profile),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 60),
                              child: _SettingsActionTile(
                                label: 'Subscription',
                                icon: Icons.edit_outlined,
                                onTap: () =>
                                    Get.to(() => const SubscriptionScreen()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 70),
                              child: _SettingsActionTile(
                                label: 'Change Fitness Level',
                                icon: Icons.edit_outlined,
                                onTap: () => Get.toNamed(Routes.fitnessLevel),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 90),
                              child: _SettingsActionTile(
                                label: 'Help',
                                icon: Icons.help_outline,
                                onTap: () => Get.to(() => const HelpScreen()),
                                trailing: const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 100),
                              child: _SettingsActionTile(
                                label: 'Language Preferences',
                                icon: Icons.edit_outlined,
                                onTap: () => Get.to(
                                  () => const LanguagePreferencesScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 110),
                              child: _SettingsActionTile(
                                label: 'Change Theme',
                                icon: Icons.edit_outlined,
                                onTap: () => _showThemeOptions(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedReveal(
                              delay: const Duration(milliseconds: 120),
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
                                trailing: const SizedBox.shrink(),
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: SizedBox(
            width: 42,
            height: 42,
            child: FloatingActionButton(
              backgroundColor:
                  isDark ? AppColors.cFF1E1E1E : Colors.white,
              elevation: 2,
              onPressed: () {},
              child: Icon(
                Icons.add,
                color: AppColors.textPrimaryFor(context),
                size: 20,
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: const HomeBottomNav(selected: 'Settings'),
        );
      },
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
