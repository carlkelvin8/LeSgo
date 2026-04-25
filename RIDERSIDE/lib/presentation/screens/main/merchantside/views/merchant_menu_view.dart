import 'package:flutter/material.dart';
import '../../../../../core/utils/helpers/fakedata.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';
import '../merchant_menu_edit_item_screen.dart';

class MerchantMenuView extends StatelessWidget {
  const MerchantMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Food Category',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...merchantFoodCategories.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      right: ResponsiveUtils.spacing(context, 10),
                    ),
                    child: MerchantFoodCategoryChip(
                      label: entry.value['label']!,
                      icon: entry.value['icon']!,
                      isSelected: entry.key == 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          const Divider(height: 1, color: Color(0xFFE4E4E7)),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            'Food Menu',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 14)),
              itemCount: merchantFoodMenuItems.length,
              itemBuilder: (context, index) {
                final item = merchantFoodMenuItems[index];
                return MerchantMenuItemCard(
                  name: item['name']!,
                  description: item['description']!,
                  price: item['price']!,
                  category: item['category'],
                  onEditTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MerchantMenuEditItemScreen(
                          initialItem: item,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
