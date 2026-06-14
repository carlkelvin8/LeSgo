import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Stores multipart bytes on disk for offline replay.
class OfflineFormFileStorage {
  OfflineFormFileStorage._();

  static const String _folderName = 'offline_queue_files';

  static Future<Directory> _directory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> saveBytes(Uint8List bytes) async {
    final dir = await _directory();
    final storageKey = '${DateTime.now().microsecondsSinceEpoch}_${bytes.length}';
    final file = File('${dir.path}/$storageKey');
    await file.writeAsBytes(bytes, flush: true);
    return storageKey;
  }

  static Future<Uint8List?> readBytes(String storageKey) async {
    final file = File('${(await _directory()).path}/$storageKey');
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static Future<void> delete(String storageKey) async {
    final file = File('${(await _directory()).path}/$storageKey');
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> deleteMany(Iterable<String> storageKeys) async {
    for (final key in storageKeys) {
      await delete(key);
    }
  }
}
