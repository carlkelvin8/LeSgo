import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../provider/main/profile/profile_provider.dart';

class HomeHeroSection extends ConsumerStatefulWidget {
  const HomeHeroSection({super.key});

  @override
  ConsumerState<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends ConsumerState<HomeHeroSection> {
  late PageController _pageController;
  int _currentPage = 0;
  
  // Carousel slides data
  final List<Map<String, dynamic>> _slides = [
    {
      'background': 'assets/images/homepage/customer_welcome_hero.png',
      'backgroundType': 'image',
      'title': 'Ready to Order?',
      'subtitle': 'Book your ride now',
    },
    {
      'background': 'assets/images/homepage/tricycle_hero.png',
      'backgroundType': 'image',
      'title': 'Best Prices',
      'subtitle': 'Affordable rates for everyone',
    },
    {
      'background': 'assets/images/homepage/food_delivery_hero.png',
      'backgroundType': 'image',
      'title': 'Fast Food Delivery',
      'subtitle': 'Get your favorites delivered quickly',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      
      _startAutoScroll(); // Continue loop
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    
    // Extract first name from full name, or use 'Guest' if empty
    String firstName = 'Guest';
    if (profileState.name.isNotEmpty) {
      firstName = profileState.name.split(' ').first;
    }
    
    return Column(
      children: [
        // Carousel PageView
        SizedBox(
          height: ResponsiveUtils.imageHeight(context, 220),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return HeroBanner(
                    userName: firstName,
                    showGreeting: index == 0,
                    backgroundImagePath: slide['background']!,
                    title: slide['title']!,
                    subtitle: slide['subtitle']!,
                    onBookNowPressed: () {
                      AppRouter.push(context, MainRoutes.bookNow);
                    },
                  );
                },
              ),
              
              // Page indicators
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFA930D0)
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
      ],
    );
  }
}

