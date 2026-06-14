import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_api.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../widgets/common/retry_widget.dart';

class RiderNotificationCenterScreen extends StatefulWidget {
  const RiderNotificationCenterScreen({super.key});

  @override
  State<RiderNotificationCenterScreen> createState() =>
      _RiderNotificationCenterScreenState();
}

class _RiderNotificationCenterScreenState
    extends State<RiderNotificationCenterScreen> {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.fontSize(context, 18),
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(fontFamily: 'TT Fors', color: Color(0xFF5F2D82)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
            )
          : _error != null && _notifications.isEmpty
              ? RetryWidget(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: const Color(0xFF5F2D82),
                  onRefresh: _load,
                  child: _notifications.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: ResponsiveUtils.spacing(context, 80)),
                            Center(
                              child: Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(
                            ResponsiveUtils.spacing(context, 16),
                          ),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            return _NotificationTile(
                              notification: n,
                              formattedDate: _formatDate(n.createdAt),
                              onTap: () => _onTapNotification(n),
                            );
                          },
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFF1E8F8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5F2D82),
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
