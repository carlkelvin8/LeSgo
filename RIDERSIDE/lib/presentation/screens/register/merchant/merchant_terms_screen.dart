import 'package:flutter/material.dart';
import '../../../../core/constants/merchant_terms.dart';
import '../../../widgets/register/rider/terms_and_conditions/terms_scrollable_content.dart';
import '../registration_terms_screen.dart';

class MerchantTermsScreen extends StatelessWidget {
  final VoidCallback onAccepted;
  const MerchantTermsScreen({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context) => RegistrationTermsScreen(
    onAccepted: onAccepted,
    content: const TermsScrollableContent(content: MerchantTerms.content),
  );
}
