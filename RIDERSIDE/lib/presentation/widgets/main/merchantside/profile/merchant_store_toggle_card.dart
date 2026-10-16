import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_store_toggle_provider.dart';

/// A prominent card with a switch to open/close the merchant store.
class MerchantStoreToggleCard extends ConsumerWidget {
  const MerchantStoreToggleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(merchantIsOpenProvider);
    final toggleState = ref.watch(merchantStoreToggleProvider);
    final isLoading = toggleState is AsyncLoading;

    // Show error snackbar if toggle failed
    ref.listen<AsyncValue<void>>(merchantStoreToggleProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle store: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final open = isOpen ?? false;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 14),
      ),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFE8F5E9) : const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: open ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: open ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open ? 'Store is Open' : 'Store is Closed',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: open
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                Text(
                  open
                      ? 'Customers can see and order from your menu'
                      : 'Your store is hidden from customers',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: open,
              activeThumbColor: const Color(0xFF4CAF50),
              onChanged: (value) {
                ref
                    .read(merchantStoreToggleProvider.notifier)
                    .toggle(value);
              },
            ),
        ],
      ),
    );
  }
}
