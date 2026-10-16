import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/api_error_mapper.dart';

class RetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isLoading;
  final String actionLabel;
  final IconData actionIcon;

  const RetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.isLoading = false,
    this.actionLabel = 'Try Again',
    this.actionIcon = Icons.refresh,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final content = Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context, const Color(0xFFF0E7F6)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, size: 32, color: Color(0xFF5F2D82)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Let’s try that again',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'TT Fors', fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  ApiErrorMapper.message(message),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'TT Fors', fontSize: 14, height: 1.5,
                      color: AppColors.foreground(context, Colors.grey[600]!)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isLoading ? null : onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(actionIcon),
                  label: Text(isLoading ? 'Retrying…' : actionLabel),
                ),
              ],
            ),
          ),
        ),
      );
      if (!constraints.hasBoundedHeight) return content;
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: content,
        ),
      );
    },
  );
}
