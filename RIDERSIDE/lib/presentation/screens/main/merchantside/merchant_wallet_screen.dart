import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/screen_auto_refresh.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../provider/main/merchantside/merchant_wallet_provider.dart';

class MerchantWalletScreen extends ConsumerStatefulWidget {
  const MerchantWalletScreen({super.key});

  @override
  ConsumerState<MerchantWalletScreen> createState() =>
      _MerchantWalletScreenState();
}

class _MerchantWalletScreenState extends ConsumerState<MerchantWalletScreen>
    with WidgetsBindingObserver, AutoRefreshMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() {
    ref.read(merchantWalletProvider.notifier).loadWallet(silent: true);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  Future<void> _showTopUpDialog(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top up LesPay', style: TextStyle(fontFamily: 'TT Fors')),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount (PHP)',
            prefixText: 'PHP ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5F2D82)),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final amount = double.tryParse(amountController.text.trim());
    amountController.dispose();
    if (amount == null || amount < 10) {
      SnackBarUtils.showError(context, 'Enter at least PHP 10.00');
      return;
    }

    final checkout =
        await ref.read(merchantWalletProvider.notifier).startTopUp(amount);
    if (!mounted || checkout == null) return;

    SnackBarUtils.showSuccess(
      context,
      'Payment link created. Complete payment to credit your wallet.',
    );
    await ref.read(merchantWalletProvider.notifier).completeTopUp(checkout);
  }

  Future<void> _showWithdrawDialog(BuildContext context, WidgetRef ref) async {
    final wallet = ref.read(merchantWalletProvider);
    final amountController = TextEditingController();
    var method = wallet.isProviderLinked('gcash') ? 'gcash' : 'maya';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Withdraw', style: TextStyle(fontFamily: 'TT Fors')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available: ${wallet.balanceFormatted}',
                style: const TextStyle(fontFamily: 'TT Fors'),
              ),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount (PHP)'),
              ),
              DropdownButtonFormField<String>(
                value: method,
                items: const [
                  DropdownMenuItem(value: 'gcash', child: Text('GCash')),
                  DropdownMenuItem(value: 'maya', child: Text('Maya')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => method = v);
                },
                decoration: const InputDecoration(labelText: 'Method'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5F2D82)),
              child: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final amount = double.tryParse(amountController.text.trim());
    amountController.dispose();
    if (amount == null || amount <= 0) return;

    final ok = await ref.read(merchantWalletProvider.notifier).withdraw(amount, method);
    if (!mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(context, 'Withdrawal submitted');
    } else {
      SnackBarUtils.showError(context, ref.read(merchantWalletProvider).error ?? 'Withdraw failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(merchantWalletProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'LesPay E-Wallet',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () => ref.read(merchantWalletProvider.notifier).loadWallet(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.spacing(context, 24),
          ),
          children: [
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B59F0), Color(0xFF5F2D82)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: wallet.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            wallet.balanceFormatted,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 28),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (wallet.error != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Text(
                  wallet.error!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5F2D82),
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.spacing(context, 14),
                        ),
                      ),
                      onPressed: wallet.isProcessingTopUp
                          ? null
                          : () => _showTopUpDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Top up',
                        style: TextStyle(fontFamily: 'TT Fors'),
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
                      ),
                      onPressed: () => _showWithdrawDialog(context, ref),
                      icon: const Icon(Icons.remove),
                      label: const Text(
                        'Withdraw',
                        style: TextStyle(fontFamily: 'TT Fors'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8D9F5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: ResponsiveUtils.fontSize(context, 18),
                      color: const Color(0xFF5F2D82),
                    ),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Expanded(
                      child: Text(
                        'When customers pay online (GCash, Maya, or card), their payment is credited to your LesPay e-wallet after the order is paid.',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          color: const Color(0xFF5F2D82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Text(
                'Transaction History',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 17),
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            if (wallet.isLoading && wallet.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (wallet.transactions.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: ResponsiveUtils.spacing(context, 32),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    Text(
                      'No wallet transactions yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...wallet.transactions.map((tx) {
                final type = tx['type']?.toString() ?? 'transaction';
                final amount = tx['amount'];
                final desc = tx['description']?.toString() ?? '';
                final isCredit = type == 'credit';
                final amountStr = amount is num
                    ? amount.toDouble().toStringAsFixed(2)
                    : amount?.toString() ?? '0.00';

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: ResponsiveUtils.spacing(context, 4),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCredit
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                desc.isNotEmpty ? desc : type,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDate(tx['created_at']?.toString()),
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 11),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isCredit ? '+' : '-'}PHP $amountStr',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight: FontWeight.w700,
                            color: isCredit
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
