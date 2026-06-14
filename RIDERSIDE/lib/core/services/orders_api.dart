import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../di/injection.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

/// Order-related HTTP endpoints.
class OrdersApi {
  OrdersApi._();

  static Dio get _dio => getIt<DioClient>().dio;

  static Future<List<dynamic>> getOrders({
    String? status,
    int perPage = 30,
  }) async {
    final params = <String, dynamic>{'per_page': perPage};
    if (status != null) params['status'] = status;
    final res = await _dio.get('/v1/orders', queryParameters: params);
    return (res.data['data'] as List<dynamic>?) ?? [];
  }

  static Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      final res = await _dio.get('/v1/orders/$orderId');
      final data = res.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('data')) {
          return data['data'] as Map<String, dynamic>?;
        }
        return data;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error fetching order by ID', e);
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status, {
    String? cancelReason,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (cancelReason != null && cancelReason.isNotEmpty) {
      data['cancel_reason'] = cancelReason;
    }
    final res = await _dio.patch(
      '/v1/orders/$orderId/status',
      data: data,
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadProofImages(
    int orderId,
    List<String> imagePaths, {
    double? latitude,
    double? longitude,
    bool firstItemProof = false,
  }) async {
    final formData = FormData();

    if (latitude != null) {
      formData.fields.add(MapEntry('latitude', latitude.toString()));
    }
    if (longitude != null) {
      formData.fields.add(MapEntry('longitude', longitude.toString()));
    }
    if (firstItemProof) {
      formData.fields.add(const MapEntry('first_item_proof', '1'));
    }

    for (var i = 0; i < imagePaths.length; i++) {
      final file = await MultipartFile.fromFile(
        imagePaths[i],
        filename: 'proof_$i.jpg',
      );
      formData.files.add(MapEntry('images[]', file));
    }

    final res = await _dio.post(
      '/v1/orders/$orderId/upload-proof',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadProofImagesWeb(
    int orderId,
    List<XFile> imageFiles, {
    double? latitude,
    double? longitude,
    bool firstItemProof = false,
  }) async {
    final formData = FormData();

    if (latitude != null) {
      formData.fields.add(MapEntry('latitude', latitude.toString()));
    }
    if (longitude != null) {
      formData.fields.add(MapEntry('longitude', longitude.toString()));
    }
    if (firstItemProof) {
      formData.fields.add(const MapEntry('first_item_proof', '1'));
    }

    for (var i = 0; i < imageFiles.length; i++) {
      final bytes = await imageFiles[i].readAsBytes();
      formData.files.add(MapEntry(
        'images[]',
        MultipartFile.fromBytes(bytes, filename: imageFiles[i].name),
      ));
    }

    final res = await _dio.post(
      '/v1/orders/$orderId/upload-proof',
      data: formData,
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post('/v1/orders', data: data);
    return res.data as Map<String, dynamic>;
  }
}
