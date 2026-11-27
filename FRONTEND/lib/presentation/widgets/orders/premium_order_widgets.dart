import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:lesgo/core/theme/app_tokens.dart';

import '../common/service_icon.dart';

const _brand = Color(0xFF5F2D82);

/// Cleans up the repeated pieces in addresses such as
/// "Claveria, Cagayan, Claveria, Cagayan Valley" so they read once.
class OrderAddress {
  const OrderAddress._();

  static String tidy(String raw) {
    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final seen = <String>{};
    final unique = <String>[];
    for (final p in parts) {
      if (seen.add(p.toLowerCase())) unique.add(p);
    }
    // "Cagayan" is redundant next to "Cagayan Valley".
    final kept = unique.where((p) {
      final lower = p.toLowerCase();
      return !unique.any((o) {
        final ol = o.toLowerCase();
        return ol != lower && ol.startsWith('$lower ');
      });
    }).toList();
    return kept.join(', ');
  }

  /// First segment is the place, the rest is the area.
  static (String title, String area) split(String raw) {
    final tidy0 = tidy(raw);
    final i = tidy0.indexOf(',');
    if (i < 0) return (tidy0, '');
    return (tidy0.substring(0, i).trim(), tidy0.substring(i + 1).trim());
  }
}

/// Fades and slides its child up, staggered by [index]. Timer-free, so it is
/// safe in widget tests.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index.clamp(0, 6)) * 70;
    final total = 420 + delay;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.border(context, const Color(0xFFE3DAEC));
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(c)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const dash = 5.0, gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), p);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A soft white card with a faint brand-tinted shadow.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppCard.decoration(context, radius: radius).copyWith(
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: AppColors.accent(context, _brand).withValues(alpha: 0.75),
      ),
    );
  }
}

enum HeroTone { active, success, danger }

/// The status hero: service, state, a clear headline and a stepper.
class OrderHero extends StatelessWidget {
  const OrderHero({
    super.key,
    required this.service,
    required this.headline,
    required this.statusLabel,
    required this.statusIcon,
    this.date,
    this.caption,
    this.tone = HeroTone.active,
    this.stepLabels = const [],
    this.stepIndex = 0,
  });

  final String service;
  final String headline;
  final String statusLabel;
  final IconData statusIcon;
  final String? date;
  final String? caption;
  final HeroTone tone;
  final List<String> stepLabels;
  final int stepIndex;

  List<Color> get _colors => switch (tone) {
    HeroTone.active => const [Color(0xFF3F1B5C), Color(0xFF7B3FA8)],
    HeroTone.success => const [Color(0xFF14573A), Color(0xFF2E9E5B)],
    HeroTone.danger => const [Color(0xFF4A1F2A), Color(0xFFB5384A)],
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _Orb(size: 170, alpha: 0.10),
            ),
            Positioned(
              left: -30,
              bottom: -60,
              child: _Orb(size: 140, alpha: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ServiceIcon(service, size: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service,
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (date != null)
                              Text(
                                date!,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.38,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    headline,
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (caption != null && caption!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      caption!,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                  if (stepLabels.length > 1) ...[
                    const SizedBox(height: 22),
                    OrderStepper(labels: stepLabels, index: stepIndex),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// Dots joined by a line, light on the hero gradient.
class OrderStepper extends StatelessWidget {
  const OrderStepper({
    super.key,
    required this.labels,
    required this.index,
    this.light = false,
  });

  final List<String> labels;
  final int index;

  /// Draw for a white page (purple on grey) instead of the dark hero.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    final on = light ? AppColors.accent(context, _brand) : Colors.white;
    final off = light
        ? AppColors.border(context, const Color(0xFFE6DFEE))
        : Colors.white.withValues(alpha: 0.28);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < n; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= index ? on : off),
                        ),
                      ),
                      _Dot(done: i < index, current: i == index, light: light),
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i == n - 1
                              ? Colors.transparent
                              : (i < index ? on : off),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 10,
                    fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                    color: Colors.white.withValues(alpha: i <= index ? 1 : 0.6),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.done, required this.current, this.light = false});

  final bool done;
  final bool current;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final on = light ? AppColors.accent(context, _brand) : Colors.white;
    final off = light
        ? AppColors.border(context, const Color(0xFFE6DFEE))
        : Colors.white.withValues(alpha: 0.28);
    if (current) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on.withValues(alpha: light ? 0.16 : 0.3),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(shape: BoxShape.circle, color: on),
        ),
      );
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(shape: BoxShape.circle, color: done ? on : off),
      child: done
          ? Icon(
              Icons.check_rounded,
              size: 10,
              color: light ? Colors.white : const Color(0xFF3F1B5C),
            )
          : null,
    );
  }
}

/// Pickup and drop-off as a timeline with cleaned-up addresses.
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.pickupLabel = 'Pickup',
    this.dropoffLabel = 'Drop-off',
    this.title = 'Route',
    this.flat = false,
  });

  /// No card behind it: just type on the page background.
  final bool flat;
  final String pickup;
  final String dropoff;
  final String pickupLabel;
  final String dropoffLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        SizedBox(height: flat ? 18 : 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const SizedBox(height: 3),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E9E5B).withValues(alpha: 0.18),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2E9E5B),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF2E9E5B), Color(0xFFE5484D)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: Color(0xFFE5484D),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stop(context, pickupLabel, pickup),
                    const SizedBox(height: 18),
                    _stop(context, dropoffLabel, dropoff),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (flat)
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: body,
      );
    return PremiumCard(child: body);
  }

  Widget _stop(BuildContext context, String label, String address) {
    final (name, area) = OrderAddress.split(address);
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: AppColors.foreground(context, Colors.grey[500]!),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name.isEmpty ? '—' : name,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: flat ? 18 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
            height: 1.2,
            color: AppColors.foreground(context, Colors.black87),
          ),
        ),
        if (area.isNotEmpty)
          Text(
            area,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12.5,
              height: 1.3,
              color: muted,
            ),
          ),
      ],
    );
  }
}

class ReceiptItem {
  const ReceiptItem({required this.qty, required this.name, this.price});

  final int qty;
  final String name;
  final String? price;
}

class ReceiptRow {
  const ReceiptRow(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;
}

/// Items, price lines and a big total, with a payment strip at the bottom.
class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    this.items = const [],
    required this.rows,
    required this.total,
    this.totalLabel = 'Total',
    this.footer,
    this.title = 'Your order',
    this.flat = false,
  });

  /// No card behind it: just type on the page background.
  final bool flat;
  final List<ReceiptItem> items;
  final List<ReceiptRow> rows;
  final String total;
  final String totalLabel;
  final String title;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _brand);
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    final text = AppColors.foreground(context, Colors.black87);
    return Container(
      width: double.infinity,
      decoration: flat
          ? null
          : AppCard.decoration(context, radius: 22).copyWith(
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : [
                      BoxShadow(
                        color: _brand.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(flat ? 0 : 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: flat
                  ? const EdgeInsets.fromLTRB(4, 0, 4, 14)
                  : const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isNotEmpty) ...[
                    SectionLabel(title),
                    const SizedBox(height: 12),
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(minWidth: 30),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${items[i].qty}×',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                items[i].name,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: text,
                                ),
                              ),
                            ),
                          ),
                          if (items[i].price != null)
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3, left: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    items[i].price!,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: text,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const DashedDivider(),
                    const SizedBox(height: 14),
                  ],
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              r.label,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 13.5,
                                color: muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                r.value,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: r.color ?? text,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        totalLabel,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: flat ? 17 : 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: text,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            total,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: flat ? 32 : 26,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: flat ? -0.8 : 0,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (footer != null && flat) ...[
              const SizedBox(height: 4),
              Divider(
                height: 1,
                color: AppColors.border(context, const Color(0xFFEEE8F3)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                child: footer,
              ),
            ] else if (footer != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                color: accent.withValues(alpha: 0.06),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Paid with Cash" on the left, a status chip on the right.
class PaymentStrip extends StatelessWidget {
  const PaymentStrip({
    super.key,
    required this.method,
    required this.status,
    required this.statusColor,
  });

  final String method;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    return Row(
      children: [
        Icon(Icons.payments_outlined, size: 18, color: muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            method,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
        ),
        if (status.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.38,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A full-width brand button: filled purple gradient, or a quiet outline.
class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.danger = false,
    this.outlined = false,
    this.flat = false,
  });

  /// A solid brand fill with no glow, for use on a plain page.
  final bool flat;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool danger;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final base = danger ? const Color(0xFFD63B45) : _brand;
    final fg = outlined
        ? (danger ? base : AppColors.accent(context, _brand))
        : Colors.white;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 19, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ],
      ],
    );
    final radius = BorderRadius.circular(16);
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: outlined || flat || !enabled
              ? null
              : [
                  BoxShadow(
                    color: base.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: flat && !outlined ? base : null,
              gradient: outlined || flat
                  ? null
                  : LinearGradient(
                      colors: danger
                          ? const [Color(0xFFD63B45), Color(0xFFB02A35)]
                          : const [Color(0xFF6B34A0), Color(0xFF4A1F68)],
                    ),
              border: outlined
                  ? Border.all(color: base.withValues(alpha: 0.55), width: 1.4)
                  : null,
            ),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact gradient status banner for bottom sheets.
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tone = HeroTone.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final HeroTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      HeroTone.active => const [Color(0xFF3F1B5C), Color(0xFF7B3FA8)],
      HeroTone.success => const [Color(0xFF14573A), Color(0xFF2E9E5B)],
      HeroTone.danger => const [Color(0xFF4A1F2A), Color(0xFFB5384A)],
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12.5,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Restaurant" row with the service icon and a tidied name.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.label,
    required this.name,
    this.address,
  });

  final String label;
  final String name;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final (title, area) = address == null
        ? OrderAddress.split(name)
        : (name, address!);
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(
        children: [
          const ServiceIcon('LesEat', size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(label),
                const SizedBox(height: 3),
                Text(
                  title.isEmpty ? name : title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground(context, Colors.black87),
                  ),
                ),
                if (area.isNotEmpty)
                  Text(
                    area,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12.5,
                      color: AppColors.foreground(context, Colors.grey[600]!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A calm, flat status header: who, when, one quiet status pill, and for an
/// active order a slim progress line. No gradients.
class OrderStatusHeader extends StatelessWidget {
  const OrderStatusHeader({
    super.key,
    required this.service,
    required this.statusLabel,
    required this.tone,
    this.date,
    this.headline,
    this.caption,
    this.stepLabels = const [],
    this.stepIndex = 0,
  });

  final String service;
  final String statusLabel;
  final HeroTone tone;
  final String? date;
  final String? headline;
  final String? caption;
  final List<String> stepLabels;
  final int stepIndex;

  Color get _color => switch (tone) {
    HeroTone.active => const Color(0xFF5F2D82),
    HeroTone.success => const Color(0xFF2E9E5B),
    HeroTone.danger => const Color(0xFFE5484D),
  };

  @override
  Widget build(BuildContext context) {
    final c = _color;
    final muted = AppColors.foreground(context, Colors.grey[600]!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ServiceIcon(service, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.foreground(
                          context,
                          const Color(0xFF1F1530),
                        ),
                      ),
                    ),
                    if (date != null)
                      Text(
                        date!,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12.5,
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (headline != null && headline!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              headline!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.25,
                color: AppColors.foreground(context, const Color(0xFF1F1530)),
              ),
            ),
          ],
          if (caption != null && caption!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: muted,
              ),
            ),
          ],
          if (stepLabels.length > 1) ...[
            const SizedBox(height: 18),
            OrderStepper(labels: stepLabels, index: stepIndex, light: true),
          ],
        ],
      ),
    );
  }
}

/// Why an order was cancelled: a quiet note with a thin red rule, not a box.
class CancellationNote extends StatelessWidget {
  const CancellationNote({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE5484D);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: red.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REASON FOR CANCELLATION',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: red.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.3,
                      color: AppColors.foreground(
                        context,
                        const Color(0xFF1F1530),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
