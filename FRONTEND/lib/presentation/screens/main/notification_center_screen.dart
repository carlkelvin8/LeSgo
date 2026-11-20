import 'package:lesgo/core/utils/responsive_utils.dart';
import 'package:lesgo/presentation/widgets/common/empty_state_view.dart';
import 'package:lesgo/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lesgo/core/theme/app_colors.dart';
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
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              child: TextButton(
                onPressed: notifier.markAllAsRead,
                child: const Text('Mark all read'),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: state.isLoading && state.notifications.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : state.notifications.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyStateView(
                    icon: Icons.notifications_none_rounded,
                    title: 'You’re all caught up',
                    message: 'New order updates and offers will show up here.',
                  ),
                ],
              )
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.screenPadding(context),
                  AppSpace.sm,
                  ResponsiveUtils.screenPadding(context),
                  AppSpace.xl,
                ),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpace.sm),
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  final accent = AppColors.accent(
                    context,
                    const Color(0xFF5F2D82),
                  );
                  final scheme = Theme.of(context).colorScheme;
                  return AppCard(
                    padding: const EdgeInsets.all(AppSpace.md),
                    onTap: () => _openNotification(context, ref, notification),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: accent.withValues(
                            alpha: notification.isRead ? 0.08 : 0.16,
                          ),
                          child: Icon(
                            _iconFor(notification.type),
                            color: accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  height: 1.35,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notification.isRead)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpace.sm,
                              top: 6,
                            ),
                            child: Icon(Icons.circle, size: 9, color: accent),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
