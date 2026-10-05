import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'offline_form_file_storage.dart';

/// Encodes [FormData] into JSON-safe maps with on-disk file storage.
class OfflineFormDataCodec {
  OfflineFormDataCodec._();

  static const String markerKey = '_offlineFormData';

  static bool isEncoded(dynamic data) {
    return data is Map && data[markerKey] == true;
  }

  static Future<Map<String, dynamic>> encode(FormData formData) async {
    final fields = formData.fields
        .map((entry) => {'key': entry.key, 'value': entry.value})
        .toList();

    final files = <Map<String, dynamic>>[];
    for (final entry in formData.files) {
      final bytes = await _readMultipartBytes(entry.value);
      final storageKey = await OfflineFormFileStorage.saveBytes(bytes);
      files.add({
        'field': entry.key,
        'filename': entry.value.filename ?? 'upload.bin',
        'contentType': entry.value.contentType ?? 'application/octet-stream',
        'storageKey': storageKey,
      });
    }

    return {
      markerKey: true,
      'fields': fields,
      'files': files,
    };
  }

  static Future<FormData> decode(Map<String, dynamic> encoded) async {
    final formData = FormData();
    final fields = encoded['fields'];
    if (fields is List) {
      for (final item in fields) {
        if (item is Map) {
          formData.fields.add(
            MapEntry(item['key'].toString(), item['value'].toString()),
          );
        }
      }
    }

    final files = encoded['files'];
    if (files is List) {
      for (final item in files) {
        if (item is! Map) continue;
        final storageKey = item['storageKey']?.toString();
        if (storageKey == null) continue;

        final bytes = await OfflineFormFileStorage.readBytes(storageKey);
        if (bytes == null) {
          throw StateError('Missing offline file for key $storageKey');
        }

        final contentTypeRaw = item['contentType']?.toString();
        formData.files.add(
          MapEntry(
            item['field'].toString(),
            MultipartFile.fromBytes(
              bytes,
              filename: item['filename']?.toString() ?? 'upload.bin',
              contentType: contentTypeRaw == null
                  ? null
                  : MediaType.parse(contentTypeRaw),
            ),
          ),
        );
      }
    }

    return formData;
  }

  static List<String> storageKeysFromEncoded(dynamic data) {
    if (!isEncoded(data)) return [];
    final files = (data as Map)['files'];
    if (files is! List) return [];

    return files
        .whereType<Map>()
        .map((file) => file['storageKey']?.toString())
        .whereType<String>()
        .toList();
  }

  static Future<Uint8List> _readMultipartBytes(MultipartFile file) async {
    final stream = file.finalize();
    final chunks = await stream.toList();
    return Uint8List.fromList(chunks.expand((chunk) => chunk).toList());
  }
}
