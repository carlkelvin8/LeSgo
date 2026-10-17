import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../widgets/common/retry_widget.dart';

class RiderFaqsScreen extends ConsumerStatefulWidget {
  const RiderFaqsScreen({super.key});

  @override
  ConsumerState<RiderFaqsScreen> createState() => _RiderFaqsScreenState();
}

class _RiderFaqsScreenState extends ConsumerState<RiderFaqsScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _categories = [];
  List<dynamic> _articles = [];
  int? _selectedCategoryId;
  bool _loading = true;
  bool _searching = false;
  String? _error;
  final Set<int> _votedArticleIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getFaqCategories(),
        ApiService.getFaqArticles(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _articles = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searching = false;
        _selectedCategoryId = null;
      });
      await _loadInitial();
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final articles = await ApiService.searchFaqArticles(trimmed);
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _searching = false;
      });
    }
  }

  Future<void> _loadCategory(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchController.clear();
      _searching = false;
      _loading = true;
      _error = null;
    });
    try {
      final articles = categoryId == null
          ? await ApiService.getFaqArticles()
          : await ApiService.getFaqArticlesByCategory(categoryId);
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _voteHelpful(int articleId, {required bool helpful}) async {
    if (_votedArticleIds.contains(articleId)) return;
    try {
      await ApiService.markFaqHelpful(articleId, helpful: helpful);
      if (!mounted) return;
      setState(() => _votedArticleIds.add(articleId));
      final l = ref.read(appLanguageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(helpful ? AppLocalization.translate('thank_you_feedback', l) : AppLocalization.translate('feedback_recorded', l)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final showChips = _categories.isNotEmpty && !_searching;
    final headerExtent = 66.0 + (showChips ? 46.0 : 0.0);

    Widget body;
    if (_loading || _searching) {
      body = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: _brand)),
      );
    } else if (_error != null && _articles.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: RetryWidget(message: _error!, onRetry: _loadInitial),
      );
    } else if (_articles.isEmpty) {
      body = const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).padding.bottom + 40,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final faq = _articles[index] as Map<String, dynamic>;
            final articleId = (faq['id'] as num?)?.toInt() ?? index;
            final voted = _votedArticleIds.contains(articleId);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index.clamp(0, 6) * 60)),
              curve: Curves.easeOutCubic,
              builder: (_, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - v)),
                  child: child,
                ),
              ),
              child: _FaqCard(
                key: ValueKey(articleId),
                index: index,
                question: faq['title']?.toString() ?? 'Question',
                answer: faq['content']?.toString() ?? '',
                isFirst: index == 0 && _searchController.text.isEmpty,
                voted: voted,
                yesLabel: AppLocalization.translate('yes', lang),
                noLabel: AppLocalization.translate('no', lang),
                onVote: (helpful) =>
                    _voteHelpful(articleId, helpful: helpful),
              ),
            );
          }, childCount: _articles.length),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FB),
      body: RefreshIndicator(
        color: _brand,
        displacement: 80,
        onRefresh: () => _selectedCategoryId == null && !_searching
            ? _loadInitial()
            : _loadCategory(_selectedCategoryId),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF5A1E88),
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _BackButton(),
              ),
              title: Text(
                AppLocalization.translate('faqs', lang),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: const FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: [StretchMode.zoomBackground],
                background: _FaqHero(),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                extent: headerExtent,
                child: Container(
                  color: const Color(0xFFF8F7FB),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: _SearchBar(
                          controller: _searchController,
                          hint: AppLocalization.translate('search_faqs', lang),
                          onSubmitted: _search,
                          onCleared: () => _search(''),
                        ),
                      ),
                      if (showChips)
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _CategoryChip(
                                label: 'All',
                                selected: _selectedCategoryId == null,
                                onTap: () => _loadCategory(null),
                              ),
                              ..._categories.map((cat) {
                                final map = cat as Map<String, dynamic>;
                                final id = (map['id'] as num?)?.toInt();
                                if (id == null) return const SizedBox.shrink();
                                return _CategoryChip(
                                  label: map['name']?.toString() ??
                                      map['title']?.toString() ??
                                      'Category',
                                  selected: _selectedCategoryId == id,
                                  onTap: () => _loadCategory(id),
                                );
                              }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

const _brand = Color(0xFF5F2D82);

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
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _FaqHero extends StatelessWidget {
  const _FaqHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B3FC8), Color(0xFF5A1E88), Color(0xFF280A45)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _RingsPainter())),
        ),
        Positioned(
          right: -10,
          bottom: 28,
          child: SvgPicture.asset(
            'assets/images/faq/Faq.svg',
            height: 150,
            fit: BoxFit.contain,
            alignment: Alignment.bottomRight,
          ),
        ),
        Positioned(
          left: 24,
          bottom: 40,
          right: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: .08),
            blurRadius: 16,
            offset: const Offset(0, 3),
            spreadRadius: -3,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        onChanged: (value) {
          if (value.isEmpty) onCleared();
        },
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13.5,
          color: Color(0xFF1A0A2E),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13.5,
            color: Colors.grey.shade400,
          ),
          prefixIcon: Icon(Icons.search_rounded,
              size: 18, color: Colors.grey.shade400),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) => value.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      onCleared();
                    },
                    child: Icon(Icons.close_rounded,
                        size: 16, color: Colors.grey.shade400),
                  )
                : const SizedBox.shrink(),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;
  const _FilterHeaderDelegate({required this.extent, required this.child});

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrink, bool overlap) => child;

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate old) => true;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
                color: const Color(0xFFF3ECF9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 34, color: Color(0xFF9B70CC)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No FAQs found',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A0A2E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term',
              style: TextStyle(
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _brand : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _brand : const Color(0xFFE7DEEF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF4A3060),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final int index;
  final String question;
  final String answer;
  final bool isFirst;
  final bool voted;
  final String yesLabel;
  final String noLabel;
  final ValueChanged<bool> onVote;

  const _FaqCard({
    super.key,
    required this.index,
    required this.question,
    required this.answer,
    required this.isFirst,
    required this.voted,
    required this.yesLabel,
    required this.noLabel,
    required this.onVote,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _expand;
  late final Animation<double> _rotate;
  late final Animation<double> _fade;
  bool _isOpen = false;

  static const _accents = [
    Color(0xFF7B3FC8),
    Color(0xFF5F2D82),
    Color(0xFF9040C0),
    Color(0xFF6A2EA0),
    Color(0xFF4E2070),
  ];

  Color get _accent => _accents[widget.index % _accents.length];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _rotate = Tween<double>(begin: 0, end: .5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    if (widget.isFirst) {
      _isOpen = true;
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _isOpen;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: isOpen ? .12 : .05),
            blurRadius: isOpen ? 20 : 10,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
        border: Border.all(
          color: isOpen
              ? _accent.withValues(alpha: .20)
              : const Color(0xFFF0EBF6),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            splashColor: _accent.withValues(alpha: .06),
            highlightColor: _accent.withValues(alpha: .04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(top: 1, right: 12),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? _accent
                              : _accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.index + 1}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isOpen ? Colors.white : _accent,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.question,
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E1A4A),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RotationTransition(
                        turns: _rotate,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isOpen
                                ? _accent.withValues(alpha: .10)
                                : const Color(0xFFF3ECF9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: _accent),
                        ),
                      ),
                    ],
                  ),
                ),
                SizeTransition(
                  sizeFactor: _expand,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _accent.withValues(alpha: .15),
                                _accent.withValues(alpha: .04),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(56, 12, 16, 12),
                          child: Text(
                            widget.answer,
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 13,
                              color: Color(0xFF4A3060),
                              height: 1.65,
                            ),
                          ),
                        ),
                        if (!widget.voted)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(52, 0, 16, 14),
                            child: Row(
                              children: [
                                Text(
                                  'Was this helpful?',
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _VoteButton(
                                  icon: Icons.thumb_up_outlined,
                                  label: widget.yesLabel,
                                  onTap: () => widget.onVote(true),
                                ),
                                const SizedBox(width: 8),
                                _VoteButton(
                                  icon: Icons.thumb_down_outlined,
                                  label: widget.noLabel,
                                  onTap: () => widget.onVote(false),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3ECF9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _brand),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
