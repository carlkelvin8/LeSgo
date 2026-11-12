import '../../../../provider/auth/rider_auth_provider.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../provider/main/merchantside/merchant_daily_summary_provider.dart';
import '../../../../../core/services/daily_sales_summary_service.dart';
import '../../../../widgets/widgets.dart';
import '../../../../widgets/main/merchantside/profile/merchant_settings_section.dart';
import '../../../../widgets/main/merchantside/analytics/merchant_revenue_chart.dart';
import '../../../../widgets/main/merchantside/analytics/merchant_popular_items_section.dart';
import '../merchant_edit_information_screen.dart';
import '../merchant_menu_edit_item_screen.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_actions.dart';
import '../../../../../core/utils/dark_aware_colors.dart';
import '../../../../../core/utils/app_localization.dart';
import '../../../../../core/utils/api_error_mapper.dart';

bool _canEditMenu(BuildContext context, WidgetRef ref) {
  if (ref.read(canEditMerchantMenuProvider)) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.tr('Only the store owner or a staff admin can edit the menu.'))),
  );
  return false;
}

class MerchantProfileView extends ConsumerWidget {
  const MerchantProfileView({super.key});

  Widget _buildDailySummaryBanner(WidgetRef ref) {
    final dismissed = ref.watch(merchantDailySummaryDismissedProvider);
    if (dismissed) return const SizedBox.shrink();

    final summaryAsync = ref.watch(merchantDailySummaryProvider);
    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DailySalesSummaryBanner(
            data: data,
            onDismiss: () {
              ref.read(merchantDailySummaryDismissedProvider.notifier).state = true;
              DailySalesSummaryService.markShown();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final profileAsync = ref.watch(merchantProfileProvider);
    final menuItemsAsync = ref.watch(merchantMenuItemsProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(ApiErrorMapper.message(error, fallbackEn: 'Could not load your profile.', fallbackTl: 'Hindi ma-load ang profile mo.')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(merchantProfileProvider),
              child: Text(context.tr('Retry')),
            ),
          ],
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Center(
            child: Text(context.tr('No merchant profile found. Please contact support.')),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: ResponsiveUtils.spacing(context, 18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailySummaryBanner(ref),
              const MerchantProfileHeader(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              const MerchantProfileInfoSection(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              const MerchantAnalyticsPreviewCard(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              const MerchantRevenueChart(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              const MerchantPopularItemsSection(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              _SalesReportCard(),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              const MerchantReviewsPreviewCard(),
              SizedBox(
                height: ResponsiveUtils.spacing(context, 24),
                child: ElevatedButton(
                  onPressed: ref.watch(riderAuthProvider).user?.isStaff == true ? null : () {
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
                    context.tr('Edit Information'),
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
              Divider(color: context.brd(Colors.grey.shade300), thickness: 1),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              const MerchantSettingsSection(),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Divider(color: context.brd(Colors.grey.shade300), thickness: 1),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Row(
                children: [
                  Icon(
                    Icons.menu,
                    size: ResponsiveUtils.spacing(context, 18),
                    color: context.txt(Colors.black87),
                  ),
                  SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                  Text(
                    context.tr('Food Menu'),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 18),
                      fontWeight: FontWeight.w700,
                      color: context.txt(Colors.black),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.read(merchantNavProvider.notifier).state =
                          MerchantNavType.menu;
                    },
                    child: Text(
                      context.tr('See all'),
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
              menuItemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(ApiErrorMapper.message(error, fallbackEn: 'Could not load your menu.', fallbackTl: 'Hindi ma-load ang menu mo.')),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(merchantMenuItemsProvider),
                        child: Text(context.tr('Retry')),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: context.sub(Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('No menu items yet'),
                            style: TextStyle(
                              fontSize: 18,
                              color: context.sub(Colors.grey.shade600),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Add items to your menu to get started'),
                            style: TextStyle(
                              fontSize: 14,
                              color: context.sub(Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...items.take(5).map(
                        (item) => MerchantMenuItemCard(
                          name: item.name,
                          description: item.description ?? '',
                          price: item.price.toStringAsFixed(2),
                          category: item.category?.name ?? '',
                          imageUrl: item.imageUrl,
                          onEditTap: () {
                            if (!_canEditMenu(context, ref)) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MerchantMenuEditItemScreen(
                                  initialItem: menuItemToEditFormMap(
                                    item,
                                    categoryName: item.category?.name ?? '',
                                    encodeOptions: jsonEncode,
                                  ),
                                ),
                              ),
                            );
                          },
                          onDeleteTap: () {
                            if (!_canEditMenu(context, ref)) return;
                            confirmAndDeleteMerchantMenuItem(
                              context,
                              ref,
                              itemId: item.id,
                              itemName: item.name,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 18)),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesReportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRouter.push(context, MainRoutes.merchantSalesReport),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: context.surf(const Color(0xFFF3E5F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.brd(const Color(0xFFE1BEE7))),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.spacing(context, 44),
              height: ResponsiveUtils.spacing(context, 44),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.download_outlined,
                color: context.acc(const Color(0xFF7B1FA2)),
                size: ResponsiveUtils.fontSize(context, 22),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Sales Reports'),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: context.acc(const Color(0xFF4A148C)),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    context.tr('Download CSV or PDF reports'),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.acc(const Color(0xFF7B1FA2)),
            ),
          ],
        ),
      ),
    );
  }
}
