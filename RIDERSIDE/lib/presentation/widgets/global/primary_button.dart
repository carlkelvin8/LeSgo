import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final double? width;
  final double? fontSize;
  final bool fitText;
  final String? semanticsLabel;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.width,
    this.fontSize,
    this.fitText = false,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.spacing(context, 52);
    final borderRadius = BorderRadius.circular(
      ResponsiveUtils.spacing(context, 12),
    );

    return Semantics(
      button: true,
      enabled: !isLoading && onPressed != null,
      label: semanticsLabel ?? text,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width ?? double.infinity,
          height: buttonHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient:
                  gradient ??
                  (backgroundColor == null
                      ? const LinearGradient(
                          colors: [Color(0xFF9B59F0), Color(0xFF5F2D82)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null),
              color: backgroundColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: (backgroundColor ?? const Color(0xFF5F2D82)).withValues(
                    alpha: 0.3,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: MaterialButton(
              onPressed: isLoading ? null : onPressed,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: EdgeInsets.zero,
              child: isLoading
                  ? SizedBox(
                      height: ResponsiveUtils.spacing(context, 22),
                      width: ResponsiveUtils.spacing(context, 22),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: textColor,
                      ),
                    )
                  : _buildLabel(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    final label = Text(
      text,
      maxLines: 1,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, fontSize ?? 16),
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.3,
      ),
    );

    if (!fitText) return label;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 8),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: label,
      ),
    );
  }
}
