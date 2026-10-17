import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _purple = Color(0xFF6D3EA0);

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;
Color _surface(BuildContext context) =>
    _isDark(context) ? const Color(0xFF1E1730) : Colors.white;
Color _text(BuildContext context) =>
    _isDark(context) ? const Color(0xFFF5F0FB) : const Color(0xFF1A0A2E);
Color _muted(BuildContext context) =>
    _isDark(context) ? const Color(0xFFB9B1C6) : const Color(0xFF9A85B8);
Color _border(BuildContext context) =>
    _isDark(context) ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2);

// ─── Tappable press surface with bounce + haptic ──────────────────────────────
class _PressSurface extends StatefulWidget {
  const _PressSurface({
    required this.child,
    required this.onTap,
    this.radius = 20.0,
    this.gradient,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Gradient? gradient;

  @override
  State<_PressSurface> createState() => _PressSurfaceState();
}

class _PressSurfaceState extends State<_PressSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: .97,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    _ctrl.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      onTap: _onTap,
      onTapDown: (_) {
        if (!disabled) _ctrl.forward();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: disabled ? 1 : _scale.value, child: child),
        child: Material(
          color: _surface(context),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.radius),
            side: widget.gradient == null
                ? BorderSide(color: _border(context))
                : BorderSide.none,
          ),
          child: widget.gradient != null
              ? Ink(
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(widget.radius),
                  ),
                  child: widget.child,
                )
              : widget.child,
        ),
      ),
    );
  }
}

// ─── Wallet card with animated shimmer sweep ──────────────────────────────────
class MoreWalletCard extends StatefulWidget {
  const MoreWalletCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  State<MoreWalletCard> createState() => _MoreWalletCardState();
}

class _MoreWalletCardState extends State<MoreWalletCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PressSurface(
      onTap: widget.onTap,
      radius: 24,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5A1E88), Color(0xFF8B3FC8), Color(0xFF3A0D60)],
        stops: [0.0, 0.5, 1.0],
      ),
      child: Stack(
        children: [
          // Decorative ring
          Positioned(
            right: -44,
            top: -72,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .06),
                    width: 32,
                  ),
                ),
              ),
            ),
          ),
          // Second ring
          Positioned(
            right: 20,
            bottom: -30,
            child: IgnorePointer(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .05),
                    width: 16,
                  ),
                ),
              ),
            ),
          ),
          // Shimmer beam
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (_, __) {
                final x = -0.4 + 1.8 * _shimmer.value;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CustomPaint(painter: _ShimmerPainter(x: x)),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .20),
                          width: .8,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.action,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F0B8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .20),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: Color(0xFF2A0850),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer beam painter ─────────────────────────────────────────────────────
class _ShimmerPainter extends CustomPainter {
  final double x;
  const _ShimmerPainter({required this.x});

  @override
  void paint(Canvas canvas, Size size) {
    final beamX = size.width * x;
    canvas.save();
    canvas.transform(
      Matrix4(
        math.cos(math.pi / 10),
        math.sin(math.pi / 10),
        0,
        0,
        -math.sin(math.pi / 10),
        math.cos(math.pi / 10),
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        -size.height * .2,
        0,
        1,
      ).storage,
    );
    canvas.drawRect(
      Rect.fromLTWH(beamX, -20, size.width * .20, size.height * 1.6),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: .06),
            Colors.white.withValues(alpha: .10),
            Colors.white.withValues(alpha: .06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(beamX, 0, size.width * .20, size.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.x != x;
}

// ─── Shortcut card ────────────────────────────────────────────────────────────
class MoreShortcutCard extends StatelessWidget {
  const MoreShortcutCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressSurface(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBadge(icon: icon, accent: accent, size: 40),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: _text(context),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: _muted(context),
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section heading ──────────────────────────────────────────────────────────
class MoreSectionHeading extends StatelessWidget {
  const MoreSectionHeading({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
        color: _muted(context),
      ),
    ),
  );
}

// ─── Menu group ───────────────────────────────────────────────────────────────
class MoreMenuGroup extends StatelessWidget {
  const MoreMenuGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surface(context),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border(context)),
      boxShadow: [
        BoxShadow(
          color: const Color(
            0xFF5F2D82,
          ).withValues(alpha: _isDark(context) ? .08 : .04),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: -4,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.only(left: 68),
                color: _border(context),
              ),
            children[i],
          ],
        ],
      ),
    ),
  );
}

// ─── Menu row ─────────────────────────────────────────────────────────────────
class MoreMenuRow extends StatefulWidget {
  const MoreMenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = _purple,
    this.onTap,
    this.trailing,
    this.titleColor,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<MoreMenuRow> createState() => _MoreMenuRowState();
}

class _MoreMenuRowState extends State<MoreMenuRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: .97,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.onTap == null && widget.trailing == null) return;
    HapticFeedback.selectionClick();
    _ctrl.reverse();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    final content = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: disabled ? 1.0 : _scale.value, child: child),
      child: InkWell(
        onTap: widget.trailing != null ? null : _onTap,
        onTapDown: widget.trailing != null
            ? null
            : (_) {
                if (!disabled) _ctrl.forward();
              },
        onTapCancel: () => _ctrl.reverse(),
        splashColor: widget.accent.withValues(alpha: .08),
        highlightColor: widget.accent.withValues(alpha: .05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _IconBadge(icon: widget.icon, accent: widget.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: widget.titleColor ?? _text(context),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        color: _muted(context),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              widget.trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: _muted(context),
                  ),
            ],
          ),
        ),
      ),
    );
    if (widget.trailing != null) return MergeSemantics(child: content);
    return content;
  }
}

// ─── Icon badge ───────────────────────────────────────────────────────────────
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.accent, this.size = 38});
  final IconData icon;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _isDark(context)
        ? Color.lerp(accent, Colors.white, .40)!
        : accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .30),
        border: Border.all(color: color.withValues(alpha: .20), width: .8),
      ),
      child: Icon(icon, color: color, size: size * .50),
    );
  }
}
