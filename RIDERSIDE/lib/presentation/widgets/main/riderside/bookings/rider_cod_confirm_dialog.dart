import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/rider_payment_utils.dart';
import '../../../../../core/utils/app_localization.dart';

Future<bool> showRiderCodConfirmDialog(
  BuildContext context, {
  required String amountLabel,
}) async {
  final lang = ProviderScope.containerOf(context).read(appLanguageProvider);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalization.translate('confirm_cash_collection', lang),
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${RiderPaymentUtils.formatCollectionLabel(amountLabel)}\n\n'
              '${AppLocalization.translate('cod_confirm_hint', lang)}',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalization.translate('not_yet', lang)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalization.translate('cash_collected', lang)),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
