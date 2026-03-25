import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fun_fit/services/auth_session_storage.dart';
import 'package:fun_fit/widget/getx.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/responsive_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _kHasOpenedApp = 'has_opened_app';
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 3), _navigateFromSplash);
  }

  Future<void> _navigateFromSplash() async {
    final alreadyLoggedIn = await AuthSessionStorage.isLoggedIn();
    if (!mounted) return;
    if (alreadyLoggedIn) {
      Get.offNamed(Routes.home);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasOpenedBefore = prefs.getBool(_kHasOpenedApp) ?? false;
    if (!mounted) return;

    if (hasOpenedBefore) {
      Get.offNamed(Routes.login);
      return;
    }

    await prefs.setBool(_kHasOpenedApp, true);
    Get.offNamed(Routes.signup);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.fromConstraints(constraints);
        final logoSize = info.value(mobile: 82, tablet: 96, desktop: 110);
        final textSize = info.value(mobile: 36, tablet: 46, desktop: 54);
        final loaderSize = info.value(mobile: 24, tablet: 28, desktop: 32);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: logoSize,
                            color: Colors.white,
                          ),
                          SizedBox(
                            height: info.value(
                              mobile: 12,
                              tablet: 16,
                              desktop: 18,
                            ),
                          ),
                          Text(
                            'ModivFit',
                            style: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: info.value(mobile: 28, tablet: 36, desktop: 42),
                ),
                child: SizedBox(
                  width: loaderSize,
                  height: loaderSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
