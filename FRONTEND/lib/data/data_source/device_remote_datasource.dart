import 'dart:io';

import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

@lazySingleton
class DeviceRemoteDataSource {
  final DioClient _dioClient;

  DeviceRemoteDataSource(this._dioClient);

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _dioClient.dio.post(
      ApiConstants.deviceRegister,
      data: {
        'token': token,
        'platform': platform,
        'app': 'lesgo_customer',
      },
    );
  }

  static String currentPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
