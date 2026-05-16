import 'package:flutter_riverpod/flutter_riverpod.dart';

class Offer {
  final String id;
  final String title;
  final String description;
  final String code;
  final String category;
  final String service;
  final String expiresAt;
  final String discountLabel;
  final int accentColor;
  final bool isFeatured;
  final bool isSaved;
  final bool isClaimed;

  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.category,
    required this.service,
    required this.expiresAt,
    required this.discountLabel,
    required this.accentColor,
    this.isFeatured = false,
    this.isSaved = false,
    this.isClaimed = false,
  });

  Offer copyWith({bool? isSaved, bool? isClaimed}) {
    return Offer(
      id: id,
      title: title,
      description: description,
      code: code,
      category: category,
      service: service,
      expiresAt: expiresAt,
      discountLabel: discountLabel,
      accentColor: accentColor,
      isFeatured: isFeatured,
      isSaved: isSaved ?? this.isSaved,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}

class OffersState {
  final List<Offer> offers;
  final String selectedCategory;
  final bool isLoading;
  final String? error;

  const OffersState({
    this.offers = const [],
    this.selectedCategory = 'All',
    this.isLoading = false,
    this.error,
  });

  List<String> get categories {
    final values = offers.map((offer) => offer.category).toSet().toList()
      ..sort();
    return ['All', ...values];
  }

  List<Offer> get filteredOffers {
    if (selectedCategory == 'All') return offers;
    return offers
        .where((offer) => offer.category == selectedCategory)
        .toList(growable: false);
  }

  List<Offer> get featuredOffers {
    return offers.where((offer) => offer.isFeatured).take(3).toList();
  }

  OffersState copyWith({
    List<Offer>? offers,
    String? selectedCategory,
    bool? isLoading,
    String? error,
  }) {
    return OffersState(
      offers: offers ?? this.offers,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OffersNotifier extends StateNotifier<OffersState> {
  OffersNotifier() : super(const OffersState(isLoading: true)) {
    loadOffers();
  }

  Future<void> loadOffers() async {
    state = state.copyWith(isLoading: true, error: null);
    state = state.copyWith(offers: _seedOffers, isLoading: false);
  }

  void selectCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void toggleSaved(String offerId) {
    state = state.copyWith(
      offers: state.offers
          .map((offer) {
            if (offer.id != offerId) return offer;
            return offer.copyWith(isSaved: !offer.isSaved);
          })
          .toList(growable: false),
    );
  }

  void claimOffer(String offerId) {
    state = state.copyWith(
      offers: state.offers
          .map((offer) {
            if (offer.id != offerId) return offer;
            return offer.copyWith(isClaimed: true);
          })
          .toList(growable: false),
    );
  }

  Offer? findById(String offerId) {
    for (final offer in state.offers) {
      if (offer.id == offerId) return offer;
    }
    return null;
  }
}

const _seedOffers = [
  Offer(
    id: 'ride-20',
    title: 'Save on your next ride',
    description: 'Get a discount on LesRide bookings around Cagayan de Oro.',
    code: 'RIDE20',
    category: 'Rides',
    service: 'LesRide',
    expiresAt: 'May 31, 2026',
    discountLabel: '20% OFF',
    accentColor: 0xFF5F2D82,
    isFeatured: true,
  ),
  Offer(
    id: 'food-free-delivery',
    title: 'Free delivery for lunch',
    description: 'Order from partner restaurants and skip the delivery fee.',
    code: 'LUNCHFREE',
    category: 'Food',
    service: 'LesEat',
    expiresAt: 'June 15, 2026',
    discountLabel: 'FREE DELIVERY',
    accentColor: 0xFFB72AC8,
    isFeatured: true,
  ),
  Offer(
    id: 'wallet-cashback',
    title: 'LesPay cashback',
    description: 'Pay with your LesPay wallet and receive wallet cashback.',
    code: 'PAYBACK',
    category: 'Wallet',
    service: 'LesPay',
    expiresAt: 'June 30, 2026',
    discountLabel: 'P50 BACK',
    accentColor: 0xFF2364AA,
    isFeatured: true,
  ),
  Offer(
    id: 'parcel-discount',
    title: 'Send parcels for less',
    description: 'Use LesGo for errands, parcels, and local item delivery.',
    code: 'SEND15',
    category: 'Delivery',
    service: 'LesGo',
    expiresAt: 'May 28, 2026',
    discountLabel: '15% OFF',
    accentColor: 0xFF16846B,
  ),
  Offer(
    id: 'market-run',
    title: 'Market run saver',
    description: 'Get help buying daily essentials from nearby stores.',
    code: 'BUYMORE',
    category: 'Shopping',
    service: 'LesBuy',
    expiresAt: 'July 5, 2026',
    discountLabel: 'P75 OFF',
    accentColor: 0xFFC46A20,
  ),
];

final offersProvider = StateNotifierProvider<OffersNotifier, OffersState>(
  (ref) => OffersNotifier(),
);
