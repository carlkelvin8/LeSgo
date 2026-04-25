import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class RiderHistoryBookingCard extends StatelessWidget {
  final String bookingId;
  final String restaurantName;
  final String address;
  final String price;
  final String status;
  final Color statusColor;
  final Color statusBackgroundColor;
  final int? proofImageCount;

  const RiderHistoryBookingCard({
    super.key,
    required this.bookingId,
    required this.restaurantName,
    required this.address,
    required this.price,
    required this.status,
    required this.statusColor,
    required this.statusBackgroundColor,
    this.proofImageCount,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.spacing(context, 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
            children: [
              // Restaurant image placeholder
              Container(
                width: ResponsiveUtils.spacing(context, 60),
                height: ResponsiveUtils.spacing(context, 60),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  size: ResponsiveUtils.imageHeight(context, 28),
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              // Booking details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID + Status badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bookingId,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.spacing(context, 10),
                            vertical: ResponsiveUtils.spacing(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: statusBackgroundColor,
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.spacing(context, 12),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 10),
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    // Price
                    Text(
                      price,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 15),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    // Restaurant name
                    Text(
                      restaurantName,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                    // Address
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 11),
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    // Proof images indicator
                    if (proofImageCount != null && proofImageCount! > 0) ...[
                      SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                      Row(
                        children: [
                          Icon(
                            Icons.image,
                            size: ResponsiveUtils.fontSize(context, 12),
                            color: const Color(0xFF5F2D82),
                          ),
                          SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                          Text(
                            '$proofImageCount proof image${proofImageCount! > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 10),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5F2D82),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      ),
    );
  }
}
