import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Makes empty content refreshable, including when it is shorter than the page.
class RefreshableEmptyState extends StatelessWidget {
  const RefreshableEmptyState({
    super.key,
    required this.onRefresh,
    required this.child,
  });
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => RefreshIndicator(
      color: AppColors.accent(context, Color(0xFF5F2D82)),
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    ),
  );
}
