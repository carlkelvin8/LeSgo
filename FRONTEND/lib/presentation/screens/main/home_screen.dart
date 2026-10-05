import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/widgets.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/promo_notification_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/offers/offers_provider.dart';
import '../../widgets/home/home_favorites_section.dart';
import '../../widgets/home/home_active_orders_section.dart';
import '../../widgets/home/home_services_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  
  @override
  void initState() {
    super.initState();
    
    // Create 6 animation controllers for each section (added 1 for services)
    _controllers = List.generate(
      6,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800), // Longer duration for visibility
      ),
    );

    // Create slide and fade animations with MORE movement
    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3), // More slide distance
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();

    // Start animations with delays - LONGER delays for visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onHomeReady();
      for (var i = 0; i < _controllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 200), () { // 200ms delay instead of 150ms
          if (mounted) _controllers[i].forward();
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _onHomeReady() async {
    if (!mounted) return;
    final offers = ref.read(offersProvider).featuredOffers;
    if (offers.isNotEmpty) {
      await getIt<PromoNotificationService>().maybeShowDailyPromoPush(
        context,
        featuredTitle: offers.first.title,
        featuredDiscount: offers.first.discountLabel,
      );
    }
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext scaffoldContext) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header - no animation
                  const HomeHeaderSection(),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  
                  // Active orders - animated
                  _buildAnimatedSection(0, const HomeActiveOrdersSection()),
                  
                  // Hero banner - animated
                  _buildAnimatedSection(1, const HomeHeroSection()),
                  
                  // Quick access cards stay stationary.
                  const HomeQuickAccessSection(),
                  
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  // Services showcase - animated
                  _buildAnimatedSection(2, const HomeServicesSection()),
                  
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  // Favorites - animated
                  _buildAnimatedSection(3, const HomeFavoritesSection()),
                  
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                  
                  // Promos - animated
                  _buildAnimatedSection(5, const HomePromosSection()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
