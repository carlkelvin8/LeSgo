import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/state/user_session_epoch.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/di/injection.dart';
import '../../../data/data_source/dto/notification/notification_dto.dart';

class NotificationState {
  final List<NotificationDto> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationDto>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(NotificationState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    await _notificationService.initialize();
    _loadNotifications();
    state = state.copyWith(isLoading: false);
  }

  void _loadNotifications() {
    state = state.copyWith(
      notifications: _notificationService.notifications,
      unreadCount: _notificationService.unreadCount,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _notificationService.refreshFromBackend();
    _loadNotifications();
    state = state.copyWith(isLoading: false);
  }

  Future<void> markAsRead(int notificationId) async {
    await _notificationService.markAsRead(notificationId);
    _loadNotifications();
  }

  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
    _loadNotifications();
  }

  Future<void> clearAll() async {
    await _notificationService.clearAll();
    _loadNotifications();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      ref.watch(userSessionEpochProvider);
      return NotificationNotifier(getIt<NotificationService>());
    });
