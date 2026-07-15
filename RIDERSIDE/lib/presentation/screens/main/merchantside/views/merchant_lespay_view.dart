import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/merchant_wallet_api.dart';
import '../../../../../core/utils/merchant_transfer_commission_utils.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_wallet_provider.dart';
import '../../../../widgets/widgets.dart';

class MerchantLespayView extends ConsumerWidget {
  const MerchantLespayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(merchantWalletProvider);
    final notifier = ref.read(merchantWalletProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(0xFF5F2D82),
          onRefresh: () => notifier.loadWallet(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
              vertical: ResponsiveUtils.spacing(context, 16),
            ),
            children: [
              const HomeHeader(
                backgroundColor: Colors.transparent,
                logoColor: Color(0xFF5F2D82),
                borderColor: Color(0x335F2D82),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              Text(
                'LeSpay',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 24),
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF5F2D82),
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 4)),
              Text(
                'Pay riders directly from your merchant wallet.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              _BalanceCard(wallet: wallet),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              if (notifier.canManageWallet)
                _TopUpCard(notifier: notifier, wallet: wallet),
              if (wallet.error != null) ...[
                SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                Text(
                  wallet.error!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.red.shade700,
                  ),
                ),
              ],
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              if (notifier.canManageWallet)
                _PayRiderCard(notifier: notifier, wallet: wallet)
              else
                _RestrictedCard(),
              SizedBox(height: ResponsiveUtils.spacing(context, 24)),
              Text(
                'Recent transactions',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              if (wallet.isLoading && wallet.transactions.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (wallet.transactions.isEmpty)
                Text(
                  'No LesPay activity yet.',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    color: Colors.grey.shade600,
                  ),
                )
              else
                ...wallet.transactions.take(10).map(
                      (tx) => _TransactionTile(transaction: tx),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});

  final MerchantWalletState wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5F2D82), Color(0xFF7B3FA0)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available balance',
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            wallet.isLoading ? '...' : wallet.balanceFormatted,
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: Colors.white,
              fontSize: ResponsiveUtils.fontSize(context, 28),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopUpCard extends ConsumerStatefulWidget {
  const _TopUpCard({required this.notifier, required this.wallet});

  final MerchantWalletNotifier notifier;
  final MerchantWalletState wallet;

  @override
  ConsumerState<_TopUpCard> createState() => _TopUpCardState();
}

class _TopUpCardState extends ConsumerState<_TopUpCard> {
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum top-up is PHP 50'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await MerchantWalletApi.createTopUpInvoice(amount: amount);
      if (!mounted) return;

      final invoiceUrl = result['invoice_url']?.toString();
      if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up invoice created: PHP ${amount.toStringAsFixed(0)}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _amountController.clear();
        // Refresh wallet after a delay to pick up the payment
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) widget.notifier.loadWallet();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Top-up initiated'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _amountController.clear();
        widget.notifier.loadWallet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up failed: ${MerchantWalletApi.extractError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.green.shade200),
      ),
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Top Up Wallet',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (PHP)',
                      hintText: 'Min. 50',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _topUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Top Up', style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayRiderCard extends ConsumerStatefulWidget {
  const _PayRiderCard({required this.notifier, required this.wallet});

  final MerchantWalletNotifier notifier;
  final MerchantWalletState wallet;

  @override
  ConsumerState<_PayRiderCard> createState() => _PayRiderCardState();
}

class _PayRiderCardState extends ConsumerState<_PayRiderCard> {
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final success = await widget.notifier.transferToRider(
      recipientEmail: _emailController.text.trim(),
      amount: amount,
      note: _noteController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sent ${widget.notifier.transferPreview(amount)}',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _amountController.clear();
      _noteController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final preview = amount > 0 ? widget.notifier.transferPreview(amount) : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pay rider',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Rider email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Amount (PHP)',
                border: OutlineInputBorder(),
              ),
            ),
            if (preview != null) ...[
              const SizedBox(height: 8),
              Text(
                preview,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'LesGo fee (${(MerchantTransferCommissionUtils.platformRate * 100).toStringAsFixed(0)}%) is deducted before the rider is credited.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF5F2D82),
                ),
                onPressed: widget.wallet.isTransferring ? null : _submit,
                child: Text(
                  widget.wallet.isTransferring ? 'Sending...' : 'Send payment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestrictedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Your staff role cannot access LesPay payments. Ask the store admin or use a cashier/admin account.',
          style: TextStyle(
            fontFamily: 'TT Fors',
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final type = transaction['type']?.toString() ?? '';
    final amount = transaction['amount']?.toString() ?? '0';
    final description = transaction['description']?.toString() ?? 'Transaction';
    final isCredit = type == 'credit';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isCredit ? Icons.arrow_downward : Icons.arrow_upward,
        color: isCredit ? Colors.green : Colors.red,
      ),
      title: Text(description, style: const TextStyle(fontFamily: 'TT Fors')),
      trailing: Text(
        '${isCredit ? '+' : '-'}PHP $amount',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontWeight: FontWeight.w700,
          color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }
}
