import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantOrderStatusPanel extends StatelessWidget {
  final String statusType;
  final String statusLabel;

  const MerchantOrderStatusPanel({
    super.key,
    required this.statusType,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (statusType == 'accept') {
      return _tag(
        context,
        statusLabel,
        const LinearGradient(
          colors: [Color(0xFFFFF1F2), Color(0xFFFFD4D8), Color(0xFFF7A7AE)],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      );
    }
    if (statusType == 'waiting') {
      return _tag(
        context,
        statusLabel,
        const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        fontSize: 9.5,
        minWidth: 84,
      );
    }
    if (statusType == 'pickup') {
      return _tag(
        context,
        statusLabel,
        const LinearGradient(
          colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        fontSize: 9.5,
        minWidth: 84,
      );
    }
    if (statusType == 'delivery') {
      return _tag(
        context,
        statusLabel,
        const LinearGradient(
          colors: [Color(0xFFFFFBE8), Color(0xFFFFEDAE), Color(0xFFF2DA62)],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        fontSize: 9.5,
        minWidth: 84,
      );
    }
    if (statusType == 'delivered') {
      return _tag(
        context,
        statusLabel,
        const LinearGradient(
          colors: [Color(0xFFEFFFF0), Color(0xFFC3F4BC), Color(0xFF82E975)],
          stops: [0.0, 0.52, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      );
    }

    return _tag(
      context,
      statusLabel,
      const LinearGradient(
        colors: [Color(0xFFF8F1FF), Color(0xFFE6D6FB), Color(0xFFD9C0F7)],
        stops: [0.0, 0.52, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      textColor: Colors.black,
    );
  }

  Widget _tag(
    BuildContext context,
    String text,
    Gradient gradient, {
    Color textColor = Colors.black,
    double horizontalPadding = 12,
    double fontSize = 11,
    double minWidth = 72,
  }) {
    return Container(
      constraints: BoxConstraints(
        minWidth: ResponsiveUtils.spacing(context, minWidth),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, horizontalPadding),
        vertical: ResponsiveUtils.spacing(context, 5),
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, fontSize),
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
