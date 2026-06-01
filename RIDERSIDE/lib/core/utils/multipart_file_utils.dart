import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';

Future<MultipartFile> multipartFileFromPath(String path) async {
  final filename = path.split(RegExp(r'[/\\]')).last;

  try {
    return await MultipartFile.fromFile(path, filename: filename);
  } catch (_) {
    final bytes = await XFile(path).readAsBytes();
    return MultipartFile.fromBytes(bytes, filename: filename);
  }
}

Future<void> appendDocumentFile(
  FormData formData,
  String fieldName,
  String path,
) async {
  formData.files.add(
    MapEntry(fieldName, await multipartFileFromPath(path)),
  );
}
