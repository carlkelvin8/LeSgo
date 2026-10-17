import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/sales_report_service.dart';
import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../widgets/common/settings_page_kit.dart';

enum ReportPeriod { daily, weekly, monthly }

class MerchantSalesReportScreen extends ConsumerStatefulWidget {
  const MerchantSalesReportScreen({super.key});

  @override
  ConsumerState<MerchantSalesReportScreen> createState() =>
      _MerchantSalesReportScreenState();
}

class _MerchantSalesReportScreenState
    extends ConsumerState<MerchantSalesReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _recalcDates();
  }

  void _recalcDates() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate;
      case ReportPeriod.weekly:
        final weekday = now.weekday;
        _startDate =
            DateTime(now.year, now.month, now.day - (weekday - 1));
        _endDate = _startDate.add(const Duration(days: 6));
      case ReportPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate =
            DateTime(now.year, now.month + 1, 0);
    }
  }

  String get _dateRangeLabel {
    final f = DateFormat('MMM d, yyyy');
    if (_startDate == _endDate) return f.format(_startDate);
    return '${f.format(_startDate)} — ${f.format(_endDate)}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF5F2D82),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_selectedPeriod == ReportPeriod.daily) {
          _endDate = picked;
        } else if (_selectedPeriod == ReportPeriod.weekly) {
          _endDate = picked.add(const Duration(days: 6));
        } else {
          _endDate =
              DateTime(picked.year, picked.month + 1, 0);
        }
      });
    }
  }

  List<OrderDto> _filterByPeriod(List<OrderDto> orders) {
    return orders.where((order) {
      final date = MerchantOrderAmountUtils.earningsDate(order);
      if (date == null) return false;
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  Future<void> _exportCsv(List<OrderDto> filtered) async {
    setState(() => _isExporting = true);
    try {
      await SalesReportService.shareCsv(
        orders: filtered,
        periodLabel: _dateRangeLabel,
        start: _startDate,
        end: _endDate,
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to export CSV');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf(List<OrderDto> filtered) async {
    setState(() => _isExporting = true);
    try {
      await SalesReportService.sharePdf(
        orders: filtered,
        periodLabel: _dateRangeLabel,
        start: _startDate,
        end: _endDate,
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to export PDF');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String get _periodName => switch (_selectedPeriod) {
        ReportPeriod.daily => 'Today',
        ReportPeriod.weekly => 'This week',
        ReportPeriod.monthly => 'This month',
      };

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SettingsKit.appBar(context, ''),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: SettingsKit.brand),
        ),
        error: (err, _) => Center(
          child: SettingsEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Failed to load orders',
            subtitle: '$err',
            actionLabel: 'Retry',
            actionIcon: Icons.refresh_rounded,
            onAction: () => ref.invalidate(merchantOrdersProvider),
          ),
        ),
        data: (orders) {
          final filtered = _filterByPeriod(orders);
          final completed = filtered
              .where((o) => MerchantOrderAmountUtils.isCompleted(o))
              .toList();
          final cancelled = filtered
              .where((o) => MerchantOrderAmountUtils.isCancelled(o))
              .toList();
          final revenue = completed.fold<double>(
            0,
            (s, o) => s + MerchantOrderAmountUtils.foodEarnings(o),
          );
          final avg = completed.isNotEmpty ? revenue / completed.length : 0.0;

          return RefreshIndicator(
            color: SettingsKit.brand,
            onRefresh: () async {
              ref.invalidate(merchantOrdersProvider);
              await ref.read(merchantOrdersProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(hp, 0, hp, 32),
              children: [
                const SettingsPageHeader(
                  title: 'Sales Reports',
                  subtitle: 'Track your earnings and export reports',
                ),
                const SizedBox(height: 20),
                _periodSelector(context),
                const SizedBox(height: 16),
                _revenueCard(context, revenue, avg),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        icon: Icons.receipt_long_outlined,
                        color: SettingsKit.brand,
                        value: '${filtered.length}',
                        label: 'Orders',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricTile(
                        icon: Icons.check_circle_outline_rounded,
                        color: SettingsKit.success,
                        value: '${completed.length}',
                        label: 'Completed',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricTile(
                        icon: Icons.cancel_outlined,
                        color: SettingsKit.danger,
                        value: '${cancelled.length}',
                        label: 'Cancelled',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _completionBar(filtered.length, completed.length),
                const SizedBox(height: 28),
                _exportSection(filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _periodSelector(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SettingsKit.pageBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ReportPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                  _recalcDates();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SettingsKit.brand.withValues(alpha: .12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period.name[0].toUpperCase() + period.name.substring(1),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    color: isSelected ? SettingsKit.brand : SettingsKit.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _revenueCard(BuildContext context, double revenue, double avg) {
    final money = NumberFormat('#,##0.00');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SettingsKit.brandLight, SettingsKit.brand, Color(0xFF3E1460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SettingsKit.brand.withValues(alpha: .25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total revenue · $_periodName',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: .8),
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _pickStartDate,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'PHP ${money.format(revenue)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 30),
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dateRangeLabel,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: Colors.white.withValues(alpha: .75),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up_rounded,
                    size: 18, color: Colors.white.withValues(alpha: .9)),
                const SizedBox(width: 8),
                Text(
                  'Avg order value',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: .85),
                  ),
                ),
                const Spacer(),
                Text(
                  'PHP ${money.format(avg)}',
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: SettingsKit.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: SettingsKit.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _completionBar(int total, int completed) {
    final rate = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SettingsKit.pageBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Completion rate',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SettingsKit.ink,
                ),
              ),
              const Spacer(),
              Text(
                total == 0 ? '—' : '${(rate * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SettingsKit.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: SettingsKit.brand.withValues(alpha: .10),
              valueColor: const AlwaysStoppedAnimation(SettingsKit.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportSection(List<OrderDto> filtered) {
    final disabled = filtered.isEmpty || _isExporting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionLabel(
          'Export report',
          trailing: _isExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SettingsKit.brand,
                  ),
                )
              : null,
        ),
        Row(
          children: [
            Expanded(
              child: _exportTile(
                icon: Icons.table_chart_outlined,
                title: 'CSV',
                subtitle: 'Spreadsheet',
                color: SettingsKit.success,
                onTap: disabled ? null : () => _exportCsv(filtered),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _exportTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'PDF',
                subtitle: 'Printable',
                color: SettingsKit.danger,
                onTap: disabled ? null : () => _exportPdf(filtered),
              ),
            ),
          ],
        ),
        if (filtered.isEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'No orders in this period yet, so there is nothing to export.',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _exportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : .45,
      child: Material(
        color: SettingsKit.pageBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SettingsIconBox(icon: icon, color: color, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: SettingsKit.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          color: SettingsKit.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.download_rounded,
                    size: 18, color: SettingsKit.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
