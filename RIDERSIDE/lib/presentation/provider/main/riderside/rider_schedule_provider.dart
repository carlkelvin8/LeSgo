import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderScheduleEntry {
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isEnabled;

  const RiderScheduleEntry({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'is_enabled': isEnabled,
      };

  factory RiderScheduleEntry.fromJson(Map<String, dynamic> json) =>
      RiderScheduleEntry(
        dayOfWeek: json['day_of_week'] as int,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        isEnabled: json['is_enabled'] as bool? ?? true,
      );

  RiderScheduleEntry copyWith({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isEnabled,
  }) =>
      RiderScheduleEntry(
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isEnabled: isEnabled ?? this.isEnabled,
      );
}

class RiderScheduleState {
  final List<RiderScheduleEntry> entries;

  const RiderScheduleState({this.entries = const []});
}

class RiderScheduleNotifier extends StateNotifier<RiderScheduleState> {
  RiderScheduleNotifier() : super(const RiderScheduleState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('rider_schedules');
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) =>
            RiderScheduleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    state = RiderScheduleState(entries: list);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rider_schedules',
      jsonEncode(state.entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addEntry(RiderScheduleEntry entry) async {
    state = RiderScheduleState(entries: [...state.entries, entry]);
    await _save();
  }

  Future<void> removeEntry(int index) async {
    final updated = [...state.entries]..removeAt(index);
    state = RiderScheduleState(entries: updated);
    await _save();
  }

  Future<void> toggleEntry(int index) async {
    final entry = state.entries[index];
    final updated = [...state.entries];
    updated[index] = entry.copyWith(isEnabled: !entry.isEnabled);
    state = RiderScheduleState(entries: updated);
    await _save();
  }
}

final riderScheduleProvider =
    StateNotifierProvider<RiderScheduleNotifier, RiderScheduleState>(
  (ref) => RiderScheduleNotifier(),
);
