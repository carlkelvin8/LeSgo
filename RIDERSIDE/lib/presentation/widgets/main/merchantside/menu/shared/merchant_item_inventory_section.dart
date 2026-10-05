import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import 'merchant_live_on_menu_toggle_section.dart';

class MerchantItemInventorySection extends StatelessWidget {
  final bool trackStock;
  final int stock;
  final bool autoHideWhenEmpty;
  final bool liveOnMenu;
  final ValueChanged<bool> onTrackStockChanged;
  final ValueChanged<int> onStockChanged;
  final ValueChanged<bool> onAutoHideChanged;
  final ValueChanged<bool> onLiveOnMenuChanged;

  const MerchantItemInventorySection({
    super.key,
    required this.trackStock,
    required this.stock,
    required this.autoHideWhenEmpty,
    required this.liveOnMenu,
    required this.onTrackStockChanged,
    required this.onStockChanged,
    required this.onAutoHideChanged,
    required this.onLiveOnMenuChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 10)),
        Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Track stock',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Monitor quantity and auto-hide when sold out',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.grey.shade600,
                  ),
                ),
                value: trackStock,
                onChanged: onTrackStockChanged,
                activeThumbColor: const Color(0xFF5F2D82),
              ),
              if (trackStock) ...[
                const Divider(height: 1),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stock quantity',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: stock > 0
                          ? () => onStockChanged(stock - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFF5F2D82),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '$stock',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 16),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onStockChanged(stock + 1),
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFF5F2D82),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Auto-hide when sold out',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Sets item unavailable for customers at 0 stock',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: autoHideWhenEmpty,
                  onChanged: onAutoHideChanged,
                  activeThumbColor: const Color(0xFF5F2D82),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        MerchantLiveOnMenuToggleSection(
          isLive: liveOnMenu,
          onChanged: onLiveOnMenuChanged,
        ),
      ],
    );
  }
}
