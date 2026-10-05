import 'package:flutter/material.dart';
import '../../../core/utils/utils.dart';
import '../../widgets/widgets.dart';

/// Shared terms presentation based on the original Rider registration screen.
class RegistrationTermsScreen extends StatefulWidget {
  final VoidCallback onAccepted;
  final Widget content;
  const RegistrationTermsScreen({
    super.key,
    required this.onAccepted,
    this.content = const TermsScrollableContent(),
  });

  @override
  State<RegistrationTermsScreen> createState() =>
      _RegistrationTermsScreenState();
}

class _RegistrationTermsScreenState extends State<RegistrationTermsScreen> {
  bool termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),

              TopBar(
                title: 'Register',
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 24)),

              const TermsHeader(),

              SizedBox(height: ResponsiveUtils.spacing(context, 20)),

              Expanded(child: widget.content),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              TermsAcceptanceCheckbox(
                value: termsAccepted,
                onChanged: (value) =>
                    setState(() => termsAccepted = value ?? false),
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 16)),

              PrimaryButton(
                text: 'Continue',
                onPressed: termsAccepted ? widget.onAccepted : null,
              ),

              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            ],
          ),
        ),
      ),
    );
  }
}
