import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:lesgo/core/theme/app_tokens.dart';

/// The one empty-state look: a soft tinted icon badge, a short title, an
/// optional helper line, and an optional action.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xxl,
          vertical: AppSpace.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 38, color: accent),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13.5,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
