import 'package:flutter/material.dart';
import '../profile/profile_panel.dart';
import 'rider_earnings_light_card.dart';

Color earningsCanvas(BuildContext context) =>
    profileDark(context) ? const Color(0xFF171320) : const Color(0xFFFAF9FC);

class EarningsPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const EarningsPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: profileDark(context) ? const Color(0xFF241D30) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: profileDark(context)
            ? const Color(0xFF393044)
            : const Color(0xFFEFEAF4),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .025),
          blurRadius: 18,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class EarningsBalanceCard extends StatelessWidget {
  final String title;
  final double total;
  final int trips;
  final double average;
  final bool compact;
  const EarningsBalanceCard({
    super.key,
    required this.title,
    required this.total,
    required this.trips,
    required this.average,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => RiderEarningsLightCard(
    subtle: compact,
    child: Padding(
      padding: EdgeInsets.all(compact ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: .8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xFFE2CBF5),
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'PHP ${total.toStringAsFixed(2)}',
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: compact ? 34 : 38,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          Divider(height: 1, color: Colors.white.withValues(alpha: .16)),
          SizedBox(height: compact ? 12 : 16),
          Wrap(
            spacing: 20,
            runSpacing: 14,
            children: [
              _BalanceStat(label: 'Completed trips', value: '$trips trips'),
              _BalanceStat(
                label: 'Average per trip',
                value: 'Avg PHP ${average.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  const _BalanceStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 11,
          color: Colors.white.withValues(alpha: .65),
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ],
  );
}

class EarningsEmptyState extends StatelessWidget {
  final String title;
  final String message;
  const EarningsEmptyState({
    super.key,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: profileDark(context)
                ? const Color(0xFF33263F)
                : const Color(0xFFF4EFF9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.insights_rounded,
            size: 28,
            color: Color(0xFF9562B9),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: profileText(context),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            height: 1.6,
            color: profileMuted(context),
          ),
        ),
      ],
    ),
  );
}
