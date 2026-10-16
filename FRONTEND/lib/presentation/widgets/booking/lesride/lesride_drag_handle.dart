import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';

class LesrideDragHandle extends StatelessWidget {
  const LesrideDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
        decoration: BoxDecoration(
          color: AppColors.border(context, Colors.grey.shade300),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
