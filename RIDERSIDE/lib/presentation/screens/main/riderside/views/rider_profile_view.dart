import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/widgets.dart';
import '../../../../../../core/utils/helpers/fakedata.dart';

class RiderProfileView extends StatelessWidget {
  const RiderProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RiderProfileHeader(),
        const RiderProfileInfoSection(),
        SizedBox(height: ResponsiveUtils.spacing(context, 32)),
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFEFEFEF), // Light gray background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: ResponsiveUtils.spacing(context, 20),
                  ),
                  child: Text(
                    'Personal Tasks',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...riderPersonalTasks.map(
                          (task) => Padding(
                            padding: EdgeInsets.only(
                              bottom: ResponsiveUtils.spacing(context, 16),
                            ),
                            child: RiderProfileTaskCard(
                              title: task['title']!,
                              timeText: task['timeText']!,
                            ),
                          ),
                        ),
                        // Extra padding at the bottom for scroll area (40 - 16 = 24 remainder since padding wraps each item)
                        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
