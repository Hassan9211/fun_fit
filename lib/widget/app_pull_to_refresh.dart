import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double edgeOffset;
  final Color? color;
  final Color? backgroundColor;

  const AppPullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.edgeOffset = 0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      edgeOffset: edgeOffset,
      color: color ?? AppColors.primary,
      backgroundColor: backgroundColor ?? AppColors.white,
      child: child,
    );
  }
}
