import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../provider/auth/rider_auth_provider.dart';

/// Duplicates a menu item with " (Copy)" appended to the name.
Future<bool> duplicateMerchantMenuItem(
  BuildContext context,
  WidgetRef ref, {
  required MenuItemDto item,
}) async {
  final authState = ref.read(riderAuthProvider);
  final partnerId = authState.user?.partnerId;
  if (partnerId == null) {
    if (context.mounted) {
      SnackBarUtils.showError(context, 'No partner ID found');
    }
    return false;
  }

  try {
    final dataSource = ref.read(merchantDataSourceProvider);
    final request = CreateMenuItemRequest(
      menuCategoryId: item.menuCategoryId,
      name: '${item.name} (Copy)',
      description: item.description,
      price: item.price,
      imageUrl: item.imageUrl,
      isAvailable: item.isAvailable,
      stockCount: item.stockCount,
    );

    await dataSource.createMenuItem(partnerId, request);

    // Refresh menu
    ref.invalidate(merchantMenuProvider);
    ref.invalidate(merchantMenuItemsProvider);

    if (!context.mounted) return true;
    SnackBarUtils.showSuccess(context, 'Item duplicated successfully');
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    SnackBarUtils.showError(
      context,
      'Failed to duplicate: ${e.toString().replaceFirst('Exception: ', '')}',
    );
    return false;
  }
}
