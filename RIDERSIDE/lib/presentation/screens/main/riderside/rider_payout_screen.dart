import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_payout_provider.dart' hide PayoutRecord;
import '../../../provider/main/riderside/rider_payout_provider.dart' show PayoutRecord, RiderPayoutState, riderPayoutProvider, riderPayoutHistoryProvider;

class RiderPayoutScreen extends ConsumerWidget {
  const RiderPayoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load payout data on first build
    ref.listen(riderPayoutProvider, (prev, next) {
      if (prev == null) {
        ref.read(riderPayoutProvider.notifier).loadPayoutData();
      }
    });

    final payoutState = ref.watch(riderPayoutProvider);
    final payoutHistoryAsync = ref.watch(riderPayoutHistoryProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'Wallet & Payouts',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(riderPayoutProvider.notifier).loadPayoutData();
          ref.invalidate(riderPayoutHistoryProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(hp, ResponsiveUtils.spacing(context, 16), hp, 24),
          children: [
            // Balance Cards
            Row(
              children: [
                Expanded(
                  child: _buildBalanceCard(
                    context,
                    label: 'Available Balance',
                    amount: payoutState.availableBalanceFormatted,
                    color: const Color(0xFF4CAF50),
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBalanceCard(
                    context,
                    label: 'Pending',
                    amount: payoutState.pendingBalanceFormatted,
                    color: const Color(0xFFFF9800),
                    icon: Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Balance
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        payoutState.totalBalanceFormatted,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 28),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                      if (payoutState.availableBalance > 0)
                        ElevatedButton.icon(
                          onPressed: () => _showWithdrawalDialog(context, ref, payoutState),
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: Text(
                            'Withdraw',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w600,
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F2D82),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payout History Header
            Text(
              'Withdrawal Requests',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Payout History
            payoutHistoryAsync.when(
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFF5F2D82)),
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Failed to load withdrawal history',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              ),
              data: (payouts) {
                if (payouts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No withdrawal requests yet',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: payouts.map((payout) => _buildPayoutItem(context, payout)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context, {
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutItem(BuildContext context, PayoutRecord payout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: payout.statusColor,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: payout.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPaymentIcon(payout.paymentMethod),
              color: payout.statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PHP ${payout.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: payout.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        payout.statusLabel,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 10),
                          fontWeight: FontWeight.w600,
                          color: payout.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${payout.paymentMethod} • •••${payout.accountNumber.substring(max(0, payout.accountNumber.length - 4))}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(payout.requestedAt),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 10),
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'gcash':
        return Icons.phone_android;
      case 'maya':
        return Icons.phone_iphone;
      case 'bank':
      case 'bankaccount':
        return Icons.account_balance;
      case 'paypal':
        return Icons.credit_card;
      default:
        return Icons.account_balance_wallet;
    }
  }

  void _showWithdrawalDialog(BuildContext context, WidgetRef ref, RiderPayoutState payoutState) {
    showDialog(
      context: context,
      builder: (ctx) => _WithdrawalDialog(
        parentContext: ctx,
        availableBalance: payoutState.availableBalance,
        onWithdraw: (amount, method, account) async {
          try {
            await ref.read(riderPayoutProvider.notifier).requestWithdrawal(
              amount: amount,
              paymentMethod: method,
              accountNumber: account,
            );
            if (ctx.mounted) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Withdrawal request submitted successfully'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
              ref.invalidate(riderPayoutHistoryProvider);
            }
          } catch (e) {
            if (ctx.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _WithdrawalDialog extends StatefulWidget {
  final BuildContext parentContext;
  final double availableBalance;
  final Function(double, String, String) onWithdraw;

  const _WithdrawalDialog({
    required this.parentContext,
    required this.availableBalance,
    required this.onWithdraw,
  });

  @override
  State<_WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<_WithdrawalDialog> {
  late TextEditingController _amountController;
  String _selectedMethod = 'gcash';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Withdraw Funds',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: PHP ${widget.availableBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure your GCash/Maya is linked in the wallet page before withdrawing.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount (PHP)',
                hintText: 'Enter amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: 'PHP ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Method',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedMethod,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'gcash', child: Text('GCash (via PayMongo)')),
                DropdownMenuItem(value: 'maya', child: Text('Maya (via PayMongo)')),
              ],
              onChanged: (val) => setState(() => _selectedMethod = val ?? 'gcash'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  if (amount <= 0 || amount > widget.availableBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid amount')),
                    );
                    return;
                  }

                  setState(() => _isSubmitting = true);
                  await widget.onWithdraw(amount, _selectedMethod, '');
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Withdraw'),
        ),
      ],
    );
  }
}
