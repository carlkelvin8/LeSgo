import '../../widgets/common/segmented_filter_bar.dart';
import 'package:lesgo/core/utils/money.dart';
import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/transactions/transactions_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/common/payment_status_badge.dart';
import '../../widgets/common/retry_widget.dart';
import '../../widgets/transactions/order_transaction_detail_sheet.dart';
import '../../../core/constants/order_status_constants.dart';
import '../../../core/services/order_receipt_service.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/utils/history_grouping.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../domain/entities/transactions/transaction.dart';
import 'booking/leseat/leseat_order_tracking_screen.dart';
import 'booking/lesbuy/lesbuy_order_tracking_screen.dart';
import 'booking/lesgo/lesgo_order_tracking_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  /// `order` | `wallet` — pre-filter when opened from LesPay, etc.
  final String? initialKindFilter;

  const TransactionsScreen({super.key, this.initialKindFilter});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _sharingReceipt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(transactionsProvider.notifier);
      final kind = widget.initialKindFilter?.trim().toLowerCase();
      if (kind != null && kind.isNotEmpty) {
        notifier.filterByKind(kind);
      } else {
        notifier.reapplyFilters();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadReceipt(Transaction transaction) async {
    if (_sharingReceipt) return;
    setState(() => _sharingReceipt = true);
    try {
      await OrderReceiptService.shareTransactionReceipt(transaction);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Could not generate receipt. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharingReceipt = false);
    }
  }

  void _openOrderDetail(BuildContext context, Transaction transaction) {
    if (transaction.isWallet) {
      _showWalletDetailSheet(context, transaction);
      return;
    }

    // Active orders go to tracking screen; completed/cancelled show a summary
    final isActive = OrderStatusConstants.isActive(transaction.rawStatus);
    final orderId = transaction.id;
    double itemsTotal = 0.0;
    List<Map<String, dynamic>> items = [];
    if (transaction.items != null) {
      for (final item in transaction.items!) {
        itemsTotal += (item.price ?? 0.0) * item.quantity;
        items.add({
          'name': item.name,
          'price': item.price ?? 0.0,
          'quantity': item.quantity,
          'total': (item.price ?? 0.0) * item.quantity,
        });
      }
    }
    final double deliveryFee = transaction.amount > itemsTotal
        ? transaction.amount - itemsTotal
        : 0.0;

    final orderData = <String, dynamic>{
      'id': int.tryParse(orderId) ?? 0,
      'status': transaction.rawStatus,
      'estimated_fare': transaction.amount,
      'actual_fare': transaction.amount,
      'pickup_address': transaction.pickupLocation,
      'dropoff_address': transaction.dropoffLocation,
      // For LesEat: pickup is restaurant name
      'restaurantName': transaction.serviceId == 3
          ? transaction.pickupLocation
          : null,
      // Fare breakdown for LesGo/LesRide tracking screen
      // No fare breakdown is stored on a history row: show the total as the
      // base fare rather than inventing a split.
      'baseFee': transaction.amount,
      'distanceFee': 0.0,
      'total': transaction.amount,
      'subtotal': itemsTotal,
      'deliveryFee': deliveryFee,
      'paymentMethod': transaction.paymentMethod ?? 'Cash',
      'items': items,
    };

    if (isActive) {
      // Navigate to the appropriate live tracking screen
      switch (transaction.serviceId) {
        case 3: // LesEat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeseatOrderTrackingScreen(
                orderId: orderId,
                orderType: 'LesEat',
                orderData: orderData,
              ),
            ),
          );
          break;
        case 4: // LesBuy
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LesbuyOrderTrackingScreen(
                orderId: orderId,
                orderType: 'LesBuy',
                orderData: orderData,
              ),
            ),
          );
          break;
        default: // LesGo, LesRide, LesTransport
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LesgoOrderTrackingScreen(
                orderId: orderId,
                orderType: transaction.serviceName,
                orderData: orderData,
              ),
            ),
          );
      }
    } else {
      // Completed/cancelled — show a simple detail bottom sheet
      _showOrderDetailSheet(context, transaction);
    }
  }

  void _showOrderDetailSheet(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => OrderTransactionDetailSheet(
          transaction: transaction,
          controller: controller,
          formatDate: _formatDate,
          statusLabel: _statusLabel,
          sharingReceipt: _sharingReceipt,
          onDownloadReceipt: () {
            Navigator.pop(context);
            _downloadReceipt(transaction);
          },
        ),
      ),
    );
  }

  void _showWalletDetailSheet(BuildContext context, Transaction transaction) {
    final isCredit = transaction.isWalletCredit ?? true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              transaction.walletDescription ?? 'LesPay',
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(transaction.date),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: AppColors.foreground(context, Colors.grey[500]!),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${Money.format(transaction.amount)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isCredit
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                PaymentStatusBadge(status: transaction.paymentStatus),
              ],
            ),
            if (transaction.walletReference?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                'Ref: ${transaction.walletReference}',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: AppColors.foreground(context, Colors.grey[600]!),
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _sharingReceipt
                  ? null
                  : () {
                      Navigator.pop(context);
                      _downloadReceipt(transaction);
                    },
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Download receipt (PDF)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent(context, Color(0xFF5F2D82)),
                side: BorderSide(
                  color: AppColors.accent(context, Color(0xFF5F2D82)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _statusLabel(String raw) {
    return OrderStatusConstants.displayName(raw);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider);
    final transactions = state.filteredTransactions;
    final advancedFilterCount =
        (state.selectedService != null ? 1 : 0) +
        (state.selectedStatus != null ? 1 : 0) +
        (state.selectedPaymentStatus != null &&
                state.selectedPaymentStatus != 'refunded'
            ? 1
            : 0);
    final hasActiveFilters =
        state.selectedService != null ||
        state.selectedStatus != null ||
        state.selectedKind != null ||
        state.selectedPaymentStatus != null ||
        state.searchQuery.isNotEmpty;
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));

    return Scaffold(
      backgroundColor: AppColors.surface(context, const Color(0xFFF8F7FB)),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 8),
                ResponsiveUtils.spacing(context, 8),
              ),
              child: Row(
                children: [
                  const Expanded(child: AuthHeader(title: 'Transactions')),
                  Semantics(
                    button: true,
                    label: advancedFilterCount == 0
                        ? 'Filters'
                        : 'Filters, $advancedFilterCount active',
                    child: IconButton(
                      tooltip: 'Filters',
                      onPressed: () => _openFilterSheet(context),
                      icon: Badge(
                        isLabelVisible: advancedFilterCount > 0,
                        label: Text('$advancedFilterCount'),
                        backgroundColor: accent,
                        child: Icon(
                          advancedFilterCount > 0
                              ? Icons.tune_rounded
                              : Icons.tune_rounded,
                          color: advancedFilterCount > 0
                              ? accent
                              : AppColors.foreground(
                                  context,
                                  Colors.grey[600]!,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search orders, LesPay, reference...',
                      hintStyle: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: AppColors.foreground(context, Colors.grey[400]!),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.foreground(context, Colors.grey[500]!),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(transactionsProvider.notifier)
                                    .searchOrders('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      isDense: true,
                      fillColor: AppColors.surface(context, Colors.grey[100]!),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      ref
                          .read(transactionsProvider.notifier)
                          .searchOrders(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  // Quick type filter; more filters live in the sheet.
                  SegmentedFilterBar<String>(
                    selected: state.selectedPaymentStatus == 'refunded'
                        ? 'refunded'
                        : (state.selectedKind ?? 'all'),
                    onChanged: (v) {
                      final n = ref.read(transactionsProvider.notifier);
                      switch (v) {
                        case 'all':
                          n.filterByKind(null);
                          n.filterByPaymentStatus(null);
                        case 'refunded':
                          n.filterByPaymentStatus(
                            state.selectedPaymentStatus == 'refunded'
                                ? null
                                : 'refunded',
                          );
                        default:
                          n.filterByKind(v);
                      }
                    },
                    segments: const [
                      FilterSegment('all', 'All'),
                      FilterSegment('order', 'Orders'),
                      FilterSegment('wallet', 'LesPay'),
                      FilterSegment('refunded', 'Refunded'),
                    ],
                  ),
                  if (advancedFilterCount > 0) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildActiveFiltersChips(context, state),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.border(context, Colors.grey[200]!),
            ),
            Expanded(
              child: _buildBody(context, state, transactions, hasActiveFilters),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TransactionsState state,
    List<Transaction> transactions,
    bool hasActiveFilters,
  ) {
    if (state.isLoading) return const _TransactionsSkeleton();
    if (state.error != null) {
      return RetryWidget(
        message: state.error!,
        isLoading: false,
        onRetry: () =>
            ref.read(transactionsProvider.notifier).refreshTransactions(),
      );
    }
    if (transactions.isEmpty)
      return _buildEmptyState(context, hasActiveFilters);

    final now = DateTime.now();
    final groups = HistoryGrouping.group<Transaction>(
      transactions,
      (t) => HistoryGrouping.parse(t.date),
      (d) => HistoryGrouping.dayLabel(d, now),
    );
    final rows = <Object>[
      if (state.partialLoadFailed) const _PartialNote(),
      for (final g in groups) ...[g.label, ...g.items],
    ];

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(transactionsProvider.notifier).refreshTransactions(),
      color: AppColors.accent(context, const Color(0xFF5F2D82)),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.spacing(context, 16),
          ResponsiveUtils.spacing(context, 14),
          ResponsiveUtils.spacing(context, 16),
          ResponsiveUtils.spacing(context, 24),
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is _PartialNote) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Some history couldn't load. Pull down to retry.",
                key: const Key('transactions_partial_note'),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: AppColors.foreground(context, Colors.grey[600]!),
                ),
              ),
            );
          }
          if (row is String) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                row.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground(context, const Color(0xFF8B729C)),
                ),
              ),
            );
          }
          final transaction = row as Transaction;
          return TransactionListItem(
            transaction: transaction,
            index: index + 1,
            onTap: () => _openOrderDetail(context, transaction),
            onReorder: () async {
              try {
                final placed = await ref
                    .read(transactionsProvider.notifier)
                    .reorderTransaction(transaction.id);
                if (placed && context.mounted) {
                  SnackBarUtils.showSuccess(
                    context,
                    'Order placed successfully!',
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showError(
                    context,
                    ApiErrorMapper.message(
                      e,
                      fallbackEn: 'Could not place the order again.',
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  /// Service / status / payment filters, in a bottom sheet so the list keeps
  /// the whole screen.
  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface(context, Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final s = ref.watch(transactionsProvider);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(transactionsProvider.notifier)
                                .clearFilters();
                            setState(() {});
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: _buildFiltersSection(context, s),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.buttonFill(context),
                          foregroundColor: AppColors.onButton(context),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Show ${s.filteredTransactions.length} '
                          '${s.filteredTransactions.length == 1 ? 'result' : 'results'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, TransactionsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(context, 'All', state.selectedKind == null, () {
              ref.read(transactionsProvider.notifier).filterByKind(null);
            }),
            _buildFilterChip(
              context,
              'Orders',
              state.selectedKind == 'order',
              () {
                ref.read(transactionsProvider.notifier).filterByKind('order');
              },
            ),
            _buildFilterChip(
              context,
              'LesPay',
              state.selectedKind == 'wallet',
              () {
                ref.read(transactionsProvider.notifier).filterByKind('wallet');
              },
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        Text(
          'Payment',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              context,
              'All',
              state.selectedPaymentStatus == null,
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByPaymentStatus(null);
              },
            ),
            _buildFilterChip(
              context,
              'Paid',
              state.selectedPaymentStatus == 'paid',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByPaymentStatus('paid');
              },
            ),
            _buildFilterChip(
              context,
              'Pending',
              state.selectedPaymentStatus ==
                  OrderStatusConstants.pending_payment,
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByPaymentStatus(
                      OrderStatusConstants.pending_payment,
                    );
              },
            ),
            _buildFilterChip(
              context,
              'Failed',
              state.selectedPaymentStatus == OrderStatusConstants.failed,
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByPaymentStatus(OrderStatusConstants.failed);
              },
            ),
            _buildFilterChip(
              context,
              'Refunded',
              state.selectedPaymentStatus == 'refunded',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByPaymentStatus('refunded');
              },
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        // Service filter
        Text(
          'Service',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(context, 'All', state.selectedService == null, () {
              ref.read(transactionsProvider.notifier).filterByService(null);
            }),
            _buildFilterChip(
              context,
              'LesGo',
              state.selectedService == 'LesGo',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByService('LesGo');
              },
            ),
            _buildFilterChip(
              context,
              'LesRide',
              state.selectedService == 'LesRide',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByService('LesRide');
              },
            ),
            _buildFilterChip(
              context,
              'LesEat',
              state.selectedService == 'LesEat',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByService('LesEat');
              },
            ),
            _buildFilterChip(
              context,
              'LesBuy',
              state.selectedService == 'LesBuy',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByService('LesBuy');
              },
            ),
          ],
        ),

        SizedBox(height: ResponsiveUtils.spacing(context, 16)),

        // Status filter
        Text(
          'Status',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(context, 'All', state.selectedStatus == null, () {
              ref.read(transactionsProvider.notifier).filterByStatus(null);
            }),
            _buildFilterChip(
              context,
              'Completed',
              state.selectedStatus == OrderStatusConstants.completed,
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByStatus(OrderStatusConstants.completed);
              },
            ),
            _buildFilterChip(
              context,
              'Pending',
              state.selectedStatus == OrderStatusConstants.pending,
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByStatus(OrderStatusConstants.pending);
              },
            ),
            _buildFilterChip(
              context,
              'Cancelled',
              state.selectedStatus == 'cancelled',
              () {
                ref
                    .read(transactionsProvider.notifier)
                    .filterByStatus('cancelled');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent(context, Color(0xFF5F2D82))
              : AppColors.surface(context, Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.accent(context, Color(0xFF5F2D82))
                : AppColors.border(context, Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppColors.foreground(context, Colors.grey[700]!),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(
    BuildContext context,
    TransactionsState state,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (state.selectedKind != null)
          _buildActiveChip(
            context,
            state.selectedKind == 'wallet' ? 'LesPay' : 'Orders',
            () {
              ref.read(transactionsProvider.notifier).filterByKind(null);
            },
          ),
        if (state.selectedPaymentStatus != null)
          _buildActiveChip(context, state.selectedPaymentStatus!, () {
            ref.read(transactionsProvider.notifier).filterByPaymentStatus(null);
          }),
        if (state.selectedService != null)
          _buildActiveChip(context, state.selectedService!, () {
            ref.read(transactionsProvider.notifier).filterByService(null);
          }),
        if (state.selectedStatus != null)
          _buildActiveChip(context, state.selectedStatus!, () {
            ref.read(transactionsProvider.notifier).filterByStatus(null);
          }),
        if (state.searchQuery.isNotEmpty)
          _buildActiveChip(context, 'Search: ${state.searchQuery}', () {
            _searchController.clear();
            ref.read(transactionsProvider.notifier).searchOrders('');
            setState(() {});
          }),
      ],
    );
  }

  Widget _buildActiveChip(
    BuildContext context,
    String label,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 12),
        vertical: ResponsiveUtils.spacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: AppColors.accent(
          context,
          Color(0xFF5F2D82),
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent(context, Color(0xFF5F2D82))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              fontWeight: FontWeight.w600,
              color: AppColors.accent(context, Color(0xFF5F2D82)),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close,
                size: 14,
                color: AppColors.accent(context, Color(0xFF5F2D82)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.foreground(context, Colors.grey[400]!),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            hasFilters ? 'No transactions found' : 'No transactions yet',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: AppColors.foreground(context, Colors.black87),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            hasFilters
                ? 'Try adjusting your filters'
                : 'Orders and LesPay wallet activity will appear here',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: AppColors.foreground(context, Colors.grey[600]!),
            ),
          ),
          if (hasFilters) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                ref.read(transactionsProvider.notifier).clearFilters();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonFill(context),
                foregroundColor: AppColors.onButton(context),
              ),
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartialNote {
  const _PartialNote();
}

/// Soft pulsing placeholders while the history loads.
class _TransactionsSkeleton extends StatefulWidget {
  const _TransactionsSkeleton();

  @override
  State<_TransactionsSkeleton> createState() => _TransactionsSkeletonState();
}

class _TransactionsSkeletonState extends State<_TransactionsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = AppColors.surface(context, Colors.grey[200]!);
    Widget block(double w, double h, {double r = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: 0.55 + 0.45 * _c.value,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            block(double.infinity, 150, r: 22),
            const SizedBox(height: 18),
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    block(44, 44, r: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          block(120, 14),
                          const SizedBox(height: 8),
                          block(180, 10),
                        ],
                      ),
                    ),
                    block(60, 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
