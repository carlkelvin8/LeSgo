import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/data_source/chat_remote_datasource.dart';
import '../../data/data_source/dto/chat/chat_dto.dart';
import '../../domain/models/rider_order.dart';
import '../../presentation/provider/main/merchantside/merchant_nav_provider.dart';
import '../../presentation/provider/main/riderside/rider_main_nav_provider.dart';
import '../../presentation/screens/chat/rider_chat_screen.dart';
import '../constants/routers/app_router.dart';
import '../constants/routers/main/main_routes.dart';
import '../di/injection.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';
import '../utils/rider_booking_mapper.dart';
import 'api_service.dart';
import 'notification_payload.dart';
import 'secure_storage_service.dart';

/// Routes notification taps to the correct in-app screen.
class NotificationNavigationService {
  NotificationNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void Function(RiderNavType tab)? riderTabNavigator;
  static void Function(MerchantNavType tab)? merchantTabNavigator;

  static String? _pendingPayload;
  static bool _processing = false;

  static void handlePayload(String? payload) {
    final trimmed = payload?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    _pendingPayload = trimmed;
    unawaited(processPending());
  }

  static Future<void> onAppReady() => processPending();

  static Future<void> processPending() async {
    if (_processing) return;

    final payload = _pendingPayload;
    if (payload == null) return;

    final authToken = await SecureStorageService.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    _processing = true;
    try {
      final parsed = NotificationPayload.parse(payload);
      if (parsed == null || parsed.type == NotificationTargetType.unknown) {
        _pendingPayload = null;
        return;
      }

      if (!context.mounted) return;
      final handled = await _navigate(context, parsed);
      if (handled) {
        _pendingPayload = null;
      }
    } catch (e, stack) {
      AppLogger.error('Notification navigation failed', e, stack);
    } finally {
      _processing = false;
    }
  }

  static Future<bool> _navigate(
    BuildContext context,
    NotificationPayload payload,
  ) async {
    switch (payload.type) {
      case NotificationTargetType.order:
        return _openOrder(context, payload.orderId);
      case NotificationTargetType.chatByOrder:
        return _openChatByOrder(context, payload.orderId);
      case NotificationTargetType.chatByConversation:
        return _openChatByConversation(context, payload.conversationId);
      case NotificationTargetType.merchantOrders:
        return _openMerchantOrders(context);
      case NotificationTargetType.inbox:
        return _openRiderInbox(context);
      case NotificationTargetType.unknown:
        return false;
    }
  }

  static Future<bool> _ensureRiderMain(BuildContext context) async {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != MainRoutes.riderMain) {
      await AppRouter.pushAndRemoveUntil(context, MainRoutes.riderMain);
    }
    riderTabNavigator?.call(RiderNavType.bookings);
    return true;
  }

  static Future<bool> _openRiderInbox(BuildContext context) async {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != MainRoutes.riderMain) {
      await AppRouter.pushAndRemoveUntil(context, MainRoutes.riderMain);
    }
    riderTabNavigator?.call(RiderNavType.inbox);
    return true;
  }

  static Future<bool> _openMerchantOrders(BuildContext context) async {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != MainRoutes.merchantMain) {
      await AppRouter.pushAndRemoveUntil(context, MainRoutes.merchantMain);
    }
    merchantTabNavigator?.call(MerchantNavType.orders);
    return true;
  }

  static Future<bool> _openOrder(BuildContext context, int? orderId) async {
    if (orderId == null) return false;

    await _ensureRiderMain(context);
    if (!context.mounted) return false;

    final orderData = await ApiService.getOrderById(orderId);
    if (orderData == null || !context.mounted) return false;

    try {
      final order = RiderOrder.fromJson(orderData);
      final booking = RiderBookingMapper.fromOrder(order);
      await AppRouter.push(
        context,
        MainRoutes.riderBookingDetail,
        arguments: booking,
      );
      return true;
    } catch (e) {
      AppLogger.error('Failed to open order $orderId from notification', e);
      return false;
    }
  }

  static Future<bool> _openChatByOrder(BuildContext context, int? orderId) async {
    if (orderId == null || orderId <= 0) return false;

    await _openRiderInbox(context);
    if (!context.mounted) return false;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiderChatScreen(orderId: orderId),
      ),
    );
    return true;
  }

  static Future<bool> _openChatByConversation(
    BuildContext context,
    int? conversationId,
  ) async {
    if (conversationId == null) return false;

    await _openRiderInbox(context);
    if (!context.mounted) return false;

    try {
      final dataSource = ChatRemoteDataSource(getIt<DioClient>());
      final conversations = await dataSource.getConversations();
      ConversationDto? conversation;
      for (final conv in conversations) {
        if (conv.id == conversationId) {
          conversation = conv;
          break;
        }
      }
      if (conversation == null || !context.mounted) return false;

      final orderId = conversation.orderId ?? 0;
      if (orderId <= 0) return false;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderChatScreen(
            orderId: orderId,
            customerName: conversation!.customer?.name,
          ),
        ),
      );
      return true;
    } catch (e) {
      AppLogger.error('Failed to open chat conversation $conversationId', e);
      return false;
    }
  }
}
