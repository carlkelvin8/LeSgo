import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/rider_payment_utils.dart';

Future<bool> showRiderCodConfirmDialog(
  BuildContext context, {
  required String amountLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm cash collection',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${RiderPaymentUtils.formatCollectionLabel(amountLabel)}\n\n'
          'Only confirm after you have received the cash from the customer.',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cash collected'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
