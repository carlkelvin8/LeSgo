import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/offers/offers_provider.dart';
import '../../widgets/offers/offer_card.dart';
import '../../widgets/offers/offers_empty_state.dart';
import '../../widgets/offers/offers_filter_bar.dart';
import '../../widgets/offers/offers_header.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersState = ref.watch(offersProvider);
    final offersNotifier = ref.read(offersProvider.notifier);
    final filteredOffers = offersState.filteredOffers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            OffersHeader(offerCount: offersState.offers.length),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            OffersFilterBar(
              categories: offersState.categories,
              selectedCategory: offersState.selectedCategory,
              onCategorySelected: offersNotifier.selectCategory,
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            if (offersState.infoMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 20),
                ),
                child: Text(
                  offersState.infoMessage!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.orange[800],
                  ),
                ),
              ),
            if (offersState.error != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 20),
                  vertical: ResponsiveUtils.spacing(context, 4),
                ),
                child: Text(
                  offersState.error!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.red[700],
                  ),
                ),
              ),
            Expanded(
              child: offersState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2D82),
                      ),
                    )
                  : offersState.error != null && offersState.offers.isEmpty
                      ? Center(
                          child: TextButton(
                            onPressed: offersNotifier.loadOffers,
                            child: const Text('Retry loading offers'),
                          ),
                        )
                  : filteredOffers.isEmpty
                  ? const OffersEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF5F2D82),
                      onRefresh: offersNotifier.loadOffers,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.spacing(context, 20),
                          4,
                          ResponsiveUtils.spacing(context, 20),
                          ResponsiveUtils.spacing(context, 24),
                        ),
                        itemCount: filteredOffers.length,
                        separatorBuilder: (_, __) => SizedBox(
                          height: ResponsiveUtils.spacing(context, 14),
                        ),
                        itemBuilder: (context, index) {
                          final offer = filteredOffers[index];
                          return OfferCard(
                            offer: offer,
                            onSavePressed: () {
                              offersNotifier.toggleSaved(offer.id);
                            },
                            onClaimPressed: () async {
                              offersNotifier.claimOffer(offer.id);
                              await Clipboard.setData(
                                ClipboardData(text: offer.code),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${offer.code} copied to clipboard',
                                    ),
                                    backgroundColor: const Color(0xFF5F2D82),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
