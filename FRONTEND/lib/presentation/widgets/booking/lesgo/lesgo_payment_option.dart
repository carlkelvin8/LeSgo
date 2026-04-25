import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/responsive_utils.dart';

/// Payment option widget specifically for LesGo service.
/// This is a separate component from LesRide to allow for
/// future customizations and additional fields.
class LesgoPaymentOption extends StatelessWidget {
  const LesgoPaymentOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -2),
      leading: SvgPicture.asset(
        value == 'cod'
            ? 'assets/images/Cash.svg'
            : 'assets/images/lespay/Gcash.svg',
        width: 28,
        height: 28,
        placeholderBuilder: (context) => const Icon(
          Icons.account_balance_wallet,
          size: 20,
          color: Color(0xFF7C3AED),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 14),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFF7C3AED),
      ),
      onTap: () => onChanged(value),
    );
  }
}
