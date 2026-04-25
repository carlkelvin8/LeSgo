import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderHistoryDetailProof extends StatelessWidget {
  final String timestamp;

  const RiderHistoryDetailProof({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Proof Image Placeholder (grey box since we don't have networking setup yet)
        Container(
          width: double.infinity,
          height: ResponsiveUtils.spacing(context, 180),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 4),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image,
              size: ResponsiveUtils.imageHeight(context, 40),
              color: Colors.grey.shade700,
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),

        // Timestamp
        Text(
          timestamp,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 11),
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
