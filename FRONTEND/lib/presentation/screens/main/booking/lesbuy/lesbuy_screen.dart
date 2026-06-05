import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/widgets.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/booking/booking_routes.dart';
import '../../../../provider/main/booking/lesbuy/lesbuy_provider.dart';
import '../../../../provider/main/booking/controller/lesbuy.controller.notifier.dart';
import '../../../../provider/main/profile/profile_provider.dart';

class LesbuyScreen extends ConsumerStatefulWidget {
  const LesbuyScreen({super.key});

  @override
  ConsumerState<LesbuyScreen> createState() => _LesbuyScreenState();
}

class _LesbuyScreenState extends ConsumerState<LesbuyScreen> {
  late final LesbuyControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = LesbuyControllers();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesbuyState = ref.watch(lesbuyProvider);
    final lesbuyNotifier = ref.read(lesbuyProvider.notifier);
    final profileState = ref.watch(profileProvider);

    // Get user name and address
    final userName = profileState.name.isNotEmpty 
        ? profileState.name 
        : 'Guest';
    final userAddress = profileState.address1.isNotEmpty
        ? profileState.address1
        : 'No address set';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BookingServiceHeader(
        title: 'LesBuy',
        action: IconButton(
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: Color(0xFFA930D0),
            size: 28,
          ),
          onPressed: () {
            AppRouter.push(context, BookingRoutes.lesbuyCart);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Location Header
            LocationHeaderSection(
              userName: userName,
              address: userAddress,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Search Field
            LesbuySearchField(
              controller: _controllers.searchController,
              onChanged: (value) => lesbuyNotifier.updateSearchQuery(value),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Section Header
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.horizontalPadding(context),
              ),
              child: Text(
                'Explore stores',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 12)),

            // Store List
            Expanded(
              child: lesbuyState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : lesbuyState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                lesbuyState.error!,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 14),
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                              TextButton(
                                onPressed: () => lesbuyNotifier.refresh(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : StoreListSection(
                          stores: lesbuyState.filteredStores,
                          onStoreTap: (store) {
                            AppRouter.push(
                              context,
                              BookingRoutes.lesbuyStoreDetail,
                              arguments: store,
                            );
                          },
                        ),
            ),

            // Manual Order Section
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Can’t find what you’re looking for? You can manually enter it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  PrimaryButton(
                    text: 'Order',
                    backgroundColor: const Color(0xFF5F2D82),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DisclaimerDialog(
                          description:
                              'Prices are estimated. The actual amount will be determined by the rider when buying the product.',
                          onOrderNow: () {
                            Navigator.pop(context);
                            AppRouter.push(
                              context,
                              BookingRoutes.lesbuyManualOrder,
                            );
                          },
                          onCancel: () {
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
