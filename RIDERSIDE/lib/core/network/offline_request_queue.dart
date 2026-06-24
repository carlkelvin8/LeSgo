import 'dart:async';

import 'package:dio/dio.dart';

import '../utils/app_logger.dart';
import 'offline_form_file_storage.dart';
import 'offline_queue_storage.dart';
import 'offline_request_record.dart';

class OfflineRequestQueue {
  OfflineRequestQueue._();

  static final OfflineRequestQueue instance = OfflineRequestQueue._();

  final List<OfflineRequestRecord> _pending = [];
  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();
  bool _flushing = false;
  bool _initialized = false;

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  int get pendingCount => _pending.length;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final restored = await OfflineQueueStorage.load();
    _pending
      ..clear()
      ..addAll(restored.where((item) => !_isNonCriticalPath(item.path)));
    _emitCount();

    final dropped = restored.length - _pending.length;
    if (dropped > 0) {
      await _persist();
      AppLogger.debug('Dropped $dropped non-critical offline request(s)');
    }

    if (_pending.isNotEmpty) {
      AppLogger.debug(
        'Restored ${_pending.length} offline request(s) from storage',
      );
    }

    await pruneNonCriticalPaths();
  }

  bool _isMutating(String method) {
    final upper = method.toUpperCase();
    return upper == 'POST' ||
        upper == 'PUT' ||
        upper == 'PATCH' ||
        upper == 'DELETE';
  }

  bool canQueue(RequestOptions options) {
    if (!_isMutating(options.method)) return false;
    if (options.extra['skipOfflineQueue'] == true) return false;
    if (_isNonCriticalPath(options.path)) return false;
    return true;
  }

  static bool _isNonCriticalPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/analytics/') ||
        normalized.contains('/auth/') ||
        normalized.contains('/config/mobile') ||
        normalized.contains('/devices/register');
  }

  Future<void> pruneNonCriticalPaths() async {
    final before = _pending.length;
    _pending.removeWhere((item) => _isNonCriticalPath(item.path));
    if (_pending.length == before) return;
    _emitCount();
    await _persist();
    AppLogger.debug(
      'Pruned ${before - _pending.length} non-critical offline request(s)',
    );
  }

  Future<void> enqueue(RequestOptions options) async {
    if (!canQueue(options)) return;

    final record = await OfflineRequestRecord.fromRequestOptions(options);
    final exists =
        _pending.any((item) => item.requestKey() == record.requestKey());
    if (exists) return;

    _pending.add(record);
    _emitCount();
    await _persist();
    AppLogger.debug('Queued offline request: ${options.method} ${options.path}');
  }

  /// Replays queued requests. Returns how many were successfully sent.
  Future<int> flush(Dio dio) async {
    if (_flushing || _pending.isEmpty) return 0;
    _flushing = true;

    final batch = List<OfflineRequestRecord>.from(_pending);
    _pending.clear();
    _emitCount();
    await _persist();

    var replayed = 0;
    for (final record in batch) {
      try {
        await dio.fetch<dynamic>(await record.toRequestOptions());
        await OfflineFormFileStorage.deleteMany(record.attachedFileKeys);
        replayed++;
        AppLogger.debug('Replayed queued request: ${record.method} ${record.path}');
      } catch (e) {
        AppLogger.error('Failed replaying queued request', e);
        _pending.add(record);
      }
    }

    _emitCount();
    await _persist();
    _flushing = false;
    return replayed;
  }

  Future<void> clear() async {
    final keys = _pending.expand((record) => record.attachedFileKeys);
    await OfflineFormFileStorage.deleteMany(keys);
    _pending.clear();
    _emitCount();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await OfflineQueueStorage.save(List<OfflineRequestRecord>.from(_pending));
    } catch (e) {
      AppLogger.error('Failed persisting offline queue', e);
    }
  }

  void _emitCount() {
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(_pending.length);
    }
  }

  void dispose() {
    _pendingCountController.close();
  }
}

final offlineRequestQueue = OfflineRequestQueue.instance;
