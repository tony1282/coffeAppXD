import 'package:flutter/material.dart';

class Responsive {
  const Responsive._();

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static bool isMobile(BuildContext context) => width(context) < 600;

  static bool isTablet(BuildContext context) =>
      width(context) >= 600 && width(context) < 900;

  static bool isDesktop(BuildContext context) => width(context) >= 900;

  static double scale(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 1.05,
    double desktop = 1.1,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: horizontalPadding(context));
  }

  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }

  static double spacing(
    BuildContext context, {
    double mobile = 16,
    double tablet = 24,
    double desktop = 32,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
