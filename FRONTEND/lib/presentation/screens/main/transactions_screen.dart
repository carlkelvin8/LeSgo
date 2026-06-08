import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/transactions/transactions_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/common/payment_status_badge.dart';
import '../../widgets/transactions/order_transaction_detail_sheet.dart';
import '../../../core/services/order_receipt_service.dart';
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
  bool _showFilters = false;
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
        SnackBarUtils.showError(context, 'Could not generate receipt. Try again.');
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
    final isActive = transaction.status == TransactionStatus.pending;
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
    final double deliveryFee = transaction.amount > itemsTotal ? transaction.amount - itemsTotal : 0.0;

    final orderData = <String, dynamic>{
      'id': int.tryParse(orderId) ?? 0,
      'status': transaction.rawStatus,
      'estimated_fare': transaction.amount,
      'actual_fare': transaction.amount,
      'pickup_address': transaction.pickupLocation,
      'dropoff_address': transaction.dropoffLocation,
      // For LesEat: pickup is restaurant name
      'restaurantName': transaction.serviceId == 3 ? transaction.pickupLocation : null,
      // Fare breakdown for LesGo/LesRide tracking screen
      'baseFee': transaction.amount > 0 ? 40.0 : 0.0,
      'distanceFee': transaction.amount > 40.0 ? transaction.amount - 40.0 : 0.0,
      'total': transaction.amount,
      'subtotal': itemsTotal,
      'deliveryFee': deliveryFee,
      'paymentMethod': 'Cash',
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
        decoration: const BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}PHP ${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
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
                  color: Colors.grey[600],
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
                foregroundColor: const Color(0xFF5F2D82),
                side: const BorderSide(color: Color(0xFF5F2D82)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'failed': return 'Failed';
      default: return raw.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsProvider);
    final transactions = transactionsState.filteredTransactions;
    final hasActiveFilters = transactionsState.selectedService != null ||
        transactionsState.selectedStatus != null ||
        transactionsState.selectedKind != null ||
        transactionsState.selectedPaymentStatus != null ||
        transactionsState.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: AuthHeader(
                          title: 'Transactions',
                        ),
                      ),
                      // Test button for debugging
                      if (kDebugMode)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.blue),
                          onPressed: () {
                            print('🔵 Manual refresh button pressed');
                            ref.read(transactionsProvider.notifier).refreshTransactions();
                          },
                        ),
                      // Filter toggle button
                      IconButton(
                        icon: Icon(
                          _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                          color: hasActiveFilters ? const Color(0xFF5F2D82) : Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // Search bar
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search orders, LesPay, reference...',
                      hintStyle: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey[400],
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(transactionsProvider.notifier).searchOrders('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 16),
                        vertical: ResponsiveUtils.spacing(context, 12),
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(transactionsProvider.notifier).searchOrders(value);
                      setState(() {});
                    },
                  ),
                  
                  // Filters section
                  if (_showFilters) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildFiltersSection(context, transactionsState),
                  ],
                  
                  // Active filters chips
                  if (hasActiveFilters && !_showFilters) ...[
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    _buildActiveFiltersChips(context, transactionsState),
                  ],
                ],
              ),
            ),
            
            // Divider line
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            
            // Results count
            if (transactions.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                  vertical: ResponsiveUtils.spacing(context, 8),
                ),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Text(
                      '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'} found',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                    ),
                    if (hasActiveFilters) ...[
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(transactionsProvider.notifier).clearFilters();
                          setState(() {});
                        },
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: const Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            // Transactions List
            Expanded(
              child: transactionsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                      ),
                    )
                  : transactionsState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                              Text(
                                'Error loading transactions',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                              Text(
                                transactionsState.error!,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 14),
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(transactionsProvider.notifier).refreshTransactions();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5F2D82),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : transactions.isEmpty
                          ? _buildEmptyState(context, hasActiveFilters)
                          : RefreshIndicator(
                              onRefresh: () => ref.read(transactionsProvider.notifier).refreshTransactions(),
                              color: const Color(0xFF5F2D82),
                              child: ListView.builder(
                                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = transactions[index];
                                  return TransactionListItem(
                                    transaction: transaction,
                                    index: index + 1,
                                    onTap: () => _openOrderDetail(context, transaction),
                                    onReorder: () async {
                                      await ref.read(transactionsProvider.notifier).reorderTransaction(transaction.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Order placed successfully!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
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
            color: Colors.grey[700],
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
            _buildFilterChip(context, 'Orders', state.selectedKind == 'order', () {
              ref.read(transactionsProvider.notifier).filterByKind('order');
            }),
            _buildFilterChip(context, 'LesPay', state.selectedKind == 'wallet', () {
              ref.read(transactionsProvider.notifier).filterByKind('wallet');
            }),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        Text(
          'Payment',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(context, 'All', state.selectedPaymentStatus == null, () {
              ref.read(transactionsProvider.notifier).filterByPaymentStatus(null);
            }),
            _buildFilterChip(context, 'Paid', state.selectedPaymentStatus == 'paid', () {
              ref.read(transactionsProvider.notifier).filterByPaymentStatus('paid');
            }),
            _buildFilterChip(context, 'Pending', state.selectedPaymentStatus == 'pending', () {
              ref.read(transactionsProvider.notifier).filterByPaymentStatus('pending');
            }),
            _buildFilterChip(context, 'Failed', state.selectedPaymentStatus == 'failed', () {
              ref.read(transactionsProvider.notifier).filterByPaymentStatus('failed');
            }),
            _buildFilterChip(context, 'Refunded', state.selectedPaymentStatus == 'refunded', () {
              ref.read(transactionsProvider.notifier).filterByPaymentStatus('refunded');
            }),
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
            color: Colors.grey[700],
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
            _buildFilterChip(context, 'LesGo', state.selectedService == 'LesGo', () {
              ref.read(transactionsProvider.notifier).filterByService('LesGo');
            }),
            _buildFilterChip(context, 'LesRide', state.selectedService == 'LesRide', () {
              ref.read(transactionsProvider.notifier).filterByService('LesRide');
            }),
            _buildFilterChip(context, 'LesEat', state.selectedService == 'LesEat', () {
              ref.read(transactionsProvider.notifier).filterByService('LesEat');
            }),
            _buildFilterChip(context, 'LesBuy', state.selectedService == 'LesBuy', () {
              ref.read(transactionsProvider.notifier).filterByService('LesBuy');
            }),
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
            color: Colors.grey[700],
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
            _buildFilterChip(context, 'Completed', state.selectedStatus == 'completed', () {
              ref.read(transactionsProvider.notifier).filterByStatus('completed');
            }),
            _buildFilterChip(context, 'Pending', state.selectedStatus == 'pending', () {
              ref.read(transactionsProvider.notifier).filterByStatus('pending');
            }),
            _buildFilterChip(context, 'Cancelled', state.selectedStatus == 'cancelled', () {
              ref.read(transactionsProvider.notifier).filterByStatus('cancelled');
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(BuildContext context, TransactionsState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (state.selectedKind != null)
          _buildActiveChip(context, state.selectedKind == 'wallet' ? 'LesPay' : 'Orders', () {
            ref.read(transactionsProvider.notifier).filterByKind(null);
          }),
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

  Widget _buildActiveChip(BuildContext context, String label, VoidCallback onRemove) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 12),
        vertical: ResponsiveUtils.spacing(context, 6),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF5F2D82).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5F2D82)),
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
              color: const Color(0xFF5F2D82),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Color(0xFF5F2D82),
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
            color: Colors.grey[400],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Text(
            hasFilters ? 'No transactions found' : 'No transactions yet',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
              color: Colors.grey[600],
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
                backgroundColor: const Color(0xFF5F2D82),
              ),
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}
