import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators/lespay_validator.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import '../../screens/main/lespay/xendit_payment_screen.dart';
import 'top_up_fee_summary.dart';

class TopUpDialog extends ConsumerStatefulWidget {
  /// Scaffold context from LesPay screen (stays valid after dialog closes).
  final BuildContext parentContext;

  const TopUpDialog({super.key, required this.parentContext});

  @override
  ConsumerState<TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends ConsumerState<TopUpDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  static const _quickAmounts = [100.0, 200.0, 500.0, 1000.0];

  double get _parsedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startTopUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amountController.text.trim());
    final rootNav = Navigator.of(context, rootNavigator: true);

    final checkout =
        await ref.read(lespayProvider.notifier).startXenditTopUp(amount);

    if (!mounted) return;

    if (checkout == null) {
      final error = ref.read(lespayProvider).error;
      SnackBarUtils.showError(
        context,
        error ?? 'Could not start top-up. Please try again.',
      );
      return;
    }

    // Close dialog first, then open Xendit checkout on root navigator.
    rootNav.pop();

    final paid = await rootNav.push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => XenditPaymentScreen(checkout: checkout),
      ),
    );

    if (paid == true) {
      ref.read(lespayProvider.notifier).refreshBalance();
      if (widget.parentContext.mounted) {
        SnackBarUtils.showSuccess(
          widget.parentContext,
          '₱${amount.toStringAsFixed(2)} added to your wallet!',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lespayState = ref.watch(lespayProvider);

    return AlertDialog(
      title: Text(
        'Top Up (3% fee)',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 18),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A 3% top-up fee applies. You pay the total below using GCash, Maya, or cards.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            TextFormField(
              controller: _amountController,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount to add to wallet',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
              validator: LespayValidator.topUpAmount,
              enabled: !lespayState.isProcessingTopUp,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            TopUpFeeSummary(walletAmount: _parsedAmount),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts.map((value) {
                return ChoiceChip(
                  label: Text('₱${value.toStringAsFixed(0)}'),
                  selected: _amountController.text == value.toStringAsFixed(0),
                  onSelected: lespayState.isProcessingTopUp
                      ? null
                      : (_) {
                          setState(() {
                            _amountController.text = value.toStringAsFixed(0);
                          });
                        },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: lespayState.isProcessingTopUp
              ? null
              : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: Colors.grey[600],
              fontSize: ResponsiveUtils.fontSize(context, 14),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: lespayState.isProcessingTopUp ? null : _startTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            foregroundColor: Colors.white,
          ),
          child: lespayState.isProcessingTopUp
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Continue to payment',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
        ),
      ],
    );
  }
}
