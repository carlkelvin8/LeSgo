import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../../data/data_source/dto/order/order_dto.dart';
import '../../data/data_source/order_remote_datasource.dart';
import '../../data/data_source/wallet_remote_datasource.dart';
import '../../domain/entities/support/ibow_expression.dart';
import '../constants/routers/booking/booking_routes.dart';
import '../constants/routers/main/main_routes.dart';
import '../di/injection.dart';
import '../utils/api_error_mapper.dart';
import '../utils/driver_display_utils.dart';
import '../utils/money.dart';
import '../utils/order_cancel_utils.dart';
import '../utils/order_progress.dart';
import '../utils/order_service_labels.dart';

enum AgentActionKind { cancelOrder, reorder }

/// Something IBOW can do for the customer, but only after they tap its
/// button. The model can *propose* an action; it never runs one on its own.
class AgentAction {
  AgentAction({
    required this.id,
    required this.kind,
    required this.label,
    required this.detail,
    required Future<String> Function() run,
  }) : _run = run;

  final String id;
  final AgentActionKind kind;

  /// Text on the button, e.g. "Cancel LesEat order".
  final String label;

  /// One line that says exactly what will happen.
  final String detail;
  final Future<String> Function() _run;

  /// Performs the action and returns a friendly confirmation. Throws on error.
  Future<String> execute() => _run();
}

/// A button that opens a screen in the app.
class AgentLink {
  const AgentLink(this.label, this.route);
  final String label;
  final String route;
}

class AgentReply {
  const AgentReply(
    this.text, {
    this.mood = IbowExpression.neutral,
    this.actions = const [],
    this.links = const [],
  });

  final String text;
  final IbowExpression mood;
  final List<AgentAction> actions;
  final List<AgentLink> links;
}

/// The things IBOW can look up and do, backed by the same authenticated API
/// the rest of the app uses. Orders are exposed to the model only as short
/// references ("o1", "o2") that live on this device for the conversation, so
/// real database ids never appear in the chat or in what the model sees.
class ChatAgentTools {
  ChatAgentTools({
    OrderRemoteDataSource? orders,
    WalletRemoteDataSource? wallet,
  }) : _ordersOverride = orders,
       _walletOverride = wallet;

  final OrderRemoteDataSource? _ordersOverride;
  final WalletRemoteDataSource? _walletOverride;
  OrderRemoteDataSource get _orders =>
      _ordersOverride ?? getIt<OrderRemoteDataSource>();
  WalletRemoteDataSource get _wallet =>
      _walletOverride ?? getIt<WalletRemoteDataSource>();

  final Map<String, OrderDto> _byRef = {};
  final List<AgentAction> _actions = [];
  final List<AgentLink> _links = [];

  /// Actions and links produced since the last [takeSideEffects].
  ({List<AgentAction> actions, List<AgentLink> links}) takeSideEffects() {
    final out = (actions: List.of(_actions), links: List.of(_links));
    _actions.clear();
    _links.clear();
    return out;
  }

  void reset() {
    _byRef.clear();
    _actions.clear();
    _links.clear();
  }

  static bool isActive(OrderDto o) {
    final s = o.status.trim().toLowerCase();
    return s != 'completed' &&
        s != 'delivered' &&
        s != 'cancelled' &&
        s != 'canceled' &&
        s != 'failed';
  }

  static bool isCompleted(OrderDto o) {
    final s = o.status.trim().toLowerCase();
    return s == 'completed' || s == 'delivered';
  }

  /// Loads the latest orders and (re)assigns the on-device references.
  Future<List<MapEntry<String, OrderDto>>> loadOrders() async {
    final response = await _orders.getOrders(perPage: 20);
    _byRef.clear();
    final out = <MapEntry<String, OrderDto>>[];
    for (var i = 0; i < response.data.length; i++) {
      final ref = 'o${i + 1}';
      _byRef[ref] = response.data[i];
      out.add(MapEntry(ref, response.data[i]));
    }
    return out;
  }

  /// What the model (and the local agent) may know about an order. No ids,
  /// phone numbers or addresses.
  Map<String, Object?> summarize(String ref, OrderDto o) {
    final service = OrderServiceLabels.labelForOrder(o);
    final driver = DriverInfo.fromOrder(o);
    final created = DateTime.tryParse(o.createdAt ?? '')?.toLocal();
    return {
      'ref': ref,
      'service': service,
      'status': o.status,
      'status_text': OrderProgress.of(
        service: service,
        status: o.status,
        scheduledAt: o.scheduledAt,
      ).headline,
      'total_php': o.effectiveTotalAmount,
      if (created != null) 'date': DateFormat('MMM d, h:mm a').format(created),
      'payment_method': o.paymentMethod,
      'payment_status': o.paymentStatus,
      'items': [
        for (final i in o.effectiveItems.take(4)) '${i.name} x${i.quantity}',
      ],
      if (driver != null) 'driver_first_name': driver.name.split(' ').first,
      if (driver?.rating != null) 'driver_rating': driver!.rating,
      'can_cancel': isActive(o) && canCustomerCancelOrderStatus(o.status),
      'can_reorder': isCompleted(o),
    };
  }

  // ---- tools the model can call ------------------------------------------

  Future<Map<String, Object?>> getOrders({
    String filter = 'recent',
    int limit = 5,
  }) async {
    final all = await loadOrders();
    final picked = all
        .where((e) {
          switch (filter) {
            case 'active':
              return isActive(e.value);
            case 'completed':
              return isCompleted(e.value);
            default:
              return true;
          }
        })
        .take(limit.clamp(1, 10))
        .toList();
    return {
      'count': picked.length,
      'orders': [for (final e in picked) summarize(e.key, e.value)],
    };
  }

  Future<Map<String, Object?>> getWalletBalance() async {
    final wallet = await _wallet.getMyWallet();
    return {'balance_php': wallet.balance, 'currency': wallet.currency};
  }

  Map<String, Object?> requestCancelOrder(String ref, {String? reason}) {
    final order = _byRef[ref];
    if (order == null) {
      return {'error': 'Unknown order reference. Call get_orders first.'};
    }
    if (!(isActive(order) && canCustomerCancelOrderStatus(order.status))) {
      return {'error': 'This order can no longer be cancelled.'};
    }
    _actions.add(_cancelAction(order, reason));
    return {
      'status': 'awaiting_user_confirmation',
      'note':
          'A Cancel button was shown to the customer. Tell them to tap it to confirm. Do not say it is cancelled yet.',
    };
  }

  Map<String, Object?> requestReorder(String ref) {
    final order = _byRef[ref];
    if (order == null) {
      return {'error': 'Unknown order reference. Call get_orders first.'};
    }
    if (!isCompleted(order)) {
      return {'error': 'Only completed orders can be ordered again.'};
    }
    _actions.add(_reorderAction(order));
    return {
      'status': 'awaiting_user_confirmation',
      'note':
          'An Order again button was shown to the customer. Tell them to tap it to confirm. Do not say it is placed yet.',
    };
  }

  static const _screens = {
    'ride': AgentLink('Open LesRide', BookingRoutes.lesride),
    'delivery': AgentLink('Open LesGo', BookingRoutes.lesgo),
    'food': AgentLink('Open LesEat', BookingRoutes.leseat),
    'shop': AgentLink('Open LesBuy', BookingRoutes.lesbuy),
    'transport': AgentLink('Open LesTransport', BookingRoutes.lesport),
    'wallet': AgentLink('Open LesPay', MainRoutes.lespay),
    'orders': AgentLink('Order History', MainRoutes.orderHistory),
    'transactions': AgentLink('Transactions', MainRoutes.transactions),
    'offers': AgentLink('See offers', MainRoutes.offers),
    'missions': AgentLink('See missions', MainRoutes.missions),
    'support': AgentLink('Support tickets', MainRoutes.supportTickets),
  };

  Map<String, Object?> suggestOpenScreen(String screen) {
    final link = _screens[screen];
    if (link == null) return {'error': 'Unknown screen.'};
    if (!_links.any((l) => l.route == link.route)) _links.add(link);
    return {
      'ok': true,
      'note': 'A button to open it was shown to the customer.',
    };
  }

  void addLinks(Iterable<String> screens) {
    for (final s in screens) {
      suggestOpenScreen(s);
    }
  }

  /// Dispatches a model tool call.
  Future<Map<String, Object?>> execute(
    String name,
    Map<String, Object?> args,
  ) async {
    try {
      switch (name) {
        case 'get_orders':
          return await getOrders(
            filter: (args['filter'] as String?) ?? 'recent',
            limit: (args['limit'] as num?)?.toInt() ?? 5,
          );
        case 'get_wallet_balance':
          return await getWalletBalance();
        case 'request_cancel_order':
          return requestCancelOrder(
            '${args['order_ref'] ?? ''}',
            reason: args['reason'] as String?,
          );
        case 'request_reorder':
          return requestReorder('${args['order_ref'] ?? ''}');
        case 'suggest_open_screen':
          return suggestOpenScreen('${args['screen'] ?? ''}');
      }
      return {'error': 'Unknown tool.'};
    } catch (e) {
      return {
        'error': ApiErrorMapper.message(
          e,
          fallbackEn: 'Could not complete that.',
        ),
      };
    }
  }

  // ---- actions ------------------------------------------------------------

  AgentAction cancelActionFor(String ref) => _cancelAction(_byRef[ref]!, null);
  AgentAction reorderActionFor(String ref) => _reorderAction(_byRef[ref]!);

  AgentAction _cancelAction(OrderDto order, String? reason) {
    final service = OrderServiceLabels.labelForOrder(order);
    final total = Money.format(order.effectiveTotalAmount);
    return AgentAction(
      id: 'cancel-${order.id}',
      kind: AgentActionKind.cancelOrder,
      label: 'Yes, cancel it',
      detail: 'Cancel your $service order • $total?',
      run: () async {
        final res = await _orders.cancelOrder(
          order.id,
          (reason == null || reason.trim().isEmpty)
              ? 'Cancelled by customer via IBOW'
              : reason.trim(),
        );
        if (!res.success) throw Exception('Cancel failed');
        return 'Done. Your $service order was cancelled.';
      },
    );
  }

  AgentAction _reorderAction(OrderDto order) {
    final service = OrderServiceLabels.labelForOrder(order);
    final total = Money.format(order.effectiveTotalAmount);
    final first = order.effectiveItems.isNotEmpty
        ? order.effectiveItems.first.name
        : null;
    return AgentAction(
      id: 'reorder-${order.id}',
      kind: AgentActionKind.reorder,
      label: 'Order again',
      detail:
          '${first != null ? '$first • ' : ''}$service • $total will be placed again.',
      run: () async {
        final res = await _orders.reorderOrder(order.id);
        if (!res.success) throw Exception('Reorder failed');
        return 'Placed! Your $service order is on its way to being confirmed.';
      },
    );
  }

  // ---- model tool declarations -------------------------------------------

  static List<Tool> get declarations => [
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'get_orders',
          "Look up the signed-in customer's orders. Use this for any question about an order's status, items, total, driver or history.",
          Schema.object(
            properties: {
              'filter': Schema.enumString(
                enumValues: ['active', 'recent', 'completed'],
                description:
                    'active = still in progress; recent = newest first; completed = delivered.',
              ),
              'limit': Schema.integer(
                description: 'How many orders, 1 to 10. Default 5.',
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'get_wallet_balance',
          "Get the customer's LesPay wallet balance in pesos.",
          Schema.object(properties: {}),
        ),
        FunctionDeclaration(
          'request_cancel_order',
          'Offer to cancel an active order. Shows the customer a Cancel button; the order is only cancelled if they tap it. Call get_orders first to get the order_ref.',
          Schema.object(
            properties: {
              'order_ref': Schema.string(
                description: 'The ref from get_orders, like "o1".',
              ),
              'reason': Schema.string(
                description: "The customer's reason, if they gave one.",
              ),
            },
            requiredProperties: ['order_ref'],
          ),
        ),
        FunctionDeclaration(
          'request_reorder',
          'Offer to place a completed order again. Shows an Order again button; nothing is placed unless the customer taps it. Call get_orders first.',
          Schema.object(
            properties: {
              'order_ref': Schema.string(
                description: 'The ref from get_orders, like "o2".',
              ),
            },
            requiredProperties: ['order_ref'],
          ),
        ),
        FunctionDeclaration(
          'suggest_open_screen',
          'Show a button that opens a screen. Use it to help the customer start a new booking (ride, delivery, food, shop, transport) or reach wallet, orders, offers, missions or support.',
          Schema.object(
            properties: {
              'screen': Schema.enumString(
                enumValues: _screens.keys.toList(),
                description: 'Which screen to offer.',
              ),
            },
            requiredProperties: ['screen'],
          ),
        ),
      ],
    ),
  ];
}

/// Understands the common requests without any cloud model, using the same
/// tools. This is what keeps IBOW useful when the AI key is missing or
/// rate limited, and it makes the actions fully predictable.
class ChatAgent {
  ChatAgent([ChatAgentTools? tools]) : tools = tools ?? ChatAgentTools();

  final ChatAgentTools tools;

  static const _namedServices = {
    'lesride': 'ride',
    'lesgo': 'delivery',
    'leseat': 'food',
    'lesbuy': 'shop',
    'lestransport': 'transport',
    'lesport': 'transport',
  };

  static String? _namedService(String text) {
    for (final entry in _namedServices.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static bool _has(String t, List<String> words) => words.any(t.contains);

  /// Returns null when the message isn't one of the things the agent handles.
  Future<AgentReply?> handle(String message) async {
    final t = message.toLowerCase().trim();
    try {
      if (_has(t, ['cancel', 'kansel', 'ikansela'])) return await _cancel();
      if (_has(t, [
        'order again',
        'reorder',
        're-order',
        'repeat my order',
        'same order',
        'ulitin',
        'order ulit',
      ])) {
        return await _reorder(_namedService(t));
      }
      if (_has(t, [
        'balance',
        'how much is in my',
        'magkano ang lespay',
        'magkano ang wallet',
        'ilan ang lespay',
      ])) {
        return await _balance();
      }
      if (RegExp(r'\bbook\b').hasMatch(t) ||
          _has(t, [
            'pa-book',
            'magpa-book',
            'place an order',
            'place a new order',
            'place my order',
            'start an order',
            'order food',
            'i want to order',
            'gusto kong mag-order',
            'need a ride',
            'pa-deliver',
            'padala',
            'sakay',
          ])) {
        return _book(t);
      }
      if (_has(t, [
        'where is my order',
        'where is my',
        'track',
        'order status',
        'status of my',
        'saan na',
        'nasaan na',
        'my order',
      ])) {
        return await _track();
      }
      if (_has(t, [
        'recent orders',
        'last order',
        'previous order',
        'order history',
        'past orders',
      ])) {
        return await _recent();
      }
      if (_has(t, ['voucher', 'promo', 'discount', 'offers', 'mission'])) {
        tools.addLinks(['offers', 'missions']);
        final fx = tools.takeSideEffects();
        return AgentReply(
          'Here are your offers and missions. Check each one for eligibility and expiry.',
          mood: IbowExpression.happy,
          links: fx.links,
        );
      }
    } catch (e) {
      return const AgentReply(
        "Sorry, I couldn't reach your orders right now. Please try again in a moment.",
        mood: IbowExpression.sad,
      );
    }
    return null;
  }

  Future<AgentReply> _track() async {
    final all = await tools.loadOrders();
    final active = all.where((e) => ChatAgentTools.isActive(e.value)).toList();
    if (active.isEmpty) {
      final last = all.isEmpty ? null : all.first;
      final tail = last == null
          ? ''
          : ' Your latest order (${OrderServiceLabels.labelForOrder(last.value)}, ${Money.format(last.value.effectiveTotalAmount)}) is ${OrderProgress.of(service: OrderServiceLabels.labelForOrder(last.value), status: last.value.status).headline.toLowerCase()}.';
      tools.addLinks(['orders']);
      return AgentReply(
        "You don't have any active orders right now.$tail",
        mood: IbowExpression.neutral,
        links: tools.takeSideEffects().links,
      );
    }
    final lines = <String>[];
    for (final e in active.take(3)) {
      final s = tools.summarize(e.key, e.value);
      final driver = s['driver_first_name'] != null
          ? ' Driver: ${s['driver_first_name']}.'
          : '';
      lines.add('• ${s['service']}: ${s['status_text']}.$driver');
    }
    final more = active.length > 3
        ? '\n+${active.length - 3} more active.'
        : '';
    return AgentReply(
      '${active.length == 1 ? 'Here is your active order' : 'Here are your active orders'}:\n${lines.join('\n')}$more',
      mood: IbowExpression.happy,
      links: [const AgentLink('Order History', MainRoutes.orderHistory)],
    );
  }

  Future<AgentReply> _recent() async {
    final all = await tools.loadOrders();
    if (all.isEmpty) {
      tools.addLinks(['ride', 'food']);
      return AgentReply(
        "You haven't placed any orders yet. Want to start one?",
        links: tools.takeSideEffects().links,
      );
    }
    final lines = <String>[];
    for (final e in all.take(3)) {
      final s = tools.summarize(e.key, e.value);
      lines.add(
        '• ${s['service']} ${s['date'] ?? ''}: ${Money.format(e.value.effectiveTotalAmount)}, ${s['status_text']}',
      );
    }
    return AgentReply(
      'Your latest orders:\n${lines.join('\n')}',
      links: [const AgentLink('Order History', MainRoutes.orderHistory)],
    );
  }

  Future<AgentReply> _cancel() async {
    final all = await tools.loadOrders();
    final cancellable = all
        .where(
          (e) =>
              ChatAgentTools.isActive(e.value) &&
              canCustomerCancelOrderStatus(e.value.status),
        )
        .toList();
    if (cancellable.isEmpty) {
      return const AgentReply(
        "You don't have an order that can be cancelled right now.",
        mood: IbowExpression.sad,
      );
    }
    final actions = [
      for (final e in cancellable.take(3)) tools.cancelActionFor(e.key),
    ];
    return AgentReply(
      actions.length == 1
          ? 'I can cancel this one for you. Tap the button to confirm.'
          : 'Which order should I cancel? Tap the one you mean.',
      mood: IbowExpression.surprised,
      actions: actions,
    );
  }

  Future<AgentReply> _reorder(String? service) async {
    final all = await tools.loadOrders();
    for (final entry in all) {
      final order = entry.value;
      if (!ChatAgentTools.isCompleted(order)) continue;
      final name = OrderServiceLabels.labelForOrder(order);
      if (service != null && _namedServices[name.toLowerCase()] != service) {
        continue;
      }
      return AgentReply(
        'Want the same $name order again? Tap the button to place it.',
        mood: IbowExpression.happy,
        actions: [tools.reorderActionFor(entry.key)],
      );
    }

    if (service != null) tools.addLinks([service]);
    return AgentReply(
      "I couldn't find a completed order to repeat yet.",
      mood: IbowExpression.sad,
      links: tools.takeSideEffects().links,
    );
  }

  Future<AgentReply> _balance() async {
    final b = await tools.getWalletBalance();
    final amount = Money.format((b['balance_php'] as num).toDouble());
    tools.addLinks(['wallet']);
    return AgentReply(
      'Your LesPay balance is $amount.',
      mood: IbowExpression.happy,
      links: tools.takeSideEffects().links,
    );
  }

  AgentReply _book(String t) {
    final named = _namedService(t);
    final screens = [
      if (named != null)
        named
      else ...[
        if (_has(t, ['ride', 'tricycle', 'angkas', 'sakay', 'habal'])) 'ride',
        if (_has(t, ['food', 'pagkain', 'restaurant', 'meal'])) 'food',
        if (_has(t, ['grocery', 'shopping', 'bili', 'store'])) 'shop',
        if (_has(t, ['cargo', 'truck', 'lipat']))
          'transport'
        else if (_has(t, ['parcel', 'deliver', 'padala', 'package']))
          'delivery',
      ],
    ];
    tools.addLinks(
      screens.isEmpty
          ? ['ride', 'delivery', 'food', 'shop', 'transport']
          : screens,
    );
    return AgentReply(
      'Choose a service below to enter your order details. You can review the price and payment before placing the order.',
      mood: IbowExpression.happy,
      links: tools.takeSideEffects().links,
    );
  }
}
