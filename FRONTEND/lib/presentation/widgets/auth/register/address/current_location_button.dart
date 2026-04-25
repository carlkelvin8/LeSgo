import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const CurrentLocationButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.spacing(context, 12),
            vertical: ResponsiveUtils.spacing(context, 8),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.my_location,
                size: ResponsiveUtils.fontSize(context, 16),
                color: const Color(0xFF5F2D82),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 4)),
              Text(
                'Use my current location',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
