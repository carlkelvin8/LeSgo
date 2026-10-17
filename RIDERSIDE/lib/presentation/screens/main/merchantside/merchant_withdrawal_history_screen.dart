import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/data_source/dto/merchant/withdrawal_request_dto.dart';
import '../../../../data/data_source/merchant_withdrawal_datasource.dart';

class MerchantWithdrawalHistoryScreen extends ConsumerStatefulWidget {
  const MerchantWithdrawalHistoryScreen({super.key});

  @override
  ConsumerState<MerchantWithdrawalHistoryScreen> createState() =>
      _MerchantWithdrawalHistoryScreenState();
}

class _MerchantWithdrawalHistoryScreenState
    extends ConsumerState<MerchantWithdrawalHistoryScreen> {
  final _dataSource = MerchantWithdrawalDataSource();
  List<WithdrawalRequestDto> _withdrawals = [];
  bool _isLoading = true;
  String? _error;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _dataSource.getWithdrawals(
        status: _filterStatus,
        perPage: 50,
      );
      setState(() {
        _withdrawals = result.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelWithdrawal(WithdrawalRequestDto withdrawal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Withdrawal?'),
        content: Text(
          'Are you sure you want to cancel this withdrawal request for ${withdrawal.amount.toStringAsFixed(2)} PHP?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _dataSource.cancelWithdrawal(withdrawal.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadWithdrawals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0A18) : const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A0A2E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Withdrawal History',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (value) {
              setState(() {
                _filterStatus = value == 'all' ? null : value;
              });
              _loadWithdrawals();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Requests'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'processing',
                child: Text('Processing'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Cancelled'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWithdrawals,
        color: const Color(0xFF5F2D82),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5F2D82),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.red.withValues(alpha: .5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadWithdrawals,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _withdrawals.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 64,
                                color: isDark
                                    ? const Color(0xFF2E2540)
                                    : const Color(0xFFE5E5E5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _filterStatus == null
                                    ? 'No withdrawal requests yet'
                                    : 'No ${_filterStatus!} withdrawals',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF9A85B8)
                                      : const Color(0xFF7A5A9A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your withdrawal requests will appear here',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFF6A5578)
                                      : const Color(0xFF9A85B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _withdrawals.length,
                        itemBuilder: (context, index) {
                          final withdrawal = _withdrawals[index];
                          return _WithdrawalCard(
                            withdrawal: withdrawal,
                            isDark: isDark,
                            onCancel: () => _cancelWithdrawal(withdrawal),
                          );
                        },
                      ),
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalRequestDto withdrawal;
  final bool isDark;
  final VoidCallback onCancel;

  const _WithdrawalCard({
    required this.withdrawal,
    required this.isDark,
    required this.onCancel,
  });

  Color _getStatusColor() {
    switch (withdrawal.status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final createdDate = DateTime.tryParse(withdrawal.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1730) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _showDetails(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: .3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            withdrawal.statusLabel,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Date
                    if (createdDate != null)
                      Text(
                        dateFormat.format(createdDate),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF9A85B8)
                              : const Color(0xFF7A5A9A),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Amount
                Text(
                  'PHP ${withdrawal.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Payout method
                Row(
                  children: [
                    Icon(
                      withdrawal.payoutMethod == 'gcash'
                          ? Icons.smartphone_rounded
                          : withdrawal.payoutMethod == 'maya'
                              ? Icons.credit_card_rounded
                              : Icons.account_balance_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF9A85B8)
                          : const Color(0xFF7A5A9A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      withdrawal.payoutMethodLabel,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF9A85B8)
                            : const Color(0xFF7A5A9A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9A85B8)
                            : const Color(0xFF7A5A9A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        withdrawal.payoutAccountNumber,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF9A85B8)
                              : const Color(0xFF7A5A9A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Cancel button for pending requests
                if (withdrawal.canBeCancelled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawalDetailSheet(withdrawal: withdrawal),
    );
  }
}

class _WithdrawalDetailSheet extends StatelessWidget {
  final WithdrawalRequestDto withdrawal;

  const _WithdrawalDetailSheet({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy \'at\' hh:mm a');

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A0A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2E2540)
                        : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Withdrawal Details',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                ),
              ),
              const SizedBox(height: 24),
              _DetailRow('Reference', withdrawal.referenceNumber ?? 'N/A', isDark),
              _DetailRow('Status', withdrawal.statusLabel, isDark),
              _DetailRow('Amount', 'PHP ${withdrawal.amount.toStringAsFixed(2)}', isDark),
              _DetailRow('Fee', 'PHP ${withdrawal.fee.toStringAsFixed(2)}', isDark),
              _DetailRow(
                'Net Amount',
                'PHP ${withdrawal.netAmount.toStringAsFixed(2)}',
                isDark,
              ),
              _DetailRow('Payout Method', withdrawal.payoutMethodLabel, isDark),
              _DetailRow('Account Number', withdrawal.payoutAccountNumber, isDark),
              _DetailRow('Account Name', withdrawal.payoutAccountName, isDark),
              _DetailRow(
                'Requested',
                dateFormat.format(DateTime.parse(withdrawal.createdAt)),
                isDark,
              ),
              if (withdrawal.rejectionReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Rejection Reason',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF9A85B8)
                        : const Color(0xFF7A5A9A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  withdrawal.rejectionReason!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow(this.label, this.value, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF9A85B8) : const Color(0xFF7A5A9A),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1A0A2E),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
