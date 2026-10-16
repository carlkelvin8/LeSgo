import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_shift_provider.dart';

class RiderShiftSummarySheet extends ConsumerStatefulWidget {
  const RiderShiftSummarySheet({super.key});

  @override
  ConsumerState<RiderShiftSummarySheet> createState() => _RiderShiftSummarySheetState();
}

class _RiderShiftSummarySheetState extends ConsumerState<RiderShiftSummarySheet> {
  RiderShiftSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifier = ref.read(riderShiftProvider);
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final summary = await notifier.calculateSummary();
      await notifier.clearShiftStart();
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = const Color(0xFF5F2D82);
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final fg = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppLocalization.translate('shift_summary', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 20),
                fontWeight: FontWeight.w900,
                color: fg,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalization.translate('heres_how_shift_went', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: fg.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalization.translate('could_not_load_summary', lang),
                      style: TextStyle(color: fg.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              )
            else
              _buildSummaryContent(context, primaryPurple, fg),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context, Color primaryPurple, Color fg) {
    final s = _summary!;
    final lang = ref.watch(appLanguageProvider);

    return Column(
      children: [
        _StatCard(
          icon: Icons.access_time,
          label: AppLocalization.translate('shift_duration', lang),
          value: _formatDuration(s.shiftDuration),
          color: primaryPurple,
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.delivery_dining,
          label: AppLocalization.translate('completed_trips', lang),
          value: '${s.totalTrips}',
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.cancel_outlined,
          label: AppLocalization.translate('cancelled', lang),
          value: '${s.cancelledTrips}',
          color: Colors.orange.shade700,
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.monetization_on,
          label: AppLocalization.translate('total_earnings', lang),
          value: 'PHP ${NumberFormat('#,##0.00').format(s.totalEarnings)}',
          color: const Color(0xFF2E7D32),
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.route,
          label: AppLocalization.translate('total_distance', lang),
          value: '${s.totalDistanceKm.toStringAsFixed(1)} km',
          color: primaryPurple,
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.trending_up,
          label: AppLocalization.translate('avg_per_trip', lang),
          value: 'PHP ${NumberFormat('#,##0.00').format(s.averageEarningsPerTrip)}',
          color: primaryPurple,
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalization.translate('ok', lang),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 18),
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: color.withValues(alpha: 0.8),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 15),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
