import 'package:get/get.dart';
import 'package:fun_fit/authentication/forgot_password_screen.dart';
import 'package:fun_fit/authentication/login_screen.dart';
import 'package:fun_fit/authentication/login_success.dart';
import 'package:fun_fit/authentication/otp_verification.dart';
import 'package:fun_fit/authentication/otp_purpos.dart';
import 'package:fun_fit/onboarding/age_selection_screen.dart';
import 'package:fun_fit/onboarding/fitness_lvl.dart';
import 'package:fun_fit/onboarding/gender_selection.dart';
import 'package:fun_fit/onboarding/goal_screen.dart';
import 'package:fun_fit/onboarding/height_measure.dart';
import 'package:fun_fit/onboarding/ready_screen.dart';
import 'package:fun_fit/onboarding/waight_measure.dart';
import 'package:fun_fit/home/food_logging_screen.dart';
import 'package:fun_fit/home/challenges.dart';
import 'package:fun_fit/home/home_screen.dart';
import 'package:fun_fit/screens/registration_screen.dart';
import 'package:fun_fit/screens/signup_screen.dart';
import 'package:fun_fit/screens/splash_screen.dart';

class Routes {
  static const String splash = '/';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpSignup = '/otp-signup';
  static const String otpForgotPassword = '/otp-forgot-password';
  static const String otpSignin = '/otp-signin';
  static const String registrationSuccess = '/registration-success';
  static const String passwordResetSuccess = '/password-reset-success';
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

  static final pages = <GetPage>[
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: signup, page: () => const SignUpScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    // We reuse OtpScreen but differentiate by route name + purpose
    GetPage(
      name: otpSignup,
      page: () => const OtpScreen(purpose: OtpPurpose.signup),
    ),
    GetPage(
      name: otpForgotPassword,
      page: () => const OtpScreen(purpose: OtpPurpose.forgotPassword),
    ),
    GetPage(
      name: otpSignin,
      page: () => const OtpScreen(purpose: OtpPurpose.signin),
    ),
    GetPage(
      name: registrationSuccess,
      page: () => const RegistrationSuccessScreen(),
    ),
    GetPage(
      name: passwordResetSuccess,
      page: () => const PasswordResetSuccessScreen(),
    ),
    GetPage(name: ready, page: () => const AreYouReadyScreen()),
    GetPage(name: gender, page: () => const GenderSelectionScreen()),
    GetPage(name: goal, page: () => const GoalSelectionScreen()),
    GetPage(name: fitnessLevel, page: () => const FitnessLevelScreen()),
    GetPage(name: age, page: () => const AgeSelectionScreen()),
    GetPage(name: height, page: () => const HeightSelectionScreen()),
    GetPage(name: weight, page: () => const WeightSelectionScreen()),
    // Home route placeholder – you can point it to your real home screen later
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: foodLogging, page: () => const FoodLoggingScreen()),
    GetPage(name: challenges, page: () => const ChallengesScreen()),
  ];
}
