import 'package:flutter/material.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:lesgo/core/utils/money.dart';
import 'order_symbol.dart';

/// Colors and surfaces shared by customer order forms and checkout screens.
abstract final class OrderDesign {
  static const sheetRadius = BorderRadius.vertical(top: Radius.circular(30));
  static const cardRadius = BorderRadius.all(Radius.circular(20));

  static Color canvas(BuildContext context) =>
      AppColors.surface(context, const Color(0xFFF8F5FA));

  static Color line(BuildContext context) =>
      AppColors.border(context, const Color(0xFFE9DFEF));

  static Color accent(BuildContext context) =>
      AppColors.accent(context, const Color(0xFF593283));

  static Color tint(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF342542)
      : const Color(0xFFF2E8FA);

  static BoxDecoration card(BuildContext context, {bool highlighted = false}) =>
      BoxDecoration(
        color: highlighted
            ? tint(context)
            : Theme.of(context).colorScheme.surface,
        borderRadius: cardRadius,
        border: Border.all(color: line(context)),
      );

  static BoxDecoration receipt(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: const BorderRadius.all(Radius.circular(16)),
  );

  static BoxDecoration dock(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    border: Border(top: BorderSide(color: line(context))),
  );

  static BoxDecoration sheet(BuildContext context) => BoxDecoration(
    color: canvas(context),
    borderRadius: sheetRadius,
    boxShadow: const [
      BoxShadow(
        color: Color(0x30241A30),
        blurRadius: 24,
        offset: Offset(0, -6),
      ),
    ],
  );
}

class OrderIcon extends StatelessWidget {
  const OrderIcon(
    this.icon, {
    super.key,
    this.mint = false,
    this.muted = false,
    this.size = 42,
  });

  final IconData icon;
  final bool mint;
  final bool muted;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final background = muted
        ? scheme.surfaceContainerHighest
        : mint
        ? (dark ? const Color(0xFF183C34) : const Color(0xFFDDF5EA))
        : OrderDesign.tint(context);
    final foreground = muted
        ? scheme.onSurfaceVariant
        : mint
        ? (dark ? const Color(0xFFB8F1DD) : const Color(0xFF1D5848))
        : OrderDesign.accent(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              Colors.white.withValues(alpha: dark ? .07 : .45),
              background,
            ),
            background,
          ],
        ),
        borderRadius: BorderRadius.circular(size * .34),
        border: Border.all(color: foreground.withValues(alpha: .19)),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: OrderSymbol(icon, size: size * .55, color: foreground),
        ),
      ),
    );
  }
}

class OrderSectionHeading extends StatelessWidget {
  const OrderSectionHeading(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -.35,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
    final leading = icon;
    return Semantics(
      header: true,
      child: leading == null
          ? label
          : Row(
              children: [
                OrderIcon(leading),
                const SizedBox(width: 11),
                Expanded(child: label),
              ],
            ),
    );
  }
}

class OrderIntro extends StatelessWidget {
  const OrderIntro({
    super.key,
    required this.title,
    required this.icon,
    this.detail,
  });

  final String title;
  final IconData icon;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    child: Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29163F), Color(0xFF60378C)],
        ),
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            top: -74,
            end: -31,
            child: IgnorePointer(
              child: Container(
                width: 162,
                height: 162,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x326ECDBA), width: 20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Row(
              children: [
                OrderIcon(icon, mint: true),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            color: Color(0xFFFFF8FF),
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      if (detail case final text?)
                        Text(
                          text,
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            color: Color(0xFFF0E2FF),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                    ],
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

/// A single surface for the pickup and destination rows and their optional notes.
class OrderRouteGroup extends StatelessWidget {
  const OrderRouteGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: OrderDesign.card(context),
    child: Stack(
      children: [
        PositionedDirectional(
          start: 28,
          top: 22,
          bottom: 22,
          child: IgnorePointer(
            child: SizedBox(
              width: 2,
              child: ColoredBox(color: OrderDesign.line(context)),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ],
    ),
  );
}

/// Keeps the existing scroll controller attached as the map sheet collapses.
class OrderBookingSheet extends StatelessWidget {
  const OrderBookingSheet({
    super.key,
    required this.title,
    required this.handle,
    required this.children,
    required this.action,
    this.controller,
  });

  final String title;
  final Widget handle;
  final List<Widget> children;
  final Widget action;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: OrderDesign.sheet(context),
    child: ClipRRect(
      borderRadius: OrderDesign.sheetRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useDock =
              constraints.maxHeight.isFinite &&
              constraints.maxHeight >= 176 &&
              MediaQuery.textScalerOf(context).scale(16) <= 24;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: controller,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  children: [
                    handle,
                    if (constraints.maxHeight >= 245) ...[
                      OrderSectionHeading(title),
                      const SizedBox(height: 8),
                    ],
                    ...children,
                    if (!useDock) ...[const SizedBox(height: 12), action],
                  ],
                ),
              ),
              if (useDock)
                Container(
                  decoration: OrderDesign.dock(context),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: action,
                ),
            ],
          );
        },
      ),
    ),
  );
}

class OrderReceiptHeader extends StatelessWidget {
  const OrderReceiptHeader({
    super.key,
    required this.title,
    required this.detail,
    required this.icon,
    this.subtotal,
  });

  final String title;
  final String detail;
  final IconData icon;
  final String? subtotal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OrderIcon(icon, mint: true, size: 39),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      detail,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtotal case final amount?) ...[
            const SizedBox(height: 12),
            OrderAmountLine(label: 'Item subtotal', amount: amount),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: OrderDesign.line(context)),
        ],
      ),
    );
  }
}

/// A read-only amount display. Callers supply only totals they already know.
class OrderAmountLine extends StatelessWidget {
  const OrderAmountLine({super.key, required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            amount,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: colors.onSurface,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class OrderActionWithTotal extends StatelessWidget {
  const OrderActionWithTotal({super.key, required this.child, this.total});

  final Widget child;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final amount = total;
    if (amount == null) return child;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderAmountLine(label: 'Total', amount: Money.format(amount)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
