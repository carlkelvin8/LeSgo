import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({super.key});

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  String? _selectedReason;
  // Shown inside the dialog: a SnackBar would render behind the modal barrier.
  String? _errorText;
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
      setState(() => _errorText = 'Please select a reason for cancellation');
      return;
    }

    String reason = _selectedReason!;
    if (_selectedReason == 'Other') {
      if (_otherReasonController.text.trim().isEmpty) {
        setState(() => _errorText = 'Please specify your reason');
        return;
      }
      reason = _otherReasonController.text.trim();
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    const red = Color(0xFFD63B45);
    final text = AppColors.foreground(context, const Color(0xFF1F1530));
    final muted = AppColors.foreground(context, Colors.grey[600]!);

    return Dialog(
      backgroundColor: AppColors.surface(context, Colors.white),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: red.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: red,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel this order?',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 20),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tell us why so we can do better.',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final reason in _cancellationReasons)
                      _reasonTile(context, reason, accent, text),
                    if (_selectedReason == 'Other') ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: _otherReasonController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) {
                          if (_errorText != null) {
                            setState(() => _errorText = null);
                          }
                        },
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14),
                          color: text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Please specify your reason...',
                          hintStyle: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13.5),
                            color: AppColors.foreground(
                              context,
                              Colors.grey[500]!,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.surface(
                            context,
                            const Color(0xFFF7F4FA),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                    if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _errorText!,
                                key: const ValueKey('cancel-reason-error'),
                                style: const TextStyle(
                                  fontFamily: 'TT Fors',
                                  color: red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: muted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cancellation may take a few minutes to process. Refunds will be credited to your wallet.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              height: 1.35,
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: text,
                        side: BorderSide(
                          color: AppColors.border(
                            context,
                            const Color(0xFFE3DAEC),
                          ),
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Keep order',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 14.5),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cancel Order',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14.5),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reasonTile(
    BuildContext context,
    String reason,
    Color accent,
    Color text,
  ) {
    final selected = _selectedReason == reason;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: reason,
        child: Material(
          color: selected
              ? accent.withValues(alpha: 0.07)
              : AppColors.surface(context, Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: selected
                  ? accent
                  : AppColors.border(context, const Color(0xFFE9E2F0)),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onTap: () => setState(() {
              _selectedReason = reason;
              _errorText = null;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14.5),
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: -0.1,
                        color: text,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accent : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? accent
                            : AppColors.border(
                                context,
                                const Color(0xFFCFC4DB),
                              ),
                        width: 1.6,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
