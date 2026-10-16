import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../di/local_storage_service.dart';

/// Exchanges a refresh token for a new access token.
@lazySingleton
class TokenRefreshService {
  final LocalStorageService _localStorageService;
  late final Dio _refreshDio;
  Future<String?>? _ongoingRefresh;
  String? _refreshSessionToken;
  String? _refreshSessionCredential;

  TokenRefreshService(this._localStorageService) {
    _refreshDio = Dio(
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
  }

  @visibleForTesting
  TokenRefreshService.withClient(this._localStorageService, Dio client) {
    _refreshDio = client;
  }

  Future<String?> refreshAccessToken() {
    final accessToken = _localStorageService.token;
    final refresh = _localStorageService.refreshToken;
    final inFlight = _ongoingRefresh;
    if (inFlight != null &&
        accessToken == _refreshSessionToken &&
        refresh == _refreshSessionCredential) {
      return inFlight;
    }

    _refreshSessionToken = accessToken;
    _refreshSessionCredential = refresh;
    if (refresh != null && refresh.isNotEmpty) {
      final future = _performRefreshWithBody(refresh);
      _ongoingRefresh = future;
      return future.whenComplete(() {
        if (identical(_ongoingRefresh, future)) {
          _ongoingRefresh = null;
        }
      });
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      final future = _performRefreshWithBearer(accessToken);
      _ongoingRefresh = future;
      return future.whenComplete(() {
        if (identical(_ongoingRefresh, future)) {
          _ongoingRefresh = null;
        }
      });
    }

    return Future.value(null);
  }

  Future<String?> _performRefreshWithBody(String refreshToken) async {
    final sessionToken = _localStorageService.token;
    try {
      final response = await _refreshDio.post(
        ApiConstants.authRefresh,
        data: {'refresh_token': refreshToken},
      );

      if (_localStorageService.token != sessionToken ||
          _localStorageService.refreshToken != refreshToken) {
        return null;
      }
      return _persistTokens(response.data);
    } on DioException catch (error) {
      if (!_isRejectedSession(error)) rethrow;
      return null;
    }
  }

  Future<String?> _performRefreshWithBearer(String accessToken) async {
    try {
      final response = await _refreshDio.post(
        ApiConstants.authRefresh,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (_localStorageService.token != accessToken) return null;
      return _persistTokens(response.data);
    } on DioException catch (error) {
      if (!_isRejectedSession(error)) rethrow;
      return null;
    }
  }

  bool _isRejectedSession(DioException error) =>
      const {401, 403, 422}.contains(error.response?.statusCode);

  Future<String?> _persistTokens(dynamic raw) async {
    final tokens = _extractTokens(raw);
    final accessToken = tokens.$1;
    if (accessToken == null || accessToken.isEmpty) return null;

    await _localStorageService.saveToken(accessToken);
    final newRefresh = tokens.$2;
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await _localStorageService.saveRefreshToken(newRefresh);
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

    return (map['token'] as String?, map['refresh_token'] as String?);
  }

  /// Persist tokens returned by login/register/change-password responses.
  Future<void> persistAuthTokens(Map<String, dynamic> response) async {
    await _persistTokens(response);
  }
}
