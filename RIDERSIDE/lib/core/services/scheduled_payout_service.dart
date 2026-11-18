import 'api_service.dart';

/// Automatic payouts require explicit consent acknowledged by the server.
/// Device preferences must never enable payouts or leak across account switches.
class ScheduledPayoutPreferences {
  final bool enabled;
  final String frequency;
  final int weeklyDay;
  final int monthlyDay;
  final String time;
  final double threshold;
  final String? accountProvider;
  final String? nextRunAt;
  final String? lastResult;

  const ScheduledPayoutPreferences({
    this.enabled = false,
    this.frequency = 'weekly',
    this.weeklyDay = 1,
    this.monthlyDay = 1,
    this.time = '09:00',
    this.threshold = 500,
    this.accountProvider,
    this.nextRunAt,
    this.lastResult,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'frequency': frequency,
    'weekly_day': weeklyDay,
    'monthly_day': monthlyDay,
    'time': time,
    'threshold': threshold,
    'account_provider': accountProvider,
  };

  factory ScheduledPayoutPreferences.fromJson(Map<String, dynamic> json) {
    final frequency = json['frequency'];
    final weeklyDay = int.tryParse('${json['weekly_day']}');
    final monthlyDay = int.tryParse('${json['monthly_day']}');
    final threshold = double.tryParse('${json['threshold']}');
    final time = json['time']?.toString() ?? '';
    if (json['enabled'] is! bool ||
        !['daily', 'weekly', 'monthly'].contains(frequency) ||
        weeklyDay == null ||
        weeklyDay < 1 ||
        weeklyDay > 7 ||
        monthlyDay == null ||
        monthlyDay < 1 ||
        monthlyDay > 28 ||
        threshold == null ||
        !threshold.isFinite ||
        threshold < 10 ||
        threshold > 100000 ||
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
      throw const FormatException(
        'Invalid scheduled payout settings from server.',
      );
    }
    return ScheduledPayoutPreferences(
      enabled: json['enabled'] as bool,
      frequency: frequency as String,
      weeklyDay: weeklyDay,
      monthlyDay: monthlyDay,
      time: time,
      threshold: threshold,
      accountProvider: json['account_provider'] as String?,
      nextRunAt: json['next_run_at'] as String?,
      lastResult: json['last_result'] as String?,
    );
  }
}

class ScheduledPayoutService {
  ScheduledPayoutService._();

  static const _endpoint = '/v1/wallets/my/scheduled-payout';

  static Future<ScheduledPayoutPreferences> load() async {
    final response = await ApiService.dio.get(_endpoint);
    final raw = response.data;
    final body = raw is Map ? raw['data'] : null;
    if (body is! Map) {
      throw const FormatException(
        'Unable to verify scheduled payout settings.',
      );
    }
    return ScheduledPayoutPreferences.fromJson(Map<String, dynamic>.from(body));
  }

  /// Returns only after the server has validated and persisted the settings.
  static Future<bool> save(ScheduledPayoutPreferences prefs) async {
    final response = await ApiService.dio.put(_endpoint, data: prefs.toJson());
    final raw = response.data;
    if (raw is! Map || raw['success'] != true || raw['data'] is! Map) {
      throw const FormatException(
        'The server did not confirm the scheduled payout.',
      );
    }
    ScheduledPayoutPreferences.fromJson(
      Map<String, dynamic>.from(raw['data'] as Map),
    );
    return true;
  }
}
