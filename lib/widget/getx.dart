import 'package:fun_fit/authentication/change_password_screen.dart';
import 'package:get/get.dart';
import 'package:fun_fit/authentication/forgot_password_screen.dart';
import 'package:fun_fit/authentication/login_screen.dart';
import 'package:fun_fit/authentication/otp_purpos.dart';
import 'package:fun_fit/authentication/otp_verification.dart';
import 'package:fun_fit/home/profile_screen.dart';
import 'package:fun_fit/onboarding/age_selection_screen.dart';
import 'package:fun_fit/onboarding/fitness_lvl.dart';
import 'package:fun_fit/onboarding/gender_selection.dart';
import 'package:fun_fit/onboarding/goal_screen.dart';
import 'package:fun_fit/onboarding/height_measure.dart';
import 'package:fun_fit/onboarding/ready_screen.dart';
import 'package:fun_fit/onboarding/waight_measure.dart';
import 'package:fun_fit/screens/signup_screen.dart';
import 'package:fun_fit/screens/splash_screen.dart';
import 'package:fun_fit/settings/help_screen.dart';
import 'package:fun_fit/widget/app_shell_screen.dart';

class Routes {
  static const String splash = '/';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String changePassword = '/change-password';
  static const String otpForgotPassword = '/otp-forgot-password';
  static const String ready = '/ready';
  static const String gender = '/gender';
  static const String goal = '/goal';
  static const String fitnessLevel = '/fitness-level';
  static const String age = '/age';
  static const String height = '/height';
  static const String weight = '/weight';
  static const String home = '/home';
  static const String foodLogging = '/food-logging';
  static const String challenges = '/challenges';
  static const String profile = '/profile';
  static const String leaderboard = '/leaderboard';
  static const String guides = '/guides';
  static const String settings = '/settings';
  static const String help = '/help';

  static final pages = <GetPage>[
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: signup, page: () => const SignUpScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: changePassword, page: () => const ChangePasswordScreen()),
    GetPage(
      name: otpForgotPassword,
      page: () => const OtpScreen(purpose: OtpPurpose.forgotPassword),
    ),
    GetPage(name: ready, page: () => const AreYouReadyScreen()),
    GetPage(name: gender, page: () => const GenderSelectionScreen()),
    GetPage(name: goal, page: () => const GoalSelectionScreen()),
    GetPage(name: fitnessLevel, page: () => const FitnessLevelScreen()),
    GetPage(name: age, page: () => const AgeSelectionScreen()),
    GetPage(name: height, page: () => const HeightSelectionScreen()),
    GetPage(name: weight, page: () => const WeightSelectionScreen()),
    // App shell entry points by tab index.
    GetPage(name: home, page: () => const AppShellScreen(initialIndex: 0)),
    GetPage(
      name: foodLogging,
      page: () => const AppShellScreen(initialIndex: 1),
    ),
    GetPage(
      name: challenges,
      page: () => const AppShellScreen(initialIndex: 2),
    ),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(
      name: leaderboard,
      page: () => const AppShellScreen(initialIndex: 3),
    ),
    GetPage(name: guides, page: () => const AppShellScreen(initialIndex: 4)),
    GetPage(name: settings, page: () => const AppShellScreen(initialIndex: 5)),
    GetPage(name: help, page: () => const HelpScreen()),
  ];
}
