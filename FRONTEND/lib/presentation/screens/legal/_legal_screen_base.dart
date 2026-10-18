import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared premium base for Privacy Policy & Terms of Service screens.
class LegalScreenBase extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<({String title, String body})> sections;

  const LegalScreenBase({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.sections,
  });

  @override
  State<LegalScreenBase> createState() => _LegalScreenBaseState();
}

class _LegalScreenBaseState extends State<LegalScreenBase>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnim;
  late final AnimationController _listAnim;
  late final ScrollController _scroll;
  double _readProgress = 0;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _listAnim = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + widget.sections.length * 55),
    )..forward();
    _scroll = ScrollController()
      ..addListener(() {
        final max = _scroll.position.maxScrollExtent;
        if (max > 0) {
          setState(() {
            _readProgress = (_scroll.offset / max).clamp(0.0, 1.0);
          });
        }
      });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _listAnim.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final safePad = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.surface(context, Color(0xFFF8F7FB)),
      body: Column(
        children: [
          // ── Hero header (fixed, not scrolling) ──────────────────────
          _HeroHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            accent: accent,
            anim: _headerAnim,
            topPadding: safePad.top,
          ),

          // ── Read progress bar ────────────────────────────────────────
          _ReadProgressBar(progress: _readProgress, accent: accent),

          // ── Scrollable sections ──────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                safePad.bottom + 40,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.sections.length,
              itemBuilder: (context, index) {
                final start = (index / widget.sections.length) * .55;
                final end = (start + .45).clamp(0.0, 1.0);
                final itemAnim = CurvedAnimation(
                  parent: _listAnim,
                  curve: Interval(start, end, curve: Curves.easeOutCubic),
                );
                return AnimatedBuilder(
                  animation: itemAnim,
                  builder: (_, child) => Opacity(
                    opacity: itemAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, 22 * (1 - itemAnim.value)),
                      child: child,
                    ),
                  ),
                  child: _SectionCard(
                    index: index,
                    title: widget.sections[index].title,
                    body: widget.sections[index].body,
                    accent: accent,
                    isFirst: index == 0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String title, subtitle;
  final Color accent;
  final Animation<double> anim;
  final double topPadding;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.anim,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(anim.value);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(accent, Colors.white, .15)!,
                accent,
                Color.lerp(accent, Colors.black, .18)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Back button row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .25),
                          width: .8,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - t)),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -.5,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Subtitle
              Opacity(
                opacity: (t * 1.6 - .6).clamp(0.0, 1.0),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: .68),
                    letterSpacing: .1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Read progress bar ────────────────────────────────────────────────────────
class _ReadProgressBar extends StatelessWidget {
  final double progress;
  final Color accent;
  const _ReadProgressBar({required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      minHeight: 3,
      backgroundColor: accent.withValues(alpha: .12),
      valueColor: AlwaysStoppedAnimation(accent),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final int index;
  final String title;
  final String body;
  final Color accent;
  final bool isFirst;

  const _SectionCard({
    required this.index,
    required this.title,
    required this.body,
    required this.accent,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    // First section = compact date chip
    if (isFirst) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: .14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: accent),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  '$title  $body',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: .05),
              blurRadius: 14,
              offset: const Offset(0, 3),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(accent, Colors.white, .25)!,
                          accent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      title,
                      style:  TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground(context, Color(0xFF1A0A2E)),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.border(context, Color(0xFFF0EBF6)),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _buildBody(context, body, accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String text, Color accent) {
    final paragraphs = text.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        final lines = para.split('\n');
        if (lines.length > 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) {
                if (line.trim().isEmpty) return const SizedBox(height: 3);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 7),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .40),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line.trim(),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 13,
                            color: AppColors.foreground(context, Color(0xFF4A3060)),
                            height: 1.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            para.trim(),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: AppColors.foreground(context, Color(0xFF4A3060)),
              height: 1.65,
            ),
          ),
        );
      }).toList(),
    );
  }
}
