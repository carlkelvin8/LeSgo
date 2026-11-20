import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class LocationHeader extends StatelessWidget {
  final String location;
  final VoidCallback? onMenuTap;
  final VoidCallback? onSupportTap;
  final VoidCallback? onLocationTap;

  /// Shows an Inbox button at the top-right of the header when set.
  final VoidCallback? onInboxTap;

  const LocationHeader({
    super.key,
    required this.location,
    this.onMenuTap,
    this.onSupportTap,
    this.onLocationTap,
    this.onInboxTap,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveUtils.spacing(context, 16.0);
    final fontSize12 = ResponsiveUtils.fontSize(context, 12);
    final fontSize14 = ResponsiveUtils.fontSize(context, 14);
    final iconSize = ResponsiveUtils.fontSize(context, 24);

    final editIconSize = ResponsiveUtils.fontSize(context, 14);
    // These SVGs are dark purple, which disappears on the dark background.
    // Light mode keeps the artwork's own colours.
    final iconTint = Theme.of(context).brightness == Brightness.dark
        ? ColorFilter.mode(
            AppColors.accent(context, const Color(0xFF5F2D82)),
            BlendMode.srcIn,
          )
        : null;

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onMenuTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.spacing(context, 12),
              ),
              child: SvgPicture.asset(
                'assets/images/homepage/Nav.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: iconTint,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: GestureDetector(
              onTap: onLocationTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveUtils.spacing(context, 6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/homepage/Location.svg',
                          width: ResponsiveUtils.fontSize(context, 14),
                          height: ResponsiveUtils.fontSize(context, 14),
                          colorFilter: iconTint,
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: fontSize12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: fontSize14,
                              color: AppColors.foreground(
                                context,
                                Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                        SvgPicture.asset(
                          'assets/images/homepage/Edit.svg',
                          width: editIconSize,
                          height: editIconSize,
                          colorFilter: iconTint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onInboxTap != null) ...[
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            _InboxButton(onTap: onInboxTap!),
          ],
        ],
      ),
    );
  }
}

/// Round Inbox shortcut for the top-right corner of the home header.
class _InboxButton extends StatelessWidget {
  const _InboxButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.fontSize(context, 44).clamp(44.0, 64.0);

    return Semantics(
      button: true,
      label: 'Inbox',
      child: GestureDetector(
        key: const ValueKey('home-inbox-button'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface(context, const Color(0xFFEEDDFD)),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA930D0).withValues(alpha: 0.18),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/images/homepage/Inbox.svg',
            width: size * 0.55,
            height: size * 0.55,
          ),
        ),
      ),
    );
  }
}
