import 'package:lesgo/presentation/widgets/booking/common/order_design.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/responsive_utils.dart';

class BookingServiceHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final Widget? action;
  final bool orderStyle;

  const BookingServiceHeader({
    super.key,
    required this.title,
    this.onProfileTap,
    this.action,
    this.orderStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: orderStyle
          ? OrderDesign.canvas(context)
          : AppColors.surface(context, Colors.white),
      scrolledUnderElevation: orderStyle ? 0 : null,
      titleSpacing: orderStyle ? 2 : null,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          orderStyle ? Icons.arrow_back_rounded : Icons.arrow_back,
          color: AppColors.foreground(context, Colors.black),
        ),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, orderStyle ? 22 : 18),
          fontWeight: orderStyle ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.foreground(context, Colors.black),
        ),
      ),
      centerTitle: !orderStyle,
      actions: [
        if (action != null)
          action!
        else
          IconButton(
            icon: SvgPicture.asset(
              'assets/images/homepage/Profile.svg',
              width: 24,
              height: 24,
            ),
            onPressed:
                onProfileTap ??
                () => AppRouter.push(context, MainRoutes.profile),
          ),
        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
