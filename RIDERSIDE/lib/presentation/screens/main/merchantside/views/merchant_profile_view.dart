import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/helpers/fakedata.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../../widgets/widgets.dart';
import '../merchant_edit_information_screen.dart';
import '../merchant_menu_edit_item_screen.dart';

class MerchantProfileView extends ConsumerWidget {
  const MerchantProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MerchantProfileHeader(),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          const MerchantProfileInfoSection(),
          SizedBox(
            height: ResponsiveUtils.spacing(context, 24),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MerchantEditInformationScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFE5E5E5),
                foregroundColor: const Color(0xFF9A9A9A),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.spacing(context, 16),
                  ),
                ),
              ),
              child: Text(
                'Edit Information',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 9),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Divider(color: Colors.grey.shade300, thickness: 1),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Row(
            children: [
              Icon(
                Icons.menu,
                size: ResponsiveUtils.spacing(context, 18),
                color: Colors.black87,
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Food Menu',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.read(merchantNavProvider.notifier).state =
                      MerchantNavType.menu;
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: const Color(0xFF9B59F0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...merchantFoodMenuItems.map(
                    (item) => MerchantMenuItemCard(
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
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
