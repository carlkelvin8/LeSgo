import 'package:flutter/material.dart';
import '../../../../../../core/utils/utils.dart';

class MerchantCompleteInfoCard extends StatelessWidget {
  final String restaurantName;
  final String address;
  final String email;
  final String contactNumber;

  const MerchantCompleteInfoCard({
    super.key,
    required this.restaurantName,
    required this.address,
    required this.email,
    required this.contactNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Here\'s your information',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoText(
                      context,
                      restaurantName,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    _buildInfoText(context, address),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    _buildInfoText(context, email),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    _buildInfoText(context, contactNumber),
                  ],
                ),
              ),
              // Store icon placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D5F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store,
                  size: 40,
                  color: const Color(0xFF9B6BB8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(
    BuildContext context,
    String text, {
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, fontSize),
        fontWeight: fontWeight,
        color: Colors.black87,
      ),
    );
  }
}
