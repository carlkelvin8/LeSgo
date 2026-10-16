import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/lesbuy/store.dart';
import 'store_card.dart';

class StoreListSection extends StatelessWidget {
  final List<Store> stores;
  final Function(Store)? onStoreTap;

  const StoreListSection({
    super.key,
    required this.stores,
    this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_mall_directory,
              size: ResponsiveUtils.fontSize(context, 64),
              color: AppColors.foreground(context, Colors.grey[400]!),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              'No stores found',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                color: AppColors.foreground(context, Colors.grey[600]!),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return StoreCard(
          store: store,
          onTap: onStoreTap != null ? () => onStoreTap!(store) : null,
        );
      },
    );
  }
}
