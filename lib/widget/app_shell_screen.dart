import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/challenges.dart';
import '../home/food_logging_screen.dart';
import '../home/guides_screen.dart';
import '../home/home_screen.dart';
import '../home/leaderboard_screen.dart';
import '../settings/settings_screen.dart';
import 'app_shell_controller.dart';

class AppShellScreen extends StatefulWidget {
  final int initialIndex;

  const AppShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late final AppShellController _controller;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _controller =
        AppShellController.maybeFind() ??
        Get.put(AppShellController(widget.initialIndex));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.setIndex(widget.initialIndex);
    });

    _pages = const <Widget>[
      HomeScreen(),
      FoodLoggingScreen(),
      ChallengesScreen(),
      LeaderboardScreen(),
      GuidesScreen(),
      SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = _controller.currentIndex.value;
      return PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (index != 0) _controller.setIndex(0);
        },
        child: IndexedStack(
          index: index,
          children: _pages,
        ),
      );
    });
  }
}
