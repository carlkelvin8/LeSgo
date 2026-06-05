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

  const BookingServiceHeader({
    super.key,
    required this.title,
    this.onProfileTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 18),
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
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
