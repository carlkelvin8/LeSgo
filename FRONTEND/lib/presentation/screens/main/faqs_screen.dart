import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../provider/main/faq/faq_provider.dart';
import '../../widgets/common/retry_widget.dart';
import '../../widgets/faq/faq_item.dart';

class FaqsScreen extends ConsumerStatefulWidget {
  const FaqsScreen({super.key});

  @override
  ConsumerState<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends ConsumerState<FaqsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _listAnim;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Start list animation once loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(faqProvider);
      if (!state.isLoading && state.faqs.isNotEmpty) {
        _listAnim.forward();
      }
    });
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _listAnim.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqState = ref.watch(faqProvider);

    // Trigger list animation when data arrives
    ref.listen<FaqState>(faqProvider, (_, next) {
      if (!next.isLoading && next.faqs.isNotEmpty) {
        _listAnim.forward(from: 0);
      }
    });

    final filtered = _query.isEmpty
        ? faqState.faqs
        : faqState.faqs
              .where(
                (f) =>
                    f.question.toLowerCase().contains(_query) ||
                    f.answer.toLowerCase().contains(_query),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.surface(context, Color(0xFFF8F7FB)),
      body: RefreshIndicator(
        color: AppColors.accent(context, Color(0xFF5F2D82)),
        displacement: 80,
        onRefresh: () => ref.read(faqProvider.notifier).refreshFaqs(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero app bar ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF5A1E88),
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _BackButton(),
              ),
              title: const Text(
                'Help Center',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: _FaqHero(),
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(
                child: _SearchBar(controller: _search),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            if (faqState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                ),
              )
            else if (faqState.error != null && faqState.faqs.isEmpty)
              SliverFillRemaining(
                child: RetryWidget(
                  message: faqState.error!,
                  onRetry: () => ref.read(faqProvider.notifier).refreshFaqs(),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(child: _EmptyState(query: _query))
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 40,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Stagger each card
                    final start = (index / filtered.length) * .6;
                    final end = (start + .4).clamp(0.0, 1.0);
                    final itemAnim = CurvedAnimation(
                      parent: _listAnim,
                      curve: Interval(start, end, curve: Curves.easeOutCubic),
                    );
                    return AnimatedBuilder(
                      animation: itemAnim,
                      builder: (_, child) => Opacity(
                        opacity: itemAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, 28 * (1 - itemAnim.value)),
                          child: child,
                        ),
                      ),
                      child: FaqItem(
                        faq: filtered[index],
                        index: index,
                        isFirst: index == 0 && _query.isEmpty,
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: .25),
            width: .8,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────
class _FaqHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B3FC8),
                  Color(0xFF5A1E88),
                  Color(0xFF280A45),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Decorative rings
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _RingsPainter())),
        ),

        // Illustration
        Positioned(
          right: -10,
          bottom: 48,
          child: SvgPicture.asset(
            'assets/images/faq/Faq.svg',
            height: 170,
            fit: BoxFit.contain,
            alignment: Alignment.bottomRight,
          ),
        ),

        // Text content
        Positioned(
          left: 24,
          bottom: 52,
          right: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .22),
                    width: .8,
                  ),
                ),
                child: const Text(
                  'HELP CENTER',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'How can we\nhelp you?',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find answers to common questions',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: .65),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Top shimmer edge
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 1.5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: .28),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Rings painter ────────────────────────────────────────────────────────────
class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    final center = Offset(size.width * 1.1, size.height * .1);
    for (var i = 0; i < 5; i++) {
      paint.color = Colors.white.withValues(alpha: .04 + i * .012);
      canvas.drawCircle(center, size.width * (.25 + i * .12), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) => false;
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface(context, const Color(0xFFF8F7FB)),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent(
                context,
                Color(0xFF5F2D82),
              ).withValues(alpha: .08),
              blurRadius: 16,
              offset: const Offset(0, 3),
              spreadRadius: -3,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13.5,
            color: AppColors.foreground(context, Color(0xFF1A0A2E)),
          ),
          decoration: InputDecoration(
            hintText: 'Search questions…',
            hintStyle: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13.5,
              color: AppColors.foreground(context, Colors.grey.shade400),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.foreground(context, Colors.grey.shade400),
            ),
            suffixIcon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, value, __) => value.text.isNotEmpty
                  ? GestureDetector(
                      onTap: controller.clear,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.foreground(
                          context,
                          Colors.grey.shade400,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }
}

// ─── Search bar sliver delegate ───────────────────────────────────────────────
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _SearchBarDelegate({required this.child});

  @override
  double get minExtent => 66;
  @override
  double get maxExtent => 66;

  @override
  Widget build(_, double shrink, bool overlap) => child;

  @override
  bool shouldRebuild(covariant _SearchBarDelegate old) => old.child != child;
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface(context, Color(0xFFF3ECF9)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: Color(0xFF9B70CC),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              query.isEmpty
                  ? 'No questions available'
                  : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground(context, Color(0xFF1A0A2E)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Pull down to refresh'
                  : 'Try a different search term',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: Color(0xFFAA90C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
