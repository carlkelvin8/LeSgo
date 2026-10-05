import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/merchant_order_ops_utils.dart';
import '../../../../data/data_source/dto/merchant/order_dto.dart';

const int kDefaultPrepMinutes = 15;
const String _prefsKey = 'merchant_prep_timers_v1';

class MerchantPrepTimerEntry {
  final int orderId;
  final DateTime startedAt;
  final int durationMinutes;

  const MerchantPrepTimerEntry({
    required this.orderId,
    required this.startedAt,
    required this.durationMinutes,
  });

  DateTime get endsAt => startedAt.add(Duration(minutes: durationMinutes));

  Duration get remaining => endsAt.difference(DateTime.now());

  bool get isOverdue => remaining.isNegative;

  String get displayLabel {
    final abs = remaining.abs();
    final minutes = abs.inMinutes;
    final seconds = abs.inSeconds % 60;
    final clock = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return isOverdue ? '-$clock' : clock;
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'startedAt': startedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory MerchantPrepTimerEntry.fromJson(Map<String, dynamic> json) {
    return MerchantPrepTimerEntry(
      orderId: (json['orderId'] as num).toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
    );
  }
}

class MerchantPrepTimerNotifier extends StateNotifier<Map<int, MerchantPrepTimerEntry>> {
  Timer? _tickTimer;
  bool _loaded = false;

  MerchantPrepTimerNotifier() : super(const {}) {
    _load();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isNotEmpty) {
        state = Map<int, MerchantPrepTimerEntry>.from(state);
      }
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _loaded = true;
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final timers = <int, MerchantPrepTimerEntry>{};
      for (final entry in decoded.entries) {
        final timer = MerchantPrepTimerEntry.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        timers[timer.orderId] = timer;
      }
      state = timers;
    } catch (_) {
      state = const {};
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    if (!_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{
      for (final entry in state.entries) entry.key.toString(): entry.value.toJson(),
    };
    await prefs.setString(_prefsKey, jsonEncode(encoded));
  }

  Future<void> start(int orderId, {int durationMinutes = kDefaultPrepMinutes}) async {
    final next = Map<int, MerchantPrepTimerEntry>.from(state);
    next[orderId] = MerchantPrepTimerEntry(
      orderId: orderId,
      startedAt: DateTime.now(),
      durationMinutes: durationMinutes,
    );
    state = next;
    await _persist();
  }

  Future<void> remove(int orderId) async {
    if (!state.containsKey(orderId)) return;
    final next = Map<int, MerchantPrepTimerEntry>.from(state)..remove(orderId);
    state = next;
    await _persist();
  }

  MerchantPrepTimerEntry? forOrder(int orderId) => state[orderId];

  /// Keeps timers aligned with active prep orders (bootstrap + cleanup).
  Future<void> syncWithOrders(List<OrderDto> orders) async {
    if (!_loaded) {
      await _load();
    }

    final next = Map<int, MerchantPrepTimerEntry>.from(state);
    final activePrepIds = <int>{};

    for (final order in orders) {
      if (!MerchantOrderOpsUtils.showsPrepTimer(order.status)) continue;
      activePrepIds.add(order.id);

      if (!next.containsKey(order.id)) {
        next[order.id] = MerchantPrepTimerEntry(
          orderId: order.id,
          startedAt: _resolvePrepStartTime(order),
          durationMinutes: kDefaultPrepMinutes,
        );
      }
    }

    for (final orderId in next.keys.toList()) {
      if (!activePrepIds.contains(orderId)) {
        next.remove(orderId);
      }
    }

    if (mapEquals(state, next)) return;
    state = next;
    await _persist();
  }

  DateTime _resolvePrepStartTime(OrderDto order) {
    for (final value in [order.updatedAt, order.createdAt]) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {}
    }
    return DateTime.now();
  }

  bool mapEquals(
    Map<int, MerchantPrepTimerEntry> a,
    Map<int, MerchantPrepTimerEntry> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null) return false;
      if (other.startedAt != entry.value.startedAt ||
          other.durationMinutes != entry.value.durationMinutes) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}

final merchantPrepTimerProvider =
    StateNotifierProvider<MerchantPrepTimerNotifier, Map<int, MerchantPrepTimerEntry>>(
  (ref) => MerchantPrepTimerNotifier(),
);
