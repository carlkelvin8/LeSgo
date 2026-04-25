import 'package:flutter/material.dart';
import '../../../../../../core/utils/helpers/fakedata.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantProfileHeader extends StatelessWidget {
  const MerchantProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            merchantProfileInfoData['greeting']!,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 40),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5F2D82),
              height: 0.95,
            ),
          ),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 12)),
        Container(
          width: ResponsiveUtils.spacing(context, 126),
          height: ResponsiveUtils.spacing(context, 126),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.spacing(context, 16),
            ),
            border: Border.all(color: Colors.black12),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  'Sun\nsets',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 20),
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 0.9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
