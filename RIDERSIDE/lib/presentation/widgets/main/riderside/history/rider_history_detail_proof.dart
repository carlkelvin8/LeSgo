import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderHistoryDetailProof extends StatelessWidget {
  final String timestamp;
  final List<String>? proofUrls;

  const RiderHistoryDetailProof({
    super.key,
    required this.timestamp,
    this.proofUrls,
  });

  @override
  Widget build(BuildContext context) {
    final urls = proofUrls?.where((url) => url.isNotEmpty).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (urls.isEmpty)
          Container(
            width: double.infinity,
            height: ResponsiveUtils.spacing(context, 120),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.spacing(context, 8),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                'No proof of delivery uploaded',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )
        else
          ...urls.map(
            (url) => Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveUtils.spacing(context, 8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.spacing(context, 8),
                ),
                child: Image.network(
                  url,
                  height: ResponsiveUtils.spacing(context, 180),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: ResponsiveUtils.spacing(context, 120),
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
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
