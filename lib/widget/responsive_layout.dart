import 'dart:math' as math;

import 'package:flutter/material.dart';

class ResponsiveInfo {
  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;

  final double width;
  final double height;

  const ResponsiveInfo._({
    required this.width,
    required this.height,
  });

  factory ResponsiveInfo.fromConstraints(BoxConstraints constraints) {
    return ResponsiveInfo._(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
    );
  }

  factory ResponsiveInfo.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveInfo._(
      width: size.width,
      height: size.height,
    );
  }

  bool get isDesktop => width >= desktopBreakpoint;
  bool get isTablet => width >= tabletBreakpoint && width < desktopBreakpoint;
  bool get isMobile => width < tabletBreakpoint;

  double value({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  double maxWidth({
    double mobile = 420,
    double tablet = 520,
    double desktop = 640,
  }) {
    return math.min(
      width,
      value(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }

  EdgeInsets pagePadding({
    double mobileHorizontal = 16,
    double tabletHorizontal = 24,
    double desktopHorizontal = 32,
    double mobileVertical = 16,
    double tabletVertical = 24,
    double desktopVertical = 28,
  }) {
    return EdgeInsets.symmetric(
      horizontal: value(
        mobile: mobileHorizontal,
        tablet: tabletHorizontal,
        desktop: desktopHorizontal,
      ),
      vertical: value(
        mobile: mobileVertical,
        tablet: tabletVertical,
        desktop: desktopVertical,
      ),
    );
  }
}

class ResponsiveContent extends StatelessWidget {
  final ResponsiveInfo info;
  final Widget child;
  final double mobileMaxWidth;
  final double tabletMaxWidth;
  final double desktopMaxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContent({
    required this.info,
    required this.child,
    this.mobileMaxWidth = 420,
    this.tabletMaxWidth = 520,
    this.desktopMaxWidth = 640,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: info.maxWidth(
            mobile: mobileMaxWidth,
            tablet: tabletMaxWidth,
            desktop: desktopMaxWidth,
          ),
        ),
        child: Padding(
          padding: padding ?? info.pagePadding(),
          child: child,
        ),
      ),
    );
  }
}
