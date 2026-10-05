import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/utils/app_localization.dart';

Future<void> showRiderCustomerRatingDialog(
  BuildContext context, {
  required int orderId,
  String? customerName,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _RiderCustomerRatingDialog(
      orderId: orderId,
      customerName: customerName,
    ),
  );
}

class _RiderCustomerRatingDialog extends ConsumerStatefulWidget {
  const _RiderCustomerRatingDialog({
    required this.orderId,
    this.customerName,
  });

  final int orderId;
  final String? customerName;

  @override
  ConsumerState<_RiderCustomerRatingDialog> createState() =>
      _RiderCustomerRatingDialogState();
}

class _RiderCustomerRatingDialogState extends ConsumerState<_RiderCustomerRatingDialog> {
  int _rating = 5;
  bool _submitting = false;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = ref.read(appLanguageProvider);
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await ApiService.submitOrderFeedback(
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      try {
        await ApiService.trackAnalyticsEvent(
          'rider_customer_rating',
          properties: {
            'order_id': widget.orderId,
            'rating': _rating,
          },
        );
      } catch (_) {}
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          ApiService.extractError(e).isNotEmpty
              ? ApiService.extractError(e)
              : AppLocalization.translate('could_not_save_rating', lang),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        AppLocalization.translate('rate_customer', lang).replaceAll('{{name}}', widget.customerName ?? 'customer'),
        style: const TextStyle(
          fontFamily: 'TT Fors',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed:
                      _submitting ? null : () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB300),
                    size: 32,
                  ),
                );
              }),
            ),
            TextField(
              controller: _commentController,
              enabled: !_submitting,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalization.translate('optional_note', lang),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(AppLocalization.translate('skip', lang)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(AppLocalization.translate('submit', lang)),
        ),
      ],
    );
  }
}
