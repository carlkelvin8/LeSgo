import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../auth/rider_auth_provider.dart';
import '../../../../data/data_source/dto/merchant/partner_staff_dto.dart';

class MerchantStaffState {
  final bool isLoading;
  final String? error;
  final List<PartnerStaffDto> staff;

  const MerchantStaffState({
    this.isLoading = false,
    this.error,
    this.staff = const [],
  });

  MerchantStaffState copyWith({
    bool? isLoading,
    String? error,
    List<PartnerStaffDto>? staff,
    bool clearError = false,
  }) {
    return MerchantStaffState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      staff: staff ?? this.staff,
    );
  }
}

class MerchantStaffNotifier extends StateNotifier<MerchantStaffState> {
  MerchantStaffNotifier({Dio? dio, Future<Map<String, dynamic>> Function()? loadUser})
      : _client = dio,
        _loadUser = loadUser ?? ApiService.getMe,
        super(const MerchantStaffState());

  final Dio? _client;
  final Future<Map<String, dynamic>> Function() _loadUser;
  Dio get _dio => _client ?? ApiService.dio;

  Future<void> loadStaff() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final partnerId = await _resolvePartnerId();
      if (!mounted) return;
      if (partnerId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not determine partner ID.',
        );
        return;
      }

      final response = await _dio.get('/v1/partners/$partnerId/staff');
      final data = response.data;
      // Handle both paginated {data: [...]} and direct [...] responses
      List rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        final nested = data['data'];
        rawList = nested is List ? nested : [];
      } else {
        rawList = [];
      }
      final staff = rawList
          .map((e) => PartnerStaffDto.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      state = state.copyWith(isLoading: false, staff: staff);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
    }
  }

  Future<bool> inviteStaff({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final partnerId = await _resolvePartnerId();
      if (!mounted) return false;
      if (partnerId == null) {
        state = state.copyWith(isLoading: false, error: 'Could not determine partner ID.');
        return false;
      }

      await _dio.post(
        '/v1/partners/$partnerId/staff',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      if (!mounted) return false;
      await loadStaff();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  Future<bool> updateStaff(int staffId, {String? role, bool? isActive}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final partnerId = await _resolvePartnerId();
      if (!mounted) return false;
      if (partnerId == null) {
        state = state.copyWith(isLoading: false, error: 'Could not determine partner ID.');
        return false;
      }

      final body = <String, dynamic>{};
      if (role != null) body['role'] = role;
      if (isActive != null) body['is_active'] = isActive;

      await _dio.patch(
        '/v1/partners/$partnerId/staff/$staffId',
        data: body,
      );

      if (!mounted) return false;
      await loadStaff();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> removeStaff(int staffId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final partnerId = await _resolvePartnerId();
      if (!mounted) return false;
      if (partnerId == null) {
        state = state.copyWith(isLoading: false, error: 'Could not determine partner ID.');
        return false;
      }

      await _dio.delete(
        '/v1/partners/$partnerId/staff/$staffId',
      );

      if (!mounted) return false;
      await loadStaff();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: ApiService.extractError(e));
      return false;
    }
  }

  Future<int?> _resolvePartnerId() async {
    try {
      final me = await _loadUser();
      final data = me['data'] ?? me['user'] ?? me;
      if (data is Map) {
        return RiderUser.parsePartnerId(Map<String, dynamic>.from(data));
      }
    } catch (_) {}

    return null;
  }
}

final merchantStaffProvider =
    StateNotifierProvider<MerchantStaffNotifier, MerchantStaffState>(
  (ref) {
    ref.watch(riderAuthProvider.select((auth) => auth.user?.id));
    return MerchantStaffNotifier();
  },
);
