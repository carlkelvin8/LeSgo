import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

/// One row of the light side menu: a tinted icon, a label, and a soft
/// rounded press highlight.
class DrawerMenuItem extends StatelessWidget {
  final String? iconPath;

  /// Material icon used instead of [iconPath] when there is no SVG asset.
  final IconData? icon;
  final String title;
  final VoidCallback onTap;

  /// Optional small label on the right, e.g. "New".
  final String? badge;

  const DrawerMenuItem({
    super.key,
    this.iconPath,
    this.icon,
    required this.title,
    required this.onTap,
    this.badge,
  }) : assert(iconPath != null || icon != null);

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    final iconSize = ResponsiveUtils.fontSize(context, 22);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      child: Semantics(
        button: true,
        label: title,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: accent.withValues(alpha: 0.12),
            highlightColor: accent.withValues(alpha: 0.07),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: ResponsiveUtils.spacing(context, 11),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: icon != null
                        ? Icon(icon, color: accent, size: iconSize)
                        : SvgPicture.asset(
                            iconPath!,
                            width: iconSize,
                            height: iconSize,
                            colorFilter: ColorFilter.mode(
                              accent,
                              BlendMode.srcIn,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: AppColors.foreground(
                          context,
                          const Color(0xFF2A2032),
                        ),
                        fontSize: ResponsiveUtils.fontSize(context, 15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onAccent(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
