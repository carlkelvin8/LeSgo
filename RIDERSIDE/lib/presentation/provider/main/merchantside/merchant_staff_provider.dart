import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
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
  MerchantStaffNotifier() : super(const MerchantStaffState());

  int? _partnerId;

  Future<void> loadStaff() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final partnerId = await _resolvePartnerId();
      if (partnerId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not determine partner ID.',
        );
        return;
      }

      final response = await ApiService.dio.get('/v1/partners/$partnerId/staff');
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

      state = state.copyWith(isLoading: false, staff: staff);
    } catch (e) {
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
      if (partnerId == null) {
        state = state.copyWith(isLoading: false, error: 'Could not determine partner ID.');
        return false;
      }

      await ApiService.dio.post(
        '/v1/partners/$partnerId/staff',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      await loadStaff();
      return true;
    } catch (e) {
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
      if (partnerId == null) return false;

      final body = <String, dynamic>{};
      if (role != null) body['role'] = role;
      if (isActive != null) body['is_active'] = isActive;

      await ApiService.dio.patch(
        '/v1/partners/$partnerId/staff/$staffId',
        data: body,
      );

      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> removeStaff(int staffId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final partnerId = await _resolvePartnerId();
      if (partnerId == null) return false;

      await ApiService.dio.delete(
        '/v1/partners/$partnerId/staff/$staffId',
      );

      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  Future<int?> _resolvePartnerId() async {
    if (_partnerId != null) return _partnerId;

    try {
      final me = await ApiService.getMe();
      final data = me['data'] ?? me['user'] ?? me;
      if (data is Map) {
        final pid = data['partner_id'];
        if (pid is num) {
          _partnerId = pid.toInt();
          return _partnerId;
        }
      }
    } catch (_) {}

    return null;
  }
}

final merchantStaffProvider =
    StateNotifierProvider<MerchantStaffNotifier, MerchantStaffState>(
  (ref) => MerchantStaffNotifier(),
);
