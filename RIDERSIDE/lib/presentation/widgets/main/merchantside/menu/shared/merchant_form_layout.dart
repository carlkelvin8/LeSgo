import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../global/home_header.dart';
import 'merchant_sticky_action_bar.dart';

/// Reusable form layout wrapper that handles scaffold, safe area, header, and form structure
/// Reduces boilerplate by ~25 lines per screen
class MerchantFormLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final Widget? stickyBottomAction;
  final Function(String)? onErrorMessage;

  const MerchantFormLayout({
    super.key,
    required this.formKey,
    required this.children,
    this.stickyBottomAction,
    this.onErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: ResponsiveUtils.spacing(context, 16),
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
            if (stickyBottomAction != null)
              MerchantStickyActionBar(child: stickyBottomAction!),
          ],
        ),
      ),
    );
  }
}
