import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';

class RiderProfileView extends StatelessWidget {
  const RiderProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveUtils.scrollPaddingWithBottomNav(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const RiderProfileHeader(),
          const RiderProfileInfoSection(),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          const RiderProfileSummarySection(),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          const RiderProfileSettingsSection(),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        ],
      ),
    );
  }
}
