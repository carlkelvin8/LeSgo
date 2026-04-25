import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import 'rider_duty_toggle.dart';

class RiderBookingsHeader extends StatelessWidget {
  const RiderBookingsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header illustration space
        SizedBox(
          height: ResponsiveUtils.imageHeight(context, 120),
          width: double.infinity,
          child: SvgPicture.asset(
            'assets/images/booking/banner.svg',
            fit: BoxFit.cover,
          ),
        ),
        // Duty Toggle Section
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 24),
            vertical: ResponsiveUtils.spacing(context, 16),
          ),
          child: const RiderDutyToggle(),
        ),
      ],
    );
  }
}
