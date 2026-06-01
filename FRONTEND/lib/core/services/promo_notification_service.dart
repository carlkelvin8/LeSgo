import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';
import '../di/injection.dart';
import '../../data/data_source/device_remote_datasource.dart';
import 'app_preferences_service.dart';
import 'fcm_service.dart';
import 'notification_service.dart';

/// Delivers promotional pushes that deep-link to Offers.
class PromoNotificationService {
  static const _lastPromoDayKey = 'last_promo_push_day';
  static const _promoTopic = 'offers_promos';

  final FcmService _fcmService;
  final NotificationService _notificationService;
  final SharedPreferences _prefs;
  final AppPreferencesService _appPrefs = getIt<AppPreferencesService>();

  PromoNotificationService(
    this._fcmService,
    this._notificationService,
    this._prefs,
  );

  Future<void> initialize() async {
    await _fcmService.subscribeToTopic(_promoTopic);
    _fcmService.registerMessageHandler(_handleRemoteMessage);
    _fcmService.onPromoNotificationTap = _navigateToOffers;

    final token = _fcmService.fcmToken;
    if (token != null) {
      try {
        await getIt<DeviceRemoteDataSource>().registerDeviceToken(
          token: token,
          platform: DeviceRemoteDataSource.currentPlatform(),
        );
      } catch (_) {}
    }
  }

  void _navigateToOffers() {
    final context = AppRouter.navigatorKey.currentContext;
    if (context != null) {
      AppRouter.push(context, MainRoutes.offers);
    }
  }

  void _handleRemoteMessage(Map<String, dynamic> message) {
    if (!_appPrefs.pushPromotionsEnabled) return;

    final type = (message['type'] ?? message['category'] ?? '').toString();
    if (type == 'promotional' ||
        type == 'promo' ||
        type == 'offer' ||
        message['route'] == 'offers') {
      _pendingPromoTitle = message['title']?.toString();
      _pendingPromoBody =
          message['message']?.toString() ?? message['body']?.toString();

      _fcmService.showPushNotification(
        title: _pendingPromoTitle ?? 'New promo for you!',
        body: _pendingPromoBody ??
            'Tap to view exclusive offers on LesGo, LesEat, LesPay & more.',
        payload: 'offers',
        data: message,
      );
    }
  }

  String? _pendingPromoTitle;
  String? _pendingPromoBody;

  Future<void> deliverPromoToOffers(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    if (!context.mounted || !_appPrefs.pushPromotionsEnabled) return;

    final promoTitle =
        _pendingPromoTitle ?? title ?? 'New promo for you!';
    final promoMessage = _pendingPromoBody ??
        message ??
        'Tap to view exclusive offers on LesGo, LesEat, LesPay & more.';

    _pendingPromoTitle = null;
    _pendingPromoBody = null;

    await _fcmService.showPushNotification(
      title: promoTitle,
      body: promoMessage,
      payload: 'offers',
      data: const {'type': 'promotional', 'route': 'offers'},
    );

    _notificationService.showNotificationByType(
      context,
      type: NotificationType.promotional,
      message: '$promoTitle — $promoMessage',
      data: const {'route': 'offers'},
      onTap: () => AppRouter.push(context, MainRoutes.offers),
    );
  }

  Future<void> maybeShowDailyPromoPush(
    BuildContext context, {
    required String featuredTitle,
    required String featuredDiscount,
  }) async {
    if (!_appPrefs.pushPromotionsEnabled) return;

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
