import 'package:flutter/material.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import '../widget/app_colors.dart';
import '../widget/app_button.dart';

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        double paddingH = width * 0.06;
        double avatarRadius = (width * 0.1).clamp(40.0, 70.0);
        double iconSize = avatarRadius * 0.7;
        double textSizeTitle = width * 0.05;
        double textSizeDesc = width * 0.025;
        double buttonHeight = 50;

        if (width >= 1200) {
          paddingH = width * 0.25;
          textSizeTitle = width * 0.03;
          textSizeDesc = width * 0.02;
          buttonHeight = 55;
        } else if (width >= 800) {
          paddingH = width * 0.15;
          textSizeTitle = width * 0.04;
          textSizeDesc = width * 0.022;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: height * 0.03),

                  // Title
                  Text(
                    'Password Updated Successfully',
                    style: TextStyle(
                      fontSize: textSizeTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTitleFor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.015),

                  // Description
                  Text(
                    'Your password has been updated. Please change your password regularly to avoid security issues.',
                    style: TextStyle(
                      fontSize: textSizeDesc,
                      color: AppColors.textSecondaryFor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: height * 0.04),

                  // Continue button
                  AppButton(
                    label: 'Continue',
                    onPressed: () => Get.offAllNamed(Routes.login),
                    width: double.infinity,
                    height: buttonHeight,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: 8,
                    fontWeight: FontWeight.bold,
                  ),

                  SizedBox(height: height * 0.02),

                  // Back to Login
                  GestureDetector(
                    onTap: () => Get.offAllNamed(Routes.login),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: textSizeDesc,
                        color: AppColors.textTitleFor(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
