import 'package:flutter/material.dart';
import '../../../core/utils/utils.dart';
import 'top_bar.dart';

/// A shared scaffold layout used across registration screens.
/// Provides: white background, SafeArea, sticky TopBar header,
/// and a scrollable content area.
class RegisterScaffold extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget body;
  final Widget? bottomWidget;
  final double headerBottomSpacing;

  const RegisterScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBackPressed,
    this.bottomWidget,
    this.headerBottomSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: ResponsiveUtils.spacing(context, 20),
                  ),
                  TopBar(
                    title: title,
                    onBackPressed: onBackPressed ??
                        () => Navigator.of(context).pop(),
                  ),
                  if (headerBottomSpacing > 0)
                    SizedBox(
                      height: ResponsiveUtils.spacing(
                        context,
                        headerBottomSpacing,
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: body,
              ),
            ),

            // Optional Sticky Bottom Widget
            if (bottomWidget != null)
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: bottomWidget,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
