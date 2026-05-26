import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/customer_satisfaction_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class CustomerSatisfactionDialog extends StatefulWidget {
  const CustomerSatisfactionDialog({super.key});

  static Future<void> show(
    BuildContext context,
    CustomerSatisfactionService service,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomerSatisfactionDialog(),
    );
  }

  @override
  State<CustomerSatisfactionDialog> createState() =>
      _CustomerSatisfactionDialogState();
}

class _CustomerSatisfactionDialogState extends State<CustomerSatisfactionDialog> {
  int _rating = 4;
  final _feedbackController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await getIt<CustomerSatisfactionService>().markSurveyCompleted(
        rating: _rating,
        feedback: _feedbackController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        SnackBarUtils.showSuccess(
          context,
          'Salamat sa feedback! / Thank you for your feedback!',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'How are we doing?',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 18),
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You\'ve completed ${CustomerSatisfactionService.surveyThreshold} orders with LEZGO. '
              'Help us improve your experience.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    Icons.star,
                    color: star <= _rating ? Colors.amber[700] : Colors.grey[300],
                    size: 32,
                  ),
                );
              }),
            ),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Comments (optional)',
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
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5F2D82),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}
