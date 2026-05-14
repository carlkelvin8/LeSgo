import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/transactions/transactions_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../domain/entities/transactions/transaction.dart';
import 'booking/leseat/leseat_order_tracking_screen.dart';
import 'booking/lesbuy/lesbuy_order_tracking_screen.dart';
import 'booking/lesgo/lesgo_order_tracking_screen.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openOrderDetail(BuildContext context, Transaction transaction) {
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
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          '${transaction.serviceName} — Order #${transaction.id}',
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Pickup
                    _detailRow(Icons.circle, Colors.green, 'Pickup', transaction.pickupLocation),
                    const SizedBox(height: 12),
                    // Dropoff
                    _detailRow(Icons.circle, Colors.red, 'Dropoff', transaction.dropoffLocation),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    
                    // Items section for LesBuy/LesEat
                    if (transaction.items != null && transaction.items!.isNotEmpty) ...[
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...transaction.items!.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} ${item.unit != null ? '(${item.unit})' : ''}',
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '${item.quantity}x',
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (item.price != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'PHP ${(item.price! * item.quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5F2D82),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )).toList(),
                    ],
                    
                    // Amount breakdown for LesBuy/LesEat orders
                    if (transaction.items != null && transaction.items!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      
                      // Calculate subtotal from items
                      Builder(
                        builder: (context) {
                          final itemsTotal = transaction.items!.fold<double>(
                            0.0, 
                            (sum, item) => sum + ((item.price ?? 0.0) * item.quantity)
                          );
                          final deliveryFee = transaction.amount - itemsTotal;
                          
                          return Column(
                            children: [
                              // Subtotal
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'PHP ${itemsTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Delivery Fee
                              if (deliveryFee > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Delivery Fee',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'PHP ${deliveryFee.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontFamily: 'TT Fors',
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 8),
                              ],
                              
                              // Total
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'PHP ${transaction.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF5F2D82),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      // For orders without items, show simple total
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'PHP ${transaction.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5F2D82),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 20),

                    // Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          _statusLabel(transaction.rawStatus),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: transaction.status == TransactionStatus.completed
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                          title: 'Order History',
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
                      hintText: 'Search by order ID or location...',
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
                      '${transactions.length} ${transactions.length == 1 ? 'order' : 'orders'} found',
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
                                'Error loading orders',
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
            hasFilters ? 'No orders found' : 'No orders yet',
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
                : 'Your order history will appear here',
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
