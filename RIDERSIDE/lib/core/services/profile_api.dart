import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_constants.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

/// Profile, documents, and media upload HTTP endpoints.
class ProfileApi {
  ProfileApi._();

  static Dio get _dio => getIt<DioClient>().dio;

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/v1/auth/me');
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.put('/v1/auth/me', data: data);
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadProfilePictureFromXFile(
    XFile imageFile,
  ) async {
    try {
      return await _uploadProfilePictureViaMedia(imageFile);
    } catch (mediaError) {
      AppLogger.debug(
        'Profile upload via media failed, trying direct endpoint: $mediaError',
      );
      return _uploadProfilePictureDirect(imageFile);
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    try {
      return await _uploadProfilePictureViaMedia(XFile(imagePath));
    } catch (mediaError) {
      AppLogger.debug(
        'Profile upload via media failed, trying direct endpoint: $mediaError',
      );
    }

    final formData = FormData();
    final file = MultipartFile.fromBytes(
      await XFile(imagePath).readAsBytes(),
      filename: 'profile_picture.jpg',
    );
    formData.files.add(MapEntry('profile_picture', file));

    final res = await _dio.post(
      '/v1/auth/me/profile-picture',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _uploadProfilePictureViaMedia(
    XFile imageFile,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final filename = imageFile.name.isNotEmpty ? imageFile.name : 'profile.jpg';
    final formData = FormData.fromMap({'context': 'profile'});
    formData.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));

    final uploadRes = await _dio.post(
      ApiConstants.mediaUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final uploadData = uploadRes.data['data'] ?? uploadRes.data;
    if (uploadData is! Map) {
      throw Exception('Media upload returned unexpected response');
    }
    final publicUrl = uploadData['url']?.toString();
    final storedPath = uploadData['path']?.toString();
    if (publicUrl == null || publicUrl.isEmpty) {
      throw Exception('Media upload did not return a URL');
    }

    final payload = <String, dynamic>{'profile_photo_url': publicUrl};
    if (storedPath != null && storedPath.isNotEmpty) {
      payload['profile_picture'] = storedPath;
    }

    return updateProfile(payload);
  }

  static Future<Map<String, dynamic>> _uploadProfilePictureDirect(
    XFile imageFile,
  ) async {
    final formData = FormData();
    final file = MultipartFile.fromBytes(
      await imageFile.readAsBytes(),
      filename: imageFile.name.isNotEmpty ? imageFile.name : 'profile.jpg',
    );
    formData.files.add(MapEntry('profile_picture', file));

    final res = await _dio.post(
      '/v1/auth/me/profile-picture',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyDocuments({int perPage = 30}) async {
    final res = await _dio.get(
      ApiConstants.documentsMy,
      queryParameters: {'per_page': perPage},
    );
    return _parseListData(res.data['data']);
  }

  static Future<List<dynamic>> getDocumentTypes() async {
    final res = await _dio.get(ApiConstants.documentsTypes);
    final data = res.data['data'];
    if (data is List) return data;
    return [];
  }

  static Future<Map<String, dynamic>> getDocumentVerificationStatus() async {
    final res = await _dio.get(ApiConstants.documentsVerificationStatus);
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<Map<String, dynamic>> submitDocument({
    required String documentType,
    required String documentNumber,
    required List<String> documentUrls,
    String? description,
  }) async {
    final res = await _dio.post(
      ApiConstants.documentsSubmit,
      data: {
        'document_type': documentType,
        'document_number': documentNumber,
        'document_urls': documentUrls,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return Map<String, dynamic>.from(res.data['data'] as Map? ?? {});
  }

  static Future<String> uploadDocumentFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'context': 'document',
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'document.jpg',
      ),
    });
    final res = await _dio.post(ApiConstants.documentsUpload, data: formData);
    final data = res.data['data'] as Map<String, dynamic>;
    return data['url']?.toString() ?? '';
  }

  static Future<List<String>> uploadDocumentFiles(List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadDocumentFile(file);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  static List<dynamic> _parseListData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }
}
