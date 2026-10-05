import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/api_error_mapper.dart';
import '../../../../data/data_source/voucher_remote_datasource.dart';
import '../../../../data/data_source/dto/voucher/voucher_dto.dart';

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
  final bool isEligible;
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
    this.isEligible = true,
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
      isEligible: isEligible,
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
    final featured = offers.where((offer) => offer.isFeatured).toList();
    if (featured.isNotEmpty) return featured.take(3).toList();
    return offers.take(3).toList();
  }

  OffersState copyWith({
    List<Offer>? offers,
    String? selectedCategory,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OffersState(
      offers: offers ?? this.offers,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OffersNotifier extends StateNotifier<OffersState> {
  OffersNotifier() : super(const OffersState(isLoading: true)) {
    loadOffers();
  }

  final VoucherRemoteDataSource _voucherDataSource =
      getIt<VoucherRemoteDataSource>();

  Future<void> loadOffers() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _voucherDataSource.getAvailableVouchers();
      final offers = response.data.asMap().entries.map((entry) {
        final voucher = entry.value;
        return _mapVoucherToOffer(voucher, entry.key);
      }).toList();

      state = state.copyWith(offers: offers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        offers: [],
        isLoading: false,
        error: ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not load offers from server.',
          fallbackTl: 'Hindi ma-load ang mga offer mula sa server.',
        ),
      );
    }
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

  Future<String?> claimOffer(String offerId) async {
    final offer = findById(offerId);
    if (offer == null) {
      throw Exception('Offer not found');
    }
    if (!offer.isEligible) {
      throw Exception(
        offer.isClaimed
            ? 'You already claimed this voucher.'
            : 'You are not eligible for this voucher.',
      );
    }
    if (offer.isClaimed) {
      throw Exception('You already claimed this voucher.');
    }

    try {
      await _voucherDataSource.claimVoucher(offer.code);
    } catch (e) {
      throw Exception(
        ApiErrorMapper.message(
          e,
          fallbackEn: 'Unable to claim this voucher.',
          fallbackTl: 'Hindi ma-claim ang voucher na ito.',
        ),
      );
    }

    state = state.copyWith(
      offers: state.offers
          .map((item) {
            if (item.id != offerId) return item;
            return item.copyWith(isClaimed: true);
          })
          .toList(growable: false),
      clearError: true,
    );

    return offer.code;
  }

  Offer? findById(String offerId) {
    for (final offer in state.offers) {
      if (offer.id == offerId) return offer;
    }
    return null;
  }
}

Offer _mapVoucherToOffer(VoucherDto voucher, int index) {
  final code = voucher.code;
  final upper = code.toUpperCase();
  String category = 'Promo';
  String service = 'All Services';
  int accent = 0xFF5F2D82;

  if (upper.contains('RIDE')) {
    category = 'Rides';
    service = 'LesRide';
    accent = 0xFF5F2D82;
  } else if (upper.contains('LUNCH') ||
      upper.contains('EAT') ||
      upper.contains('FOOD')) {
    category = 'Food';
    service = 'LesEat';
    accent = 0xFFB72AC8;
  } else if (upper.contains('PAY') || upper.contains('WALLET')) {
    category = 'Wallet';
    service = 'LesPay';
    accent = 0xFF2364AA;
  } else if (upper.contains('SEND') || upper.contains('GO')) {
    category = 'Delivery';
    service = 'LesGo';
    accent = 0xFF16846B;
  } else if (upper.contains('BUY')) {
    category = 'Shopping';
    service = 'LesBuy';
    accent = 0xFFC46A20;
  }

  final eligible = voucher.eligible;
  final claimed = voucher.claimed;

  return Offer(
    id: code,
    title: voucher.title,
    description: voucher.description ?? '',
    code: code,
    category: category,
    service: service,
    expiresAt: voucher.expiresAt ?? 'Limited time',
    discountLabel: voucher.discountText ?? 'SPECIAL OFFER',
    accentColor: accent,
    isFeatured: index < 3,
    isEligible: eligible,
    isClaimed: claimed,
  );
}

final offersProvider = StateNotifierProvider<OffersNotifier, OffersState>(
  (ref) => OffersNotifier(),
);
