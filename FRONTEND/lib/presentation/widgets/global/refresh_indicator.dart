import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.accent(context, Color(0xFF6B4CE6)),
      backgroundColor: backgroundColor ?? AppColors.surface(context, Colors.white),
      strokeWidth: 2.5,
      displacement: 40.0,
      child: child,
    );
  }
}
