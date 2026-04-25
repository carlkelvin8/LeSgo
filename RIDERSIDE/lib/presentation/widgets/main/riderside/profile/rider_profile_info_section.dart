import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';

class RiderProfileInfoSection extends ConsumerWidget {
  const RiderProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final profileState = ref.watch(riderProfileProvider);

    if (profileState.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ResponsiveUtils.spacing(context, 40),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
          ),
        ),
      );
    }

    if (profileState.error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ResponsiveUtils.spacing(context, 20),
        ),
        child: Text(
          'Error loading profile: ${profileState.error}',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: Colors.red,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            'Name:',
            profileState.name.isNotEmpty ? profileState.name : 'Not set',
          ),
          _buildInfoRow(
            context,
            'Contact:',
            profileState.contact.isNotEmpty ? profileState.contact : 'Not set',
          ),
          _buildInfoRow(
            context,
            'Address:',
            profileState.address.isNotEmpty ? profileState.address : 'Not set',
          ),
          _buildInfoRow(
            context,
            'Vehicle:',
            profileState.vehicle.isNotEmpty ? profileState.vehicle : 'Not set',
          ),
          _buildInfoRow(
            context,
            'Plate number:',
            profileState.plateNumber.isNotEmpty ? profileState.plateNumber : 'Not set',
          ),
          _buildInfoRow(
            context,
            'Referral Code:',
            profileState.referralCode.isNotEmpty ? profileState.referralCode : 'Not set',
            valueColor: const Color(0xFFC320D6), // Custom vibrant purple from design
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
          children: [
            TextSpan(
              text: ' $label ',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
