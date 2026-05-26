import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators/lespay_validator.dart';
import '../../provider/main/lespay/lespay_provider.dart';

class WithdrawDialog extends StatefulWidget {
  const WithdrawDialog({super.key});

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final lespayState = ref.watch(lespayProvider);

        return AlertDialog(
          title: Text(
            'Withdraw',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available balance: Php ${lespayState.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'Php ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => LespayValidator.withdrawAmount(value, lespayState.balance),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
              onPressed: lespayState.isLoading
                  ? null
                  : () async {
                      if (!(_formKey.currentState?.validate() ?? false)) return;

                      final amount = double.parse(_amountController.text);
                      await ref.read(lespayProvider.notifier).withdraw(amount);

                      if (!context.mounted) return;
                      Navigator.of(context).pop();

                      final error = ref.read(lespayProvider).error;
                      if (error != null) {
                        SnackBarUtils.showError(context, error);
                      } else {
                        SnackBarUtils.showSuccess(
                          context,
                          'Withdrawal of Php ${amount.toStringAsFixed(2)} submitted.',
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Withdraw',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
