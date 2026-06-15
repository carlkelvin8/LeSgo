import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

class UploadedMedia {
  final String url;
  final String path;
  final String filename;
  final String mimeType;
  final int size;

  const UploadedMedia({
    required this.url,
    required this.path,
    required this.filename,
    required this.mimeType,
    required this.size,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) {
    return UploadedMedia(
      url: json['url']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

@lazySingleton
class FileUploadService {
  final DioClient _dioClient;

  FileUploadService(this._dioClient);

  Future<UploadedMedia> uploadFile(
    XFile file, {
    String context = 'general',
    String uploadPath = ApiConstants.mediaUpload,
  }) async {
    final bytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty ? file.name : 'upload.jpg';

    final formData = FormData.fromMap({
      'context': context,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final response = await _dioClient.dio.post(uploadPath, data: formData);
    final data = response.data['data'] as Map<String, dynamic>;
    return UploadedMedia.fromJson(data);
  }

  Future<List<String>> uploadFiles(
    List<XFile> files, {
    String context = 'general',
    String uploadPath = ApiConstants.mediaUpload,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final uploaded = await uploadFile(
        file,
        context: context,
        uploadPath: uploadPath,
      );
      if (uploaded.url.isNotEmpty) {
        urls.add(uploaded.url);
      }
    }
    return urls;
  }
}
