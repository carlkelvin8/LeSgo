import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';

class RiderProfileView extends StatelessWidget {
  const RiderProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RiderProfileHeader(),
        const RiderProfileInfoSection(),
        SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFEFEFEF),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                child: Text(
                  'No personal tasks assigned yet.',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
