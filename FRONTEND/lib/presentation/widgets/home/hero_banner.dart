import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';

class HeroBanner extends StatefulWidget {
  final String userName;
  final bool showGreeting;
  final String backgroundImagePath;
  final String title;
  final String subtitle;
  final VoidCallback? onBookNowPressed;

  const HeroBanner({
    super.key,
    required this.userName,
    this.showGreeting = true,
    required this.backgroundImagePath,
    required this.title,
    required this.subtitle,
    this.onBookNowPressed,
  });

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Faster pulse
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      // Bigger pulse
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.spacing(context, 16.0);
    final bannerHeight = ResponsiveUtils.imageHeight(context, 220);
    final borderRadius = ResponsiveUtils.spacing(context, 16);
    final fontSize22 = ResponsiveUtils.fontSize(context, 22);
    final fontSize12 = ResponsiveUtils.fontSize(context, 12);
    final isSvg = widget.backgroundImagePath.toLowerCase().endsWith('.svg');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: bannerHeight),
          child: Stack(
            children: [
              Positioned.fill(
                child: isSvg
                    ? SvgPicture.asset(
                        widget.backgroundImagePath,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        widget.backgroundImagePath,
                        fit: BoxFit.cover,
                      ),
              ),
              // Keep text readable while letting the artwork show through.
              if (isDark || !isSvg)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: isDark ? const [0.0, 0.5, 1.0] : null,
                        colors: isDark
                            ? [
                                surface.withValues(alpha: 0.88),
                                surface.withValues(alpha: 0.78),
                                surface.withValues(alpha: 0.25),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.85),
                                const Color(0xFFF5EEFF).withValues(alpha: 0.7),
                              ],
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.fromLTRB(ResponsiveUtils.spacing(context, 20), 20,
                    ResponsiveUtils.spacing(context, 64), 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.showGreeting) ...[
                      Text(
                        'Hello, ${widget.userName}!',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: fontSize22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground(context, Color(0xFF30213D)), // Dark purple text (matching profile)
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    ],
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground(context, Color(0xFF30213D)), // Dark purple text
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: AppColors.foreground(context, Color(0xFF57515E)), // Gray text (matching profile subtitle)
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                    // Animated BOOK NOW button
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) {
                        setState(() => _isPressed = false);
                        widget.onBookNowPressed?.call();
                      },
                      onTapCancel: () => setState(() => _isPressed = false),
                      child: AnimatedScale(
                        scale: _isPressed ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeInOut,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.spacing(context, 8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFFA930D0,
                                  ).withValues(alpha: 0.4),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: const Color(0xFFA930D0),
                              borderRadius: BorderRadius.circular(
                                ResponsiveUtils.spacing(context, 8),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.spacing(
                                    context,
                                    24,
                                  ),
                                  vertical: ResponsiveUtils.spacing(
                                    context,
                                    12,
                                  ),
                                ),
                                child: Text(
                                  'Book now',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontWeight: FontWeight.w600,
                                    fontSize: fontSize12,
                                    letterSpacing: 0.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
