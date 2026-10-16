import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';

class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({super.key});

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  final List<String> _cancellationReasons = [
    'Changed my mind',
    'Found a better price',
    'Ordered by mistake',
    'Taking too long',
    'Wrong delivery address',
    'Payment issues',
    'Other',
  ];

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_selectedReason == null) {
      SnackBarUtils.showError(context, 'Please select a reason for cancellation');
      return;
    }

    String reason = _selectedReason!;
    if (_selectedReason == 'Other') {
      if (_otherReasonController.text.trim().isEmpty) {
        SnackBarUtils.showError(context, 'Please specify your reason');
        return;
      }
      reason = _otherReasonController.text.trim();
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            color: Colors.red[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Cancel Order',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please select a reason for cancellation:',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: AppColors.foreground(context, Colors.grey[700]!),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            RadioGroup<String>(
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._cancellationReasons.map((reason) {
                    return RadioListTile<String>(
                      title: Text(
                        reason,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                        ),
                      ),
                      value: reason,
                      activeColor: const Color(0xFF5F2D82),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }),
                ],
              ),
            ),
            if (_selectedReason == 'Other') ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              TextField(
                controller: _otherReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please specify your reason...',
                  hintStyle: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 13),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF5F2D82),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancellation may take a few minutes to process. Refunds will be credited to your wallet.',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Keep Order',
            style: TextStyle(
              fontFamily: 'TT Fors',
              color: AppColors.foreground(context, Colors.grey[600]!),
              fontSize: ResponsiveUtils.fontSize(context, 14),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Cancel Order',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
            ),
          ),
        ),
      ],
    );
  }
}
