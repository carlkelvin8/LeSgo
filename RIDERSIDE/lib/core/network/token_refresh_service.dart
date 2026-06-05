import '../constants/api_constants.dart';
import '../services/remember_me_service.dart';
import '../services/secure_storage_service.dart';
import 'package:dio/dio.dart';

/// Exchanges refresh tokens for new access tokens (Rider/Merchant app).
class TokenRefreshService {
  TokenRefreshService._();
  static final TokenRefreshService instance = TokenRefreshService._();

  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  Future<String?>? _ongoingRefresh;

  Future<String?> refreshAccessToken() {
    final inFlight = _ongoingRefresh;
    if (inFlight != null) return inFlight;

    final future = _performRefresh();
    _ongoingRefresh = future;
    return future.whenComplete(() {
      if (identical(_ongoingRefresh, future)) {
        _ongoingRefresh = null;
      }
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final response = await _refreshDio.post(
          ApiConstants.authRefresh,
          data: {'refresh_token': refreshToken},
        );
        return _persistTokens(response.data);
      } catch (_) {
        // fall through to bearer refresh
      }
    }

    final accessToken = await SecureStorageService.getToken();
    if (accessToken == null || accessToken.isEmpty) return null;

    try {
      final response = await _refreshDio.post(
        ApiConstants.authRefresh,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return _persistTokens(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _persistTokens(dynamic raw) async {
    final tokens = _extractTokens(raw);
    final accessToken = tokens.$1;
    if (accessToken == null || accessToken.isEmpty) return null;

    final refreshToken =
        tokens.$2 ?? await SecureStorageService.getRefreshToken();
    await SecureStorageService.saveToken(
      token: accessToken,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      refreshToken: refreshToken,
    );
    if (RememberMeService.isSessionValid()) {
      await RememberMeService.refreshExpiry();
    }
    return accessToken;
  }

  (String?, String?) _extractTokens(dynamic raw) {
    if (raw is! Map) return (null, null);
    final map = Map<String, dynamic>.from(raw);
    final nested = map['data'];
    if (nested is Map) {
      final data = Map<String, dynamic>.from(nested);
      return (
        data['token'] as String? ?? map['token'] as String?,
        data['refresh_token'] as String? ?? map['refresh_token'] as String?,
      );
    }
    return (
      map['token'] as String?,
      map['refresh_token'] as String?,
    );
  }

  Future<void> persistAuthTokens(Map<String, dynamic> response) async {
    await _persistTokens(response);
  }
}
