import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../domain/entities/booking/lesbuy/store.dart';
import '../../../../../data/data_source/partner_remote_datasource.dart';
import '../../../../../core/di/injection.dart';

class LesbuyState {
  final List<Store> stores;
  final List<Store> filteredStores;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  LesbuyState({
    List<Store>? stores,
    List<Store>? filteredStores,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  }) : stores = stores ?? [],
       filteredStores = filteredStores ?? [];

  LesbuyState copyWith({
    List<Store>? stores,
    List<Store>? filteredStores,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return LesbuyState(
      stores: stores ?? this.stores,
      filteredStores: filteredStores ?? this.filteredStores,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LesbuyNotifier extends StateNotifier<LesbuyState> {
  final PartnerRemoteDataSource _partnerDataSource = getIt<PartnerRemoteDataSource>();

  LesbuyNotifier() : super(LesbuyState()) {
    loadStores();
  }

  Future<void> loadStores() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔵 LesbuyProvider: Loading stores from API');
      
      final response = await _partnerDataSource.getPartners(
        category: 'grocery',  // or 'store', 'pharmacy', etc.
        perPage: 50,
      );
      
      final stores = response.data.map((partnerDto) {
        return Store(
          id: partnerDto.id.toString(),
          name: partnerDto.name,
          address: partnerDto.description ?? 'No address available',
          imagePath: partnerDto.logoUrl ?? 'assets/images/book/lesbuy/Store.svg',
          rating: partnerDto.rating ?? 4.0,
          reviewCount: partnerDto.totalReviews ?? 0,
          categories: partnerDto.tags ?? [],
          storeType: partnerDto.category ?? 'Store',
        );
      }).toList();
      
      print('🟢 LesbuyProvider: Loaded ${stores.length} stores');
      
      state = state.copyWith(
        stores: stores,
        filteredStores: stores,
        isLoading: false,
      );
    } catch (e) {
      print('🔴 LesbuyProvider: Error loading stores - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load stores. Please try again.',
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _filterStores();
  }

  void _filterStores() {
    var filtered = state.stores;

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((store) {
        return store.name.toLowerCase().contains(query) ||
            store.address.toLowerCase().contains(query) ||
            (store.storeType?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    state = state.copyWith(filteredStores: filtered);
  }

  void reset() {
    state = LesbuyState();
    loadStores();
  }

  Future<void> refresh() async {
    await loadStores();
  }
}

final lesbuyProvider = StateNotifierProvider<LesbuyNotifier, LesbuyState>((ref) {
  return LesbuyNotifier();
});
