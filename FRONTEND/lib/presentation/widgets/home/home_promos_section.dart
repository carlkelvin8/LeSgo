import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../provider/main/offers/offers_provider.dart';
import '../../screens/main/offers_screen.dart';
import '../offers/offers_empty_state.dart';

class HomePromosSection extends ConsumerStatefulWidget {
  const HomePromosSection({super.key});

  @override
  ConsumerState<HomePromosSection> createState() => _HomePromosSectionState();
}

class _HomePromosSectionState extends ConsumerState<HomePromosSection> {
  late ScrollController _scrollController;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Start auto-scroll after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _isUserScrolling) {
        // If user is scrolling, wait and retry
        if (mounted) _startAutoScroll();
        return;
      }

      final offersState = ref.read(offersProvider);
      final offers = offersState.featuredOffers;

      if (offers.isEmpty || !_scrollController.hasClients) {
        if (mounted) _startAutoScroll();
        return;
      }

      // Calculate card width (based on PromoCard design)
      final cardWidth = 280.0 + 12.0; // card width + spacing
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      // Check if at end, scroll back to start
      if (currentScroll >= maxScroll - 10) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        // Scroll to next card
        final nextScroll = (currentScroll + cardWidth).clamp(0.0, maxScroll);
        _scrollController.animateTo(
          nextScroll,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }

      _startAutoScroll(); // Continue loop
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersState = ref.watch(offersProvider);
    final offers = offersState.featuredOffers;

    return Column(
      children: [
        SectionHeader(
          title: 'Offers for You',
          onSeeAllPressed: () => _openOffersScreen(context),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        SectionContainer(
          margin: EdgeInsets.only(
            left: ResponsiveUtils.spacing(context, 16.0),
            right: ResponsiveUtils.spacing(context, 16.0),
            bottom: ResponsiveUtils.spacing(context, 16.0),
          ),
          child: SizedBox(
            height: ResponsiveUtils.imageHeight(context, 200),
            child: offersState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF5F2D82),
                      ),
                    ),
                  )
                : offers.isEmpty
                ? const OffersEmptyState()
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // Detect when user starts/stops scrolling
                      if (notification is ScrollStartNotification) {
                        _isUserScrolling = true;
                      } else if (notification is ScrollEndNotification) {
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) _isUserScrolling = false;
                        });
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 600 + (index * 150)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset((1 - value) * 100, 0),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: PromoCard(
                            title: offer.title,
                            subtitle: offer.service,
                            badge: offer.discountLabel,
                            accentColor: Color(offer.accentColor),
                            onTap: () => _openOffersScreen(context),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _openOffersScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OffersScreen()),
    );
  }
}
