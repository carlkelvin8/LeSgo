import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../domain/entities/booking/booking_service.dart';
import '../../../core/utils/responsive_utils.dart';

class ServiceCard extends StatelessWidget {
  final BookingService service;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isComingSoon = service.type.isComingSoon;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isComingSoon ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Opacity(
                opacity: isComingSoon ? 0.45 : 1,
                child: Container(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                  child: Row(
                    children: [
                      Container(
                        width: ResponsiveUtils.spacing(context, 110),
                        height: ResponsiveUtils.spacing(context, 110),
                        padding: EdgeInsets.all(
                          ResponsiveUtils.spacing(context, 12),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SvgPicture.asset(
                          service.iconPath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 18),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(
                              height: ResponsiveUtils.spacing(context, 4),
                            ),
                            Text(
                              service.description,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 13),
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isComingSoon)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveUtils.spacing(context, 20),
                        vertical: ResponsiveUtils.spacing(context, 10),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F2D82),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: ResponsiveUtils.fontSize(context, 16),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
