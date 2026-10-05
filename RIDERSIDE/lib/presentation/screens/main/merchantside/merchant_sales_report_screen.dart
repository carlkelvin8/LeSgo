import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/sales_report_service.dart';
import '../../../../core/utils/merchant_order_amount_utils.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../provider/main/merchantside/merchant_orders_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(merchantOrdersProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Sales Reports',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.spacing(context, 16))),
          SliverToBoxAdapter(child: _periodSelector(context)),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.spacing(context, 16))),
          SliverToBoxAdapter(child: _dateRangeTile(context, hp)),
          SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.spacing(context, 16))),
          ordersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(hp),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load orders: $err'),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(merchantOrdersProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
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

              return SliverList(
                delegate: SliverChildListDelegate([
                  _summaryPreview(
                      context, filtered, completed, cancelled, revenue, hp),
                  SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                  _exportButtons(context, filtered, hp),
                  SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _periodSelector(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      child: Row(
        children: ReportPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtils.spacing(context, 8),
            ),
            child: FilterChip(
              label: Text(
                period.name[0].toUpperCase() + period.name.substring(1),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: isSelected ? Colors.white : const Color(0xFF5F2D82),
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: const Color(0xFF5F2D82),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF5F2D82)
                    : Colors.grey.shade300,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedPeriod = period;
                  _recalcDates();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dateRangeTile(BuildContext context, double hp) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: InkWell(
        onTap: _pickStartDate,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: ResponsiveUtils.fontSize(context, 18),
                color: const Color(0xFF5F2D82),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Period',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _dateRangeLabel,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryPreview(
    BuildContext context,
    List<OrderDto> filtered,
    List<OrderDto> completed,
    List<OrderDto> cancelled,
    double revenue,
    double hp,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: ResponsiveUtils.fontSize(context, 18),
                  color: const Color(0xFF5F2D82),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                Text(
                  'Report Summary',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            _summaryRow(context, 'Total Orders', '${filtered.length}'),
            _summaryRow(context, 'Completed', '${completed.length}'),
            _summaryRow(
              context,
              'Cancelled',
              '${cancelled.length}',
            ),
            Divider(height: ResponsiveUtils.spacing(context, 16)),
            _summaryRow(
              context,
              'Total Revenue',
              'PHP ${revenue.toStringAsFixed(2)}',
              isBold: true,
              valueColor: const Color(0xFF5F2D82),
            ),
            _summaryRow(
              context,
              'Avg Order Value',
              'PHP ${completed.isNotEmpty ? (revenue / completed.length).toStringAsFixed(2) : '0.00'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.spacing(context, 6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _exportButtons(
    BuildContext context,
    List<OrderDto> filtered,
    double hp,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Download Report',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 15),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: filtered.isEmpty || _isExporting
                      ? null
                      : () => _exportCsv(filtered),
                  icon: Icon(
                    Icons.table_chart_outlined,
                    size: ResponsiveUtils.fontSize(context, 18),
                  ),
                  label: Text(
                    'CSV',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5F2D82),
                    side: const BorderSide(color: Color(0xFF5F2D82)),
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveUtils.spacing(context, 14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: filtered.isEmpty || _isExporting
                      ? null
                      : () => _exportPdf(filtered),
                  icon: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: ResponsiveUtils.fontSize(context, 18),
                  ),
                  label: Text(
                    'PDF',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.spacing(context, 12),
              ),
              child: Text(
                'No orders found for this period. Try a different range.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 11),
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (_isExporting)
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.spacing(context, 16),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
