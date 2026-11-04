import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../data/data_source/dto/merchant/partner_branch.dart';
import '../../auth/rider_auth_provider.dart';

class MerchantBranchesState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<PartnerBranch> branches;

  const MerchantBranchesState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.branches = const [],
  });

  MerchantBranchesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    List<PartnerBranch>? branches,
  }) {
    return MerchantBranchesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      branches: branches ?? this.branches,
    );
  }
}

class MerchantBranchesNotifier extends StateNotifier<MerchantBranchesState> {
  MerchantBranchesNotifier({
    Dio? dio,
    Future<Map<String, dynamic>> Function()? loadUser,
  })  : _client = dio,
        _loadUser = loadUser ?? ApiService.getMe,
        super(const MerchantBranchesState());

  final Dio? _client;
  final Future<Map<String, dynamic>> Function() _loadUser;
  int? _partnerId;
  Dio get _dio => _client ?? ApiService.dio;

  Future<void> loadBranches() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final partnerId = await _resolvePartnerId();
      if (!mounted) return;
      if (partnerId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not determine your store.',
        );
        return;
      }

      final response = await _dio.get('/v1/partners/$partnerId/branches');
      final data = response.data;
      final raw = data is Map ? data['data'] : data;
      final branches = (raw is List ? raw : const [])
          .whereType<Map>()
          .map((e) => PartnerBranch.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      state = state.copyWith(isLoading: false, branches: branches);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: ApiService.extractError(e));
    }
  }

  /// Creates a branch (when [branchId] is null) or updates one.
  /// Returns null on success, or an error message.
  Future<String?> saveBranch({
    int? branchId,
    required Map<String, dynamic> body,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      if (branchId == null) {
        final partnerId = await _resolvePartnerId();
        if (partnerId == null) {
          state = state.copyWith(isSaving: false);
          return 'Could not determine your store.';
        }
        await _dio.post('/v1/partners/$partnerId/branches', data: body);
      } else {
        await _dio.patch('/v1/branches/$branchId', data: body);
      }
      if (!mounted) return null;
      state = state.copyWith(isSaving: false);
      await loadBranches();
      return null;
    } catch (e) {
      if (mounted) state = state.copyWith(isSaving: false);
      return ApiService.extractError(e);
    }
  }

  Future<String?> setOpen(PartnerBranch branch, bool isOpen) =>
      saveBranch(branchId: branch.id, body: {'is_open': isOpen});

  Future<String?> makePrimary(PartnerBranch branch) =>
      saveBranch(branchId: branch.id, body: {'is_primary': true});

  Future<String?> deleteBranch(PartnerBranch branch) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _dio.delete('/v1/branches/${branch.id}');
      if (!mounted) return null;
      state = state.copyWith(isSaving: false);
      await loadBranches();
      return null;
    } catch (e) {
      if (mounted) state = state.copyWith(isSaving: false);
      return ApiService.extractError(e);
    }
  }

  Future<int?> _resolvePartnerId() async {
    if (_partnerId != null) return _partnerId;
    try {
      final me = await _loadUser();
      final data = me['data'] ?? me['user'] ?? me;
      if (data is Map) {
        _partnerId = RiderUser.parsePartnerId(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return _partnerId;
  }
}

final merchantBranchesProvider =
    StateNotifierProvider<MerchantBranchesNotifier, MerchantBranchesState>(
  (ref) {
    ref.watch(riderAuthProvider.select((auth) => auth.user?.id));
    return MerchantBranchesNotifier();
  },
);
