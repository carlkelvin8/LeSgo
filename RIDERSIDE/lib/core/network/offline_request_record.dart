import 'package:dio/dio.dart';

import 'offline_form_data_codec.dart';

/// Serializable snapshot of a queued HTTP request.
class OfflineRequestRecord {
  OfflineRequestRecord({
    required this.method,
    required this.path,
    required this.baseUrl,
    this.queryParameters = const {},
    this.data,
    this.headers = const {},
    this.extra = const {},
  });

  final String method;
  final String path;
  final String baseUrl;
  final Map<String, dynamic> queryParameters;
  final dynamic data;
  final Map<String, String> headers;
  final Map<String, dynamic> extra;

  static const _authHeaderKeys = {'authorization', 'cookie'};

  static Future<OfflineRequestRecord> fromRequestOptions(
    RequestOptions options,
  ) async {
    final headers = <String, String>{};
    options.headers.forEach((key, value) {
      if (value == null) return;
      if (_authHeaderKeys.contains(key.toString().toLowerCase())) return;
      headers[key.toString()] = value.toString();
    });

    dynamic data = options.data;
    if (data is FormData) {
      data = await OfflineFormDataCodec.encode(data);
    }

    return OfflineRequestRecord(
      method: options.method,
      path: options.path,
      baseUrl: options.baseUrl,
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      data: data,
      headers: headers,
      extra: Map<String, dynamic>.from(options.extra),
    );
  }

  Future<RequestOptions> toRequestOptions() async {
    dynamic body = data;
    if (OfflineFormDataCodec.isEncoded(body)) {
      body = await OfflineFormDataCodec.decode(
        Map<String, dynamic>.from(body as Map),
      );
    }

    return RequestOptions(
      method: method,
      path: path,
      baseUrl: baseUrl,
      queryParameters: Map<String, dynamic>.from(queryParameters),
      data: body,
      headers: Map<String, String>.from(headers),
      extra: Map<String, dynamic>.from(extra),
    );
  }

  List<String> get attachedFileKeys =>
      OfflineFormDataCodec.storageKeysFromEncoded(data);

  String requestKey() {
    if (OfflineFormDataCodec.isEncoded(data)) {
      final keys = attachedFileKeys.join(',');
      return '$method:$baseUrl$path:form:$keys';
    }
    return '$method:$baseUrl$path:$data';
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'path': path,
        'baseUrl': baseUrl,
        'queryParameters': queryParameters,
        'data': data,
        'headers': headers,
        'extra': extra,
      };

  factory OfflineRequestRecord.fromJson(Map<String, dynamic> json) {
    return OfflineRequestRecord(
      method: json['method'] as String? ?? 'GET',
      path: json['path'] as String? ?? '/',
      baseUrl: json['baseUrl'] as String? ?? '',
      queryParameters: Map<String, dynamic>.from(
        json['queryParameters'] as Map? ?? {},
      ),
      data: json['data'],
      headers: Map<String, String>.from(
        (json['headers'] as Map? ?? {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      ),
      extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
    );
  }
}
