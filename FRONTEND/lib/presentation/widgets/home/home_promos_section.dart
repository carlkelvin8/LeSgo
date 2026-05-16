import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../provider/main/offers/offers_provider.dart';
import '../../screens/main/offers_screen.dart';

class HomePromosSection extends ConsumerWidget {
  const HomePromosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider).featuredOffers;

    return Column(
      children: [
        SectionHeader(
          title: 'Offers for You',
          onSeeAllPressed: () => _openOffersScreen(context),
        ),
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
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                return PromoCard(
                  title: offer.title,
                  subtitle: offer.service,
                  badge: offer.discountLabel,
                  accentColor: Color(offer.accentColor),
                  onTap: () => _openOffersScreen(context),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openOffersScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OffersScreen()),
    );
  }
}
