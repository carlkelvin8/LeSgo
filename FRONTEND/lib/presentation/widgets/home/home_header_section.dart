import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../provider/main/address/address_provider.dart';
import '../../provider/auth/auth_provider.dart';

class HomeHeaderSection extends ConsumerStatefulWidget {
  const HomeHeaderSection({super.key});

  @override
  ConsumerState<HomeHeaderSection> createState() => _HomeHeaderSectionState();
}

class _HomeHeaderSectionState extends ConsumerState<HomeHeaderSection> {
  @override
  void initState() {
    super.initState();
    // Load addresses when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;
      if (userId > 0) {
        ref.read(addressProvider.notifier).loadAddresses(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);
    
    // Get default address using the provider's built-in getter
    final defaultAddress = addressState.defaultAddress;
    
    // Format location text
    String locationText = 'Set your location';
    if (defaultAddress != null) {
      // Use address_line1 or country
      if (defaultAddress.addressLine1.isNotEmpty) {
        locationText = defaultAddress.addressLine1;
      } else {
        locationText = defaultAddress.country;
      }
    }

    return LocationHeader(
      location: locationText,
      onMenuTap: () {
        Scaffold.of(context).openDrawer();
      },
      onLocationTap: () {
        AppRouter.push(context, MainRoutes.setLocation);
      },
      onProfileTap: () {
        AppRouter.push(context, MainRoutes.profile);
      },
    );
  }
}
