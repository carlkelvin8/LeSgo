import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
