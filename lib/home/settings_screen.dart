import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/app_colors.dart';
import '../widget/getx.dart';
import '../widget/home_bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          backgroundColor: AppColors.appBackground,
          body: SafeArea(top: false, bottom: false,
            child: Center(
              child: SizedBox(
                width: contentMaxWidth,
                child: Column(
                  children: [
                    _SettingsHeader(onBackTap: () => Get.offNamed(Routes.home)),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          hPadding,
                          16,
                          hPadding,
                          24,
                        ),
                        children: [
                          _SettingsActionTile(
                            label: 'Change Password',
                            icon: Icons.edit_outlined,
                            onTap: () => Get.toNamed(
                              Routes.forgotPassword,
                              arguments: {'asChangePassword': true},
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsActionTile(
                            label: 'Logout',
                            icon: Icons.logout,
                            onTap: () => _showLogoutDialog(context),
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
            backgroundColor: AppColors.white,
            onPressed: () {},
            child: const Icon(Icons.add, color: Colors.black),
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
  final VoidCallback onBackTap;

  const _SettingsHeader({required this.onBackTap});

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
              onPressed: onBackTap,
            ),
          ),
          const SizedBox(width: 12),
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

  const _SettingsActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
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
              Icon(icon, color: AppColors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}





