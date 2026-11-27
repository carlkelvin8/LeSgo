import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/profile/profile_provider.dart';
import 'hero_banner.dart';

const _slides = [
  (
    image: 'assets/images/homepage/customer_welcome_hero.png',
    title: 'Ready to order?',
    subtitle: 'Rides, meals, and deliveries in one place.',
  ),
  (
    image: 'assets/images/homepage/tricycle_hero.png',
    title: 'Ride around town',
    subtitle: 'Book a tricycle with LesRide.',
  ),
  (
    image: 'assets/images/homepage/food_delivery_hero.png',
    title: 'Craving something?',
    subtitle: 'Get your favorites delivered with LesEat.',
  ),
];

class HomeHeroSection extends ConsumerStatefulWidget {
  const HomeHeroSection({super.key});

  @override
  ConsumerState<HomeHeroSection> createState() => _HomeHeroSectionState();
}

class _HomeHeroSectionState extends ConsumerState<HomeHeroSection> {
  final _controller = PageController();
  final _activePointers = <int>{};
  Timer? _timer;
  int _page = 0;
  bool? _autoplayOverride;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  bool get _autoplay => _autoplayOverride ?? !_reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleSlide();
  }

  void _scheduleSlide() {
    _timer?.cancel();
    if (!_autoplay || _activePointers.isNotEmpty) return;

    _timer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if ((lifecycle == null || lifecycle == AppLifecycleState.resumed) &&
          ModalRoute.of(context)?.isCurrent != false) {
        _goToPage((_page + 1) % _slides.length);
      } else {
        _scheduleSlide();
      }
    });
  }

  void _goToPage(int index) {
    if (_controller.hasClients && index != _page) {
      if (_reduceMotion) {
        _controller.jumpToPage(index);
      } else {
        _controller
            .animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (mounted) _scheduleSlide();
            });
      }
    }
    _scheduleSlide();
  }

  void _endInteraction(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _scheduleSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref
        .watch(profileProvider.select((state) => state.name))
        .trim();
    final firstName = name.isEmpty ? null : name.split(RegExp(r'\s+')).first;
    final accent = AppColors.buttonFill(context);
    final indicator = AppColors.foreground(context, const Color(0xFF716477));

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final height =
                  (constraints.maxWidth * .58).clamp(210.0, 284.0) +
                  (textScale - 1).clamp(0.0, 2.0) * 132 +
                  (compact ? 14 : 0);
              return SizedBox(
                height: height,
                child: Listener(
                  onPointerDown: (event) {
                    _activePointers.add(event.pointer);
                    _timer?.cancel();
                  },
                  onPointerUp: _endInteraction,
                  onPointerCancel: _endInteraction,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: PageView.builder(
                      controller: _controller,
                      allowImplicitScrolling: true,
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() => _page = index);
                        _scheduleSlide();
                      },
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        return HeroBanner(
                          userName: firstName,
                          showGreeting: index == 0,
                          backgroundImagePath: slide.image,
                          title: slide.title,
                          subtitle: slide.subtitle,
                          onBookNowPressed: () =>
                              AppRouter.push(context, MainRoutes.bookNow),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < _slides.length; index++)
                      Semantics(
                        selected: index == _page,
                        child: IconButton(
                          tooltip:
                              'Slide ${index + 1} of ${_slides.length}: ${_slides[index].title}',
                          onPressed: () => _goToPage(index),
                          icon: AnimatedContainer(
                            duration: _reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 200),
                            width: index == _page ? 23 : 8,
                            height: 7,
                            decoration: BoxDecoration(
                              color: index == _page ? accent : indicator,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _autoplay ? 'Pause carousel' : 'Play carousel',
                color: accent,
                onPressed: () {
                  setState(() => _autoplayOverride = !_autoplay);
                  _scheduleSlide();
                },
                icon: Icon(
                  _autoplay ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
