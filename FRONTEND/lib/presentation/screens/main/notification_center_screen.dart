import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../data/data_source/dto/notification/notification_dto.dart';
import '../../provider/notification/notification_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

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
        child: state.isLoading && state.notifications.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : state.notifications.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Icon(Icons.notifications_none, size: 52, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('You’re all caught up')),
                ],
              )
            : ListView.separated(
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return ListTile(
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
                  );
                },
              ),
      ),
    );
  }
}
