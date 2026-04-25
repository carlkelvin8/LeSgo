import 'package:flutter/material.dart';
import '../../../../../core/utils/helpers/fakedata.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';
import '../../food_detail_screen.dart';

List<String> _parseSizes(String? rawSizes) {
  if (rawSizes == null || rawSizes.trim().isEmpty) {
    return const ['Regular'];
  }

  return rawSizes
      .split(',')
      .map((size) => size.trim())
      .where((size) => size.isNotEmpty)
      .toList();
}

class MerchantBookView extends StatelessWidget {
  const MerchantBookView({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 12),
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
          SizedBox(height: ResponsiveUtils.spacing(context, 10)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...merchantFoodCategories.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      right: ResponsiveUtils.spacing(context, 8),
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
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 16)),
              itemCount: merchantFoodMenuItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: ResponsiveUtils.spacing(context, 14),
                crossAxisSpacing: ResponsiveUtils.spacing(context, 8),
                childAspectRatio: 0.66,
              ),
              itemBuilder: (context, index) {
                final item = merchantFoodMenuItems[index];
                return MerchantFoodGridItem(
                  name: item['name']!,
                  imagePath: item['imagePath'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(
                          foodName: item['name']!,
                          foodImage: item['imagePath'],
                          price: 'PHP ${item['price']!}',
                          description: item['description']!,
                          sizes: _parseSizes(item['sizes']),
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
