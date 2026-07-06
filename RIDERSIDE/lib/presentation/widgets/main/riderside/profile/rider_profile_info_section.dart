import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';
import '../../../../screens/main/riderside/rider_edit_profile_screen.dart';

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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profileState.error != null) ...[
            Text(
              profileState.error!,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: Colors.orange.shade800,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            TextButton.icon(
              onPressed: () =>
                  ref.read(riderProfileProvider.notifier).loadProfile(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          ],
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
            valueColor: const Color(0xFFC320D6),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RiderEditProfileScreen(),
                  ),
                );
              },
              icon: Icon(Icons.edit_outlined, size: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF5F2D82)),
              label: Text(
                'Edit Profile',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF5F2D82),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF5F2D82),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 12),
                ),
              ),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: RichText(
        softWrap: true,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
          children: [
            TextSpan(
              text: ' $label ',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
