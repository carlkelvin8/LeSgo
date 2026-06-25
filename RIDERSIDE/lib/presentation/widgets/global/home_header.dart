import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class HomeHeader extends ConsumerWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final Color logoColor;
  final Color borderColor;
  final Color? backIconColor;
  final Widget? action;

  const HomeHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.backgroundColor = Colors.white,
    this.logoColor = const Color(0xFF5F2D82),
    this.borderColor = const Color(0xFFEEEEEE),
    this.backIconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: showBackButton || action != null
                ? ResponsiveUtils.spacing(context, 40)
                : 0,
            child: showBackButton
                ? GestureDetector(
                    onTap: onBack ?? () => Navigator.pop(context),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: ResponsiveUtils.imageHeight(context, 32),
                      color: backIconColor ?? const Color(0xFF5F2D82),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Center(
              child: SvgPicture.asset(
                'assets/images/Logo.svg',
                height: ResponsiveUtils.imageHeight(context, 40),
                colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(
            width: showBackButton || action != null
                ? ResponsiveUtils.spacing(context, 40)
                : 0,
            child: action,
          ),
        ],
      ),
    );
  }
}
