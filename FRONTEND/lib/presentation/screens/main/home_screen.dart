import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/widgets.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/promo_notification_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/offers/offers_provider.dart';
import '../../widgets/home/home_favorites_section.dart';
import '../../widgets/home/home_active_orders_section.dart';
import '../../provider/main/orders/active_orders_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onHomeReady());
  }

  Future<void> _onHomeReady() async {
    if (!mounted) return;
    ref.read(activeOrdersProvider.notifier).loadActiveOrders();
    final offers = ref.read(offersProvider).featuredOffers;
    if (offers.isNotEmpty) {
      await getIt<PromoNotificationService>().maybeShowDailyPromoPush(
        context,
        featuredTitle: offers.first.title,
        featuredDiscount: offers.first.discountLabel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext scaffoldContext) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HomeHeaderSection(),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  const HomeActiveOrdersSection(),
                  const HomeHeroSection(),
                  const HomeQuickAccessSection(),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  const HomeFavoritesSection(),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  const HomePromosSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
