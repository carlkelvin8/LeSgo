import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Persisted rider auto-payout configuration.
class ScheduledPayoutPreferences {
  final String frequency; // 'daily' | 'weekly' | 'monthly'
  final int weeklyDay; // 1=Mon .. 7=Sun
  final int monthlyDay; // 1..28
  final String time; // 'HH:mm'
  final double threshold;
  final String? accountProvider; // e.g. 'gcash', 'maya'

  const ScheduledPayoutPreferences({
    this.frequency = 'weekly',
    this.weeklyDay = 1,
    this.monthlyDay = 1,
    this.time = '09:00',
    this.threshold = 500,
    this.accountProvider,
  });

  ScheduledPayoutPreferences copyWith({
    String? frequency,
    int? weeklyDay,
    int? monthlyDay,
    String? time,
    double? threshold,
    String? accountProvider,
  }) =>
      ScheduledPayoutPreferences(
        frequency: frequency ?? this.frequency,
        weeklyDay: weeklyDay ?? this.weeklyDay,
        monthlyDay: monthlyDay ?? this.monthlyDay,
        time: time ?? this.time,
        threshold: threshold ?? this.threshold,
        accountProvider: accountProvider ?? this.accountProvider,
      );

  Map<String, dynamic> toJson() => {
        'frequency': frequency,
        'weekly_day': weeklyDay,
        'monthly_day': monthlyDay,
        'time': time,
        'threshold': threshold,
        'account_provider': accountProvider,
      };

  factory ScheduledPayoutPreferences.fromJson(Map<String, dynamic> json) {
    return ScheduledPayoutPreferences(
      frequency: json['frequency'] as String? ?? 'weekly',
      weeklyDay: _clampInt(json['weekly_day'], 1, 7, 1),
      monthlyDay: _clampInt(json['monthly_day'], 1, 28, 1),
      time: json['time'] as String? ?? '09:00',
      threshold: _clampDouble(json['threshold'], 0, double.infinity, 500),
      accountProvider: (json['account_provider'] as String?) ??
          (json['account'] as String?),
    );
  }

  static int _clampInt(dynamic value, int min, int max, int fallback) {
    final parsed = value is num
        ? value.toInt()
        : value is String
            ? int.tryParse(value)
            : null;
    if (parsed == null) return fallback;
    return parsed.clamp(min, max);
  }

  static double _clampDouble(
    dynamic value,
    double min,
    double max,
    double fallback,
  ) {
    final parsed = value is num
        ? value.toDouble()
        : value is String
            ? double.tryParse(value)
            : null;
    if (parsed == null) return fallback;
    return parsed.clamp(min, max);
  }
}

/// Stores rider scheduled-payout preferences.
///
/// Local-first: prefs are always written so the feature works offline and
/// settings are never lost. When online, a best-effort push keeps the server
/// copy in sync so the payout engine can honor the schedule server-side.
class ScheduledPayoutService {
  ScheduledPayoutService._();

  static const _endpoint = '/v1/wallets/my/scheduled-payout';

  /// Loads prefs, preferring the server copy when reachable and falling back
  /// to the local cache (or default preferences) otherwise.
  static Future<ScheduledPayoutPreferences> load() async {
    try {
      final response = await ApiService.dio.get(_endpoint);
      final raw = response.data;
      final body =
          raw is Map ? (raw['data'] ?? raw) as Map : const <String, dynamic>{};
      if (body.isEmpty) {
        return _readLocal();
      }
      final server =
          ScheduledPayoutPreferences.fromJson(Map<String, dynamic>.from(body));
      await _writeLocal(server);
      return server;
    } catch (e) {
      debugPrint('Scheduled payout server load failed, using local: $e');
    }
    return _readLocal();
  }

  /// Persists locally (always) and pushes to the server (best-effort).
  /// Returns `true` when the server acknowledged the sync.
  static Future<bool> save(ScheduledPayoutPreferences prefs) async {
    await _writeLocal(prefs);
    try {
      await ApiService.dio.put(_endpoint, data: prefs.toJson());
      return true;
    } catch (e) {
      debugPrint('Scheduled payout server sync failed (kept locally): $e');
      return false;
    }
  }

  static Future<ScheduledPayoutPreferences> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final frequency =
        prefs.getString('rider_payout_frequency') ?? 'weekly';

    return ScheduledPayoutPreferences(
      frequency: frequency,
      weeklyDay: prefs.getInt('rider_payout_weekly_day') ?? 1,
      monthlyDay: prefs.getInt('rider_payout_monthly_day') ?? 1,
      time: _localTime(prefs.getString('rider_payout_time')),
      threshold:
          double.tryParse(prefs.getString('rider_payout_threshold') ?? '') ??
              500,
      accountProvider: prefs.getString('rider_payout_account'),
    );
  }

  static Future<void> _writeLocal(ScheduledPayoutPreferences prefs) async {
    final store = await SharedPreferences.getInstance();
    await store.setString('rider_payout_frequency', prefs.frequency);
    await store.setInt('rider_payout_weekly_day', prefs.weeklyDay);
    await store.setInt('rider_payout_monthly_day', prefs.monthlyDay);
    await store.setString('rider_payout_time', prefs.time);
    await store.setString('rider_payout_threshold', prefs.threshold.toString());
    if (prefs.accountProvider != null) {
      await store.setString('rider_payout_account', prefs.accountProvider!);
    }
    await store.setString(
      'rider_payout_prefs',
      jsonEncode(prefs.toJson()),
    );
  }

  /// Normalizes a stored time ('HH:mm' or 'h:mm a') to 'HH:mm', defaulting to
  /// 09:00 when missing/unparseable.
  static String _localTime(String? raw) {
    if (raw == null || raw.isEmpty) return '09:00';
    final parts = raw.split(':');
    if (parts.length != 2) return '09:00';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
    if (hour == null || minute == null) return '09:00';
    final normalizedHour = hour.clamp(0, 23);
    final normalizedMinute = minute.clamp(0, 59);
    return '${normalizedHour.toString().padLeft(2, '0')}:'
        '${normalizedMinute.toString().padLeft(2, '0')}';
  }
}