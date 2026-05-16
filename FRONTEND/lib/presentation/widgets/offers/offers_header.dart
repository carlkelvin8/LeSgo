import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';

class OffersHeader extends StatelessWidget {
  final int offerCount;

  const OffersHeader({super.key, required this.offerCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.spacing(context, 20),
        ResponsiveUtils.spacing(context, 12),
        ResponsiveUtils.spacing(context, 20),
        ResponsiveUtils.spacing(context, 8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: const Color(0xFF5F2D82),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offers for You',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 22),
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$offerCount active offers',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEDDFD),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer, color: Color(0xFF5F2D82)),
          ),
        ],
      ),
    );
  }
}
