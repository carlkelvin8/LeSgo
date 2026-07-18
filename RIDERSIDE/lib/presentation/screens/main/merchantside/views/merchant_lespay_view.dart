import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/services/merchant_wallet_api.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const HomeHeader(
                backgroundColor: Colors.transparent,
                logoColor: Color(0xFF5F2D82),
                borderColor: Colors.transparent,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 16),
              ),
              child: Text(
                'LesPay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 20),
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            // Balance Card (similar to customer)
            _MerchantWalletCard(wallet: wallet, onRefresh: () => notifier.loadWallet()),

            if (wallet.error != null) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    wallet.error!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF5F2D82),
                onRefresh: () async {
                  await notifier.loadWallet();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: ResponsiveUtils.spacing(context, 24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Actions
                      if (notifier.canManageWallet) ...[
                        _ActionItem(
                          icon: Icons.add_circle_outline,
                          title: 'Top up',
                          subtitle: 'Add funds via QR PH',
                          onTap: () => _showTopUpDialog(context, ref),
                        ),
                        _ActionItem(
                          icon: Icons.send_outlined,
                          title: 'Pay Rider',
                          subtitle: 'Send payment to rider',
                          onTap: () => _showPayRiderDialog(context, ref),
                        ),
                      ],

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.spacing(context, 16),
                          vertical: ResponsiveUtils.spacing(context, 12),
                        ),
                        child: Text(
                          'Transaction History',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      if (wallet.isLoading && wallet.transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (wallet.transactions.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 16),
                          ),
                          child: Text(
                            'No transactions yet.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              color: Colors.grey.shade500,
                              fontSize: ResponsiveUtils.fontSize(context, 13),
                            ),
                          ),
                        )
                      else
                        ...wallet.transactions.take(20).map(
                              (tx) => _TransactionTile(transaction: tx),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TopUpDialog(parentContext: context),
    );
  }

  void _showPayRiderDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _PayRiderDialog(parentContext: context),
    );
  }
}

// ─── Wallet Card ───────────────────────────────────────────────────────────────

class _MerchantWalletCard extends StatelessWidget {
  const _MerchantWalletCard({required this.wallet, required this.onRefresh});

  final MerchantWalletState wallet;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRefresh,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
        ),
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5F2D82), Color(0xFF7B3FA0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F2D82).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              wallet.isLoading ? '...' : wallet.balanceFormatted,
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: Colors.white,
                fontSize: ResponsiveUtils.fontSize(context, 32),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'Merchant Wallet',
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: Colors.white.withOpacity(0.85),
                fontSize: ResponsiveUtils.fontSize(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Item ───────────────────────────────────────────────────────────────

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 16),
          vertical: ResponsiveUtils.spacing(context, 14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5F2D82).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF5F2D82), size: 22),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Top Up Dialog (matches customer style) ────────────────────────────────────

class _TopUpDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const _TopUpDialog({required this.parentContext});

  @override
  ConsumerState<_TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends ConsumerState<_TopUpDialog> {
  final _amountController = TextEditingController();
  static const _quickAmounts = [100.0, 200.0, 500.0, 1000.0];
  bool _isProcessing = false;

  double get _parsedAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  double get _fee => _parsedAmount * 0.015;
  double get _total => _parsedAmount + _fee;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _topUp() async {
    final amount = _parsedAmount;
    if (amount < 50) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(content: Text('Minimum top-up is ₱50'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await MerchantWalletApi.createTopUpInvoice(amount: amount);
      if (!mounted) return;

      final invoiceUrl = result['invoice_url']?.toString();
      if (invoiceUrl != null && invoiceUrl.isNotEmpty) {
        Navigator.of(context).pop();
        final uri = Uri.tryParse(invoiceUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        // Refresh wallet after delay
        Future.delayed(const Duration(seconds: 5), () {
          ref.read(merchantWalletProvider.notifier).loadWallet();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
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
    return AlertDialog(
      title: const Text(
        'Top Up (1.5% fee)',
        style: TextStyle(fontFamily: 'TT Fors', fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A 1.5% top-up fee applies. You pay the total below using QR PH.',
            style: TextStyle(fontFamily: 'TT Fors', fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount to add to wallet',
              prefixText: '₱ ',
              border: OutlineInputBorder(),
            ),
            enabled: !_isProcessing,
          ),
          const SizedBox(height: 12),

          // Fee summary
          if (_parsedAmount > 0) ...[
            _summaryRow('Amount to wallet', '₱${_parsedAmount.toStringAsFixed(2)}'),
            _summaryRow('Top-up fee (1.5%)', '₱${_fee.toStringAsFixed(2)}'),
            const Divider(),
            _summaryRow('Total to pay', '₱${_total.toStringAsFixed(2)}', bold: true),
            const SizedBox(height: 8),
          ],

          // Quick amounts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((value) {
              return ChoiceChip(
                label: Text('₱${value.toStringAsFixed(0)}'),
                selected: _amountController.text == value.toStringAsFixed(0),
                onSelected: _isProcessing
                    ? null
                    : (_) {
                        setState(() {
                          _amountController.text = value.toStringAsFixed(0);
                        });
                      },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(fontFamily: 'TT Fors', color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _topUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Continue to payment', style: TextStyle(fontFamily: 'TT Fors')),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontFamily: 'TT Fors', fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          )),
          Text(value, style: TextStyle(
            fontFamily: 'TT Fors', fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: bold ? const Color(0xFF5F2D82) : Colors.black87,
          )),
        ],
      ),
    );
  }
}

// ─── Pay Rider Dialog ──────────────────────────────────────────────────────────

class _PayRiderDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  const _PayRiderDialog({required this.parentContext});

  @override
  ConsumerState<_PayRiderDialog> createState() => _PayRiderDialogState();
}

class _PayRiderDialogState extends ConsumerState<_PayRiderDialog> {
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
    if (amount <= 0) return;

    final notifier = ref.read(merchantWalletProvider.notifier);
    final success = await notifier.transferToRider(
      recipientEmail: _emailController.text.trim(),
      amount: amount,
      note: _noteController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text('₱${amount.toStringAsFixed(2)} sent to rider!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(merchantWalletProvider);

    return AlertDialog(
      title: const Text(
        'Pay Rider',
        style: TextStyle(fontFamily: 'TT Fors', fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Rider email',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (PHP)',
              prefixText: '₱ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(fontFamily: 'TT Fors', color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: wallet.isTransferring ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
            foregroundColor: Colors.white,
          ),
          child: wallet.isTransferring
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send payment', style: TextStyle(fontFamily: 'TT Fors')),
        ),
      ],
    );
  }
}

// ─── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final type = transaction['type']?.toString() ?? '';
    final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final description = transaction['description']?.toString() ?? 'Transaction';
    final date = transaction['created_at']?.toString();
    final isCredit = type == 'credit';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 6),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
              size: 18,
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date != null)
                  Text(
                    date.length > 16 ? date.substring(0, 16) : date,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
