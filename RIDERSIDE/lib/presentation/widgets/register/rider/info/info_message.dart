import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

class InfoMessage extends StatelessWidget {
  const InfoMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtils.spacing(context, 12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: const Color(0xFF5F2D82),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Expanded(
            child: Text(
              'Make sure you use the place where there\'s enough light to take a clear photo.',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
