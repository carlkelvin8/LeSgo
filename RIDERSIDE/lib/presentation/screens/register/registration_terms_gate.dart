import 'package:flutter/material.dart';

/// Consent belongs to this registration visit. Returning to terms revokes it,
/// while the owning form retains its draft fields and uploaded documents.
class RegistrationTermsGate extends StatefulWidget {
  final Widget Function(VoidCallback accept) termsBuilder;
  final Widget Function(VoidCallback reviewTerms) formBuilder;
  final ValueChanged<bool> onConsentChanged;
  final bool isSubmitting;

  const RegistrationTermsGate({
    super.key,
    required this.termsBuilder,
    required this.formBuilder,
    required this.onConsentChanged,
    this.isSubmitting = false,
  });

  @override
  State<RegistrationTermsGate> createState() => _RegistrationTermsGateState();
}

class _RegistrationTermsGateState extends State<RegistrationTermsGate> {
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onConsentChanged(false);
    });
  }

  void _setConsent(bool accepted) {
    ScaffoldMessenger.of(context).clearSnackBars();
    widget.onConsentChanged(accepted);
    setState(() => _accepted = accepted);
  }

  void _reviewTerms() {
    if (!widget.isSubmitting) _setConsent(false);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_accepted,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) {
        widget.onConsentChanged(false);
      } else {
        _reviewTerms();
      }
    },
    child: _accepted
        ? widget.formBuilder(_reviewTerms)
        : widget.termsBuilder(() => _setConsent(true)),
  );
}
