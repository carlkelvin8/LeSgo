import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../provider/main/lespay/lespay_provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load linked accounts here if needed
    });
  }

  void _showAddPaymentMethodDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (dialogContext) => _AddPaymentMethodDialog(
        parentContext: context,
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
                    
                    // GCash Card
                    _PaymentMethodCard(
                      provider: 'gcash',
                      icon: 'assets/images/wallet/Gcash.svg',
                      title: 'GCash',
                      subtitle: 'Mobile wallet',
                      isLinked: false,
                      onTap: () => _showAddPaymentMethodDialog(context),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    
                    // PayMaya Card
                    _PaymentMethodCard(
                      provider: 'maya',
                      icon: 'assets/images/wallet/Maya.svg',
                      title: 'PayMaya',
                      subtitle: 'Digital wallet',
                      isLinked: false,
                      onTap: () => _showAddPaymentMethodDialog(context),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    
                    // Credit/Debit Card
                    _PaymentMethodCard(
                      provider: 'card',
                      icon: Icons.credit_card,
                      title: 'Credit/Debit Card',
                      subtitle: 'Visa, Mastercard',
                      isLinked: false,
                      onTap: () => _showAddPaymentMethodDialog(context),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                    
                    // Info box
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ℹ️ Payment Information',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          Text(
                            'Payment methods are processed securely through Xendit. Your card information is never stored on our servers.',
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

class _AddPaymentMethodDialog extends ConsumerStatefulWidget {
  final BuildContext parentContext;

  const _AddPaymentMethodDialog({required this.parentContext});

  @override
  ConsumerState<_AddPaymentMethodDialog> createState() =>
      _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState
    extends ConsumerState<_AddPaymentMethodDialog> {
  String? _selectedMethod;
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedMethod == null) {
      SnackBarUtils.showError(context, 'Please select a payment method');
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
          'Payment method added successfully',
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(lespayProvider).error;
        SnackBarUtils.showError(
          context,
          error ?? 'Failed to add payment method',
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
      title: Text(
        'Add Payment Method',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 16),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Payment Method',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
              _buildMethodOption('gcash', 'GCash'),
              _buildMethodOption('maya', 'PayMaya'),
              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Account Number / Mobile Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Account number is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
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
              : const Text('Add Method'),
        ),
      ],
    );
  }

  Widget _buildMethodOption(String value, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: ListTile(
        dense: true,
        title: Text(label),
        leading: Radio<String>(
          value: value,
          groupValue: _selectedMethod,
          onChanged: (v) => setState(() => _selectedMethod = v),
        ),
      ),
    );
  }
}
