import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/app_preferences_service.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/data_source/dto/notification/notification_dto.dart';
import '../../provider/notification/notification_provider.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  late bool _promotions;
  late bool _orderUpdates;
  late bool _missionReminders;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<AppPreferencesService>();
    _promotions = prefs.pushPromotionsEnabled;
    _orderUpdates = prefs.pushOrderUpdatesEnabled;
    _missionReminders = prefs.pushMissionRemindersEnabled;
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    final prefs = getIt<AppPreferencesService>();
    await prefs.setPushPromotionsEnabled(_promotions);
    await prefs.setPushOrderUpdatesEnabled(_orderUpdates);
    await prefs.setPushMissionRemindersEnabled(_missionReminders);
    if (!mounted) return;
    setState(() => _saving = false);
    SnackBarUtils.showSuccess(context, 'Notification preferences saved.');
  }

  IconData _iconFor(String type) => switch (type.toLowerCase()) {
    'order_accepted' || 'driver_assigned' => Icons.local_shipping_outlined,
    'order_picked_up' || 'order_in_transit' => Icons.delivery_dining,
    'order_delivered' => Icons.task_alt,
    'order_cancelled' => Icons.cancel_outlined,
    'promotional' || 'offer' => Icons.local_offer_outlined,
    'order_rating_reminder' => Icons.star_outline,
    _ => Icons.notifications_outlined,
  };

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationDto notification,
  ) async {
    await ref.read(notificationProvider.notifier).markAsRead(notification.id);
    if (!context.mounted) return;

    final type = notification.type.toLowerCase();
    if (type == 'promotional' || type == 'offer') {
      AppRouter.push(context, MainRoutes.offers);
    } else if (notification.data?['order_id'] != null ||
        type.startsWith('order_') ||
        type == 'driver_assigned') {
      AppRouter.push(context, MainRoutes.orderHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final notificationItems = <Widget>[];

    if (state.isLoading && state.notifications.isEmpty) {
      notificationItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (state.notifications.isEmpty) {
      notificationItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.notifications_none, size: 52, color: Colors.grey),
              SizedBox(height: 12),
              Text('You’re all caught up'),
            ],
          ),
        ),
      );
    } else {
      for (var index = 0; index < state.notifications.length; index++) {
        final notification = state.notifications[index];
        notificationItems.add(
          Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: notification.isRead
                      ? Colors.grey.shade100
                      : const Color(0xFFEDE5F4),
                  child: Icon(
                    _iconFor(notification.type),
                    color: const Color(0xFF5F2D82),
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.w500
                        : FontWeight.w700,
                  ),
                ),
                subtitle: Text(notification.message),
                trailing: notification.isRead
                    ? null
                    : const Icon(
                        Icons.circle,
                        size: 9,
                        color: Color(0xFF5F2D82),
                      ),
                onTap: () => _openNotification(context, ref, notification),
              ),
              if (index < state.notifications.length - 1)
                const Divider(height: 1),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          padding: EdgeInsets.only(
            top: ResponsiveUtils.spacing(context, 16),
            bottom: ResponsiveUtils.spacing(context, 24),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 16),
              ),
              child: Text(
                'Notification settings',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                ),
              ),
            ),
            Card(
              margin: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Promotions & offers'),
                    subtitle: const Text('Daily promos and voucher alerts'),
                    value: _promotions,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => setState(() => _promotions = value),
                  ),
                  SwitchListTile(
                    title: const Text('Order updates'),
                    subtitle: const Text(
                      'Driver assigned, picked up, delivered',
                    ),
                    value: _orderUpdates,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) => setState(() => _orderUpdates = value),
                  ),
                  SwitchListTile(
                    title: const Text('Mission reminders'),
                    subtitle: const Text('Referral and mission reward alerts'),
                    value: _missionReminders,
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) =>
                        setState(() => _missionReminders = value),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveUtils.spacing(context, 16),
                      0,
                      ResponsiveUtils.spacing(context, 16),
                      ResponsiveUtils.spacing(context, 16),
                    ),
                    child: FilledButton(
                      onPressed: _saving ? null : _savePreferences,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save preferences'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.spacing(context, 16),
                0,
                ResponsiveUtils.spacing(context, 16),
                ResponsiveUtils.spacing(context, 8),
              ),
              child: Text(
                'Recent notifications',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                ),
              ),
            ),
            ...notificationItems,
          ],
        ),
      ),
    );
  }
}
