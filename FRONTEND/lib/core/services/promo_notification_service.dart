import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';
import 'fcm_service.dart';
import 'notification_service.dart';

/// Delivers promotional pushes that deep-link to Offers.
class PromoNotificationService {
  static const _lastPromoDayKey = 'last_promo_push_day';
  static const _promoTopic = 'offers_promos';

  final FcmService _fcmService;
  final NotificationService _notificationService;
  final SharedPreferences _prefs;

  PromoNotificationService(
    this._fcmService,
    this._notificationService,
    this._prefs,
  );

  Future<void> initialize() async {
    await _fcmService.subscribeToTopic(_promoTopic);
    _fcmService.registerMessageHandler(_handleRemoteMessage);
  }

  void _handleRemoteMessage(Map<String, dynamic> message) {
    final type = (message['type'] ?? message['category'] ?? '').toString();
    if (type == 'promotional' ||
        type == 'promo' ||
        type == 'offer' ||
        message['route'] == 'offers') {
      _pendingPromoTitle = message['title']?.toString();
      _pendingPromoBody = message['message']?.toString() ??
          message['body']?.toString();
    }
  }

  String? _pendingPromoTitle;
  String? _pendingPromoBody;

  /// Show pending FCM promo or a daily featured-offer nudge (once per day).
  Future<void> deliverPromoToOffers(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    if (!context.mounted) return;

    final promoTitle = _pendingPromoTitle ??
        title ??
        'New promo for you!';
    final promoMessage = _pendingPromoBody ??
        message ??
        'Tap to view exclusive offers on LesGo, LesEat, LesPay & more.';

    _pendingPromoTitle = null;
    _pendingPromoBody = null;

    _notificationService.showNotificationByType(
      context,
      type: NotificationType.promotional,
      message: '$promoTitle — $promoMessage',
      data: {'route': 'offers'},
      onTap: () => AppRouter.push(context, MainRoutes.offers),
    );
  }

  /// At most one local promo banner per calendar day on home.
  Future<void> maybeShowDailyPromoPush(
    BuildContext context, {
    required String featuredTitle,
    required String featuredDiscount,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final last = _prefs.getString(_lastPromoDayKey);
    if (last == today) return;

    await _prefs.setString(_lastPromoDayKey, today);
    if (!context.mounted) return;

    await deliverPromoToOffers(
      context,
      title: featuredTitle,
      message: '$featuredDiscount — open Offers to claim your code.',
    );
  }
}
