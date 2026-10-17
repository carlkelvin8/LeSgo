import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_api.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../widgets/common/retry_widget.dart';
import '../../../widgets/common/settings_page_kit.dart';

class RiderNotificationCenterScreen extends ConsumerStatefulWidget {
  const RiderNotificationCenterScreen({super.key});

  @override
  ConsumerState<RiderNotificationCenterScreen> createState() =>
      _RiderNotificationCenterScreenState();
}

class _RiderNotificationCenterScreenState
    extends ConsumerState<RiderNotificationCenterScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.fetchNotifications(),
        ApiService.fetchNotificationUnreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _notifications = results[0] as List<AppNotification>;
        _unreadCount = results[1] as int;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      await _load();
      if (mounted) {
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.translate('all_marked_read', lang))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    }
  }

  Future<void> _onTapNotification(AppNotification notification) async {
    if (!notification.isRead) {
      try {
        await ApiService.markNotificationRead(notification.id);
      } catch (_) {}
    }
    await _load();
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, h:mm a').format(parsed.toLocal());
  }


  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);
    final unread = _notifications.where((n) => !n.isRead).toList();
    final earlier = _notifications.where((n) => n.isRead).toList();

    Widget tile(AppNotification n) => _NotificationTile(
          notification: n,
          formattedDate: _formatDate(n.createdAt),
          onTap: () => _onTapNotification(n),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SettingsKit.appBar(
        context,
        '',
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _markAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
                style: TextButton.styleFrom(
                  foregroundColor: SettingsKit.brand,
                  backgroundColor: SettingsKit.brandTint,
                  textStyle: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsPageHeader(
            title: AppLocalization.translate('notifications', lang),
            subtitle: _unreadCount > 0
                ? 'You have $_unreadCount unread ${_unreadCount == 1 ? 'notification' : 'notifications'}'
                : 'Order updates, payouts and announcements',
            padding: EdgeInsets.fromLTRB(hp, 0, hp, 12),
          ),
          Expanded(child: _body(lang, hp, unread, earlier, tile)),
        ],
      ),
    );
  }

  Widget _body(
    AppLanguage lang,
    double hp,
    List<AppNotification> unread,
    List<AppNotification> earlier,
    Widget Function(AppNotification) tile,
  ) {
    return _loading
          ? const Center(
              child: CircularProgressIndicator(color: SettingsKit.brand),
            )
          : _error != null && _notifications.isEmpty
              ? RetryWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: SettingsKit.brand,
                  onRefresh: _load,
                  child: _notifications.isEmpty
                      ? SettingsScrollableEmpty(
                          child: SettingsEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: AppLocalization.translate(
                                'no_notifications', lang),
                            subtitle:
                                'Order updates, payouts and announcements will show up here.',
                          ),
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(hp, 8, hp, 32),
                          children: [
                            if (unread.isNotEmpty) ...[
                              SettingsSectionLabel(
                                'New · ${unread.length}',
                                color: SettingsKit.brand,
                              ),
                              ...unread.map(tile),
                              const SizedBox(height: 14),
                            ],
                            if (earlier.isNotEmpty) ...[
                              const SettingsSectionLabel('Earlier'),
                              ...earlier.map(tile),
                            ],
                          ],
                        ),
                );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String formattedDate;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.formattedDate,
    required this.onTap,
  });

  (IconData, Color) get _visual {
    final type = notification.type.toLowerCase();
    if (type.contains('order') || type.contains('booking')) {
      return (Icons.receipt_long_rounded, SettingsKit.brand);
    }
    if (type.contains('payment') ||
        type.contains('wallet') ||
        type.contains('payout') ||
        type.contains('earning')) {
      return (Icons.account_balance_wallet_rounded, SettingsKit.success);
    }
    if (type.contains('promo') || type.contains('offer')) {
      return (Icons.local_offer_rounded, SettingsKit.warning);
    }
    if (type.contains('alert') || type.contains('warning')) {
      return (Icons.campaign_rounded, SettingsKit.danger);
    }
    return (Icons.notifications_rounded, SettingsKit.brand);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual;
    final unread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: SettingsKit.cardDecoration(
        color: unread ? const Color(0xFFFCF9FF) : Colors.white,
        borderColor: unread
            ? SettingsKit.brand.withValues(alpha: 0.25)
            : SettingsKit.border,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsIconBox(icon: icon, color: color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 14),
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w700,
                                color: SettingsKit.ink,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 4, left: 8),
                              decoration: const BoxDecoration(
                                color: SettingsKit.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (notification.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            height: 1.4,
                            color: SettingsKit.muted,
                          ),
                        ),
                      ],
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
