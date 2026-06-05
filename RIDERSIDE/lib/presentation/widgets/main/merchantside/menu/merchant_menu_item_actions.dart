import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../orders/merchant_order_dialogs.dart';

Future<bool> confirmAndDeleteMerchantMenuItem(
  BuildContext context,
  WidgetRef ref, {
  required int itemId,
  required String itemName,
}) async {
  final confirmed = await showMerchantConfirmDialog(
    context,
    title: 'Delete menu item',
    message: 'Delete "$itemName"? This cannot be undone.',
    confirmLabel: 'Delete',
  );
  if (!confirmed || !context.mounted) return false;

  try {
    await deleteMerchantMenuItem(ref, itemId);
    if (!context.mounted) return false;
    SnackBarUtils.showSuccess(context, 'Menu item deleted');
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    SnackBarUtils.showError(context, e.toString().replaceFirst('Exception: ', ''));
    return false;
  }
}
