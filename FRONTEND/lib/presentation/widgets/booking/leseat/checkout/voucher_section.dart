import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class VoucherSection extends StatelessWidget {
  final VoidCallback? onApplyTap;
  final VoidCallback? onRemoveTap;
  final bool enabled;
  final String? appliedVoucher;

  const VoucherSection({
    super.key, 
    this.onApplyTap, 
    this.onRemoveTap,
    this.enabled = true,
    this.appliedVoucher,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onApplyTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          margin: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 16),
            vertical: ResponsiveUtils.spacing(context, 8),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer,
                color: const Color(0xFF5F2D82),
                size: ResponsiveUtils.fontSize(context, 20),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
                child: Text(
                  appliedVoucher ?? 'Apply Voucher',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
              if (appliedVoucher != null && onRemoveTap != null)
                GestureDetector(
                  onTap: onRemoveTap,
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: ResponsiveUtils.fontSize(context, 20),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: ResponsiveUtils.fontSize(context, 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
