import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../provider/main/profile/profile_provider.dart';

class HomeHeroSection extends ConsumerWidget {
  const HomeHeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    
    // Extract first name from full name, or use 'Guest' if empty
    String firstName = 'Guest';
    if (profileState.name.isNotEmpty) {
      firstName = profileState.name.split(' ').first;
    }
    
    return Column(
      children: [
        HeroBanner(
          userName: firstName,
          backgroundImagePath: 'assets/images/homepage/Rider.svg',
          onBookNowPressed: () {
            AppRouter.push(context, MainRoutes.bookNow);
          },
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
      ],
    );
  }
}

