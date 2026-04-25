import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../widgets/home/home_favorites_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
