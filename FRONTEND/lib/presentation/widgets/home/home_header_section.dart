import 'package:flutter/material.dart';

import '../widgets.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/constants/routers/app_router.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LocationHeader(
      location: 'Brgy. 6, Gawad, Cagayan',
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
