import 'package:flutter/material.dart';

import '../widgets.dart';
import '../../../../core/utils/responsive_utils.dart';

class HomePromosSection extends StatelessWidget {
  const HomePromosSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'Offers for You', onSeeAllPressed: () {}),
        SizedBox(height: ResponsiveUtils.spacing(context, 12)),
        SectionContainer(
          margin: EdgeInsets.only(
            left: ResponsiveUtils.spacing(context, 16.0),
            right: ResponsiveUtils.spacing(context, 16.0),
            bottom: ResponsiveUtils.spacing(context, 16.0),
          ),
          child: SizedBox(
            height: ResponsiveUtils.imageHeight(context, 200),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return PromoCard(
                  title: 'Promo ${index + 1}',
                  onTap: () {
                    // TODO: Show promo details
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
