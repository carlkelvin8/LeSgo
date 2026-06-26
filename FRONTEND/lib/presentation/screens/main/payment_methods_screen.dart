import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/main/lespay/lespay_provider.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  void _showAddWalletDialog(BuildContext context, {String? initialProvider}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddWalletDialog(
        parentContext: context,
        initialProvider: initialProvider,
      ),
    );
  }

  void _handleCardTap(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Credit / Debit Card',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Card payments are processed securely through Xendit when you top up '
          'LesPay or pay at checkout. No card details are stored on our servers.',
          style: TextStyle(fontFamily: 'TT Fors', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppRouter.push(context, MainRoutes.lespay);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            child: const Text('Go to LesPay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      'Saved Payment Methods',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    _PaymentMethodCard(
                      provider: 'gcash',
                      icon: 'assets/images/wallet/Gcash.svg',
                      title: 'GCash',
                      subtitle: 'Mobile wallet',
                      isLinked: false,
                      onTap: () => _showAddWalletDialog(context, initialProvider: 'gcash'),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    _PaymentMethodCard(
                      provider: 'maya',
                      icon: 'assets/images/wallet/Maya.svg',
                      title: 'PayMaya',
                      subtitle: 'Digital wallet',
                      isLinked: false,
                      onTap: () => _showAddWalletDialog(context, initialProvider: 'maya'),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    _PaymentMethodCard(
                      provider: 'card',
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Visa, Mastercard via Xendit',
                      isLinked: false,
                      onTap: () => _handleCardTap(context),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    Container(
                      padding:
                          EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Information',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            'GCash and PayMaya can be linked to your LesPay wallet. '
                            'Credit and debit cards are charged securely through Xendit '
                            'at checkout or top-up — your card details are never stored '
                            'on our servers.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.blue.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String provider;
  final dynamic icon;
  final String title;
  final String subtitle;
  final bool isLinked;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.provider,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLinked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.spacing(context, 12),
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        leading: icon is String
            ? SvgPicture.asset(
                icon,
                width: 32,
                height: 32,
              )
            : Icon(
                icon as IconData,
                size: 32,
                color: const Color(0xFF5F2D82),
              ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: TextButton(
          onPressed: onTap,
          child: Text(
            isLinked ? 'Linked' : 'Add',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              fontWeight: FontWeight.w600,
              color: isLinked ? Colors.green : const Color(0xFF5F2D82),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddWalletDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;
  final String? initialProvider;

  const _AddWalletDialog({
    required this.parentContext,
    this.initialProvider,
  });

  @override
  ConsumerState<_AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends ConsumerState<_AddWalletDialog> {
  String? _selectedMethod;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialProvider;
  }

  Future<void> _submit() async {
    if (_selectedMethod == null) {
      SnackBarUtils.showError(context, 'Please select GCash or PayMaya');
      return;
    }

    setState(() => _submitting = true);

    try {
      final success = await ref
          .read(lespayProvider.notifier)
          .linkPaymentAccount(_selectedMethod!);

      if (!mounted) return;

      if (success) {
        SnackBarUtils.showSuccess(
          widget.parentContext,
          'Payment method linked successfully',
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(lespayProvider).error;
        SnackBarUtils.showError(
          context,
          error ?? 'Failed to link payment method',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Link Wallet',
        style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a wallet to link to LesPay:',
            style: TextStyle(fontFamily: 'TT Fors'),
          ),
          const SizedBox(height: 12),
          _buildMethodOption('gcash', 'GCash'),
          _buildMethodOption('maya', 'PayMaya'),
          const SizedBox(height: 12),
          Text(
            'You will verify your account through our secure Xendit payment partner.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
          ),
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Link Account'),
        ),
      ],
    );
  }

  Widget _buildMethodOption(String value, String label) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontFamily: 'TT Fors')),
      leading: Radio<String>(
        value: value,
        groupValue: _selectedMethod,
        activeColor: const Color(0xFF5F2D82),
        onChanged: (v) => setState(() => _selectedMethod = v),
      ),
      onTap: () => setState(() => _selectedMethod = value),
    );
  }
}
