import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class LesrideLocationTile extends StatelessWidget {
  const LesrideLocationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, const Color(0xFFF7F7F7)),
        borderRadius: BorderRadius.circular(12),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Theme.of(context).colorScheme.outlineVariant)
            : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 4)),
              SizedBox(
                width: 180,
                child: Row(
                  children: [
                    if (isLoading) ...[
                      MapLoadingIndicator(
                        size: ResponsiveUtils.fontSize(context, 16),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: AppColors.foreground(context, Colors.grey[800]!),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}
