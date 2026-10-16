import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/merchant_order_alert_service.dart';
import '../../../../../data/data_source/dto/merchant/order_dto.dart';
import '../../../../provider/main/merchantside/merchant_menu_image_lookup.dart';
import '../../../../provider/main/merchantside/merchant_orders_provider.dart';
import '../../../../provider/main/merchantside/merchant_prep_timer_provider.dart';
import '../../../../widgets/main/merchantside/orders/merchant_order_action_handlers.dart';
import '../../../../widgets/main/merchantside/orders/merchant_order_dialogs.dart';
import '../../../../widgets/main/merchantside/orders/merchant_order_queue_card.dart';
import '../merchant_order_detail_screen.dart';

enum _QueueSort { attention, newest, oldest }

class MerchantOrdersView extends ConsumerStatefulWidget {
  const MerchantOrdersView({super.key});
  @override
  ConsumerState<MerchantOrdersView> createState() => _MerchantOrdersViewState();
}

class _MerchantOrdersViewState extends ConsumerState<MerchantOrdersView> {
  final _search = TextEditingController();
  final _busy = <int>{};
  _QueueSort _sort = _QueueSort.attention;

  @override
  void initState() {
    super.initState();
    // Stop persistent notification sound when merchant views orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MerchantOrderAlertService.acknowledgeOrderAlert();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      ref.invalidate(merchantOrdersProvider);
      await ref.read(merchantOrdersProvider.future);
    } catch (_) {
      /* The error state below provides retry. */
    }
  }

  void _select(MerchantOrderFilter filter) {
    HapticFeedback.selectionClick();
    ref.read(selectedMerchantOrderFilterProvider.notifier).state = filter;
  }

  Future<void> _act(OrderDto order, Future<void> Function() action) async {
    if (_busy.contains(order.id)) return;
    setState(() => _busy.add(order.id));
    HapticFeedback.lightImpact();
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _ready(OrderDto order) async {
    final confirmed = await showMerchantConfirmDialog(
      context,
      title: 'Ready for pickup?',
      message: 'Let the rider know this order is packed and ready.',
      confirmLabel: 'Mark ready',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(merchantOrderActionProvider).markReadyForPickup(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order ready for pickup.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update the order. Please try again.'),
          ),
        );
      }
    }
  }

  List<OrderDto> _visible(List<OrderDto> all, MerchantOrderFilter filter) {
    final query = _search.text.trim().toLowerCase();
    final result = filterMerchantOrders(all, filter)
        .where(
          (o) =>
              query.isEmpty ||
              '${o.id} ${o.referenceNumber ?? ''} ${o.user?.name ?? ''} ${o.dropoffAddress} ${o.orderItems?.map((i) => i.itemName).join(' ') ?? ''}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    int priority(OrderDto o) => switch (o.status.toLowerCase()) {
      'pending' => 0,
      'searching_driver' || 'accepted' => 1,
      'ready_for_pickup' => 2,
      'completed' || 'cancelled' => 4,
      _ => 3,
    };
    result.sort((a, b) {
      if (_sort == _QueueSort.attention) {
        final rank = priority(a).compareTo(priority(b));
        if (rank != 0) return rank;
      }
      return _sort == _QueueSort.oldest
          ? a.id.compareTo(b.id)
          : b.id.compareTo(a.id);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(merchantOrdersProvider);
    final all = async.valueOrNull ?? [];
    final selected = ref.watch(selectedMerchantOrderFilterProvider);
    final images = ref.watch(menuItemImageLookupProvider);
    final timers = ref.watch(merchantPrepTimerProvider);
    final visible = _visible(all, selected);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final pending = filterMerchantOrders(
      all,
      MerchantOrderFilter.pending,
    ).length;
    final preparing = filterMerchantOrders(
      all,
      MerchantOrderFilter.pickUp,
    ).length;
    final ready = filterMerchantOrders(all, MerchantOrderFilter.ready).length;
    final duration = Duration(milliseconds: reduced ? 0 : 250);

    Widget card(OrderDto order, int index) {
      final image = order.orderItems
          ?.map(images.resolve)
          .whereType<String>()
          .firstOrNull;
      return TweenAnimationBuilder<double>(
        key: ValueKey(order.id),
        tween: Tween(begin: 0, end: 1),
        duration: Duration(
          milliseconds: reduced ? 0 : 320 + (index.clamp(0, 5) * 35),
        ),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        ),
        child: MerchantOrderQueueCard(
          order: order,
          imageUrl: image,
          timer: timers[order.id],
          busy: _busy.contains(order.id),
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MerchantOrderDetailScreen(order: order),
            ),
          ),
          onAccept: () => _act(
            order,
            () => MerchantOrderActionHandlers.accept(
              context,
              ref,
              orderId: order.id,
            ),
          ),
          onReject: () => _act(
            order,
            () => MerchantOrderActionHandlers.reject(
              context,
              ref,
              orderId: order.id,
            ),
          ),
          onCancel: () => _act(
            order,
            () => MerchantOrderActionHandlers.cancelAfterAccept(
              context,
              ref,
              orderId: order.id,
            ),
          ),
          onReady: () => _act(order, () => _ready(order)),
        ),
      );
    }

    return ColoredBox(
      color: dark ? const Color(0xFF15111E) : const Color(0xFFF6F4FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 760 &&
              MediaQuery.textScalerOf(context).scale(1) < 1.6;
          final side = ((constraints.maxWidth - 1120) / 2).clamp(
            16.0,
            double.infinity,
          );
          return RefreshIndicator(
            onRefresh: _refresh,
            color: OrderQueuePalette.purple,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 24, side, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR STORE, IN MOTION',
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.7,
                                      fontWeight: FontWeight.w800,
                                      color: OrderQueuePalette.muted(context),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Orders',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                      color: OrderQueuePalette.text(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF352056), Color(0xFF6D36C8)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: OrderQueuePalette.purple.withValues(
                                  alpha: .16,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          async.hasError
                                              ? 'Let’s reconnect'
                                              : async.isLoading && all.isEmpty
                                              ? 'Getting your queue…'
                                              : pending > 0
                                              ? 'Fresh orders are in.'
                                              : 'Keep good food moving.',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            height: 1.2,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          async.hasError
                                              ? 'Refresh to see the latest orders.'
                                              : pending > 0
                                              ? '$pending ${pending == 1 ? 'order needs' : 'orders need'} your attention. Let’s get cooking.'
                                              : 'Your next great order starts here.',
                                          style: const TextStyle(
                                            color: Color(0xFFDDCEEF),
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: .12,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.room_service_outlined,
                                      color: Color(0xFFE7D7FF),
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _Metric(
                                    label: 'NEW',
                                    value:
                                        async.hasError ||
                                            (async.isLoading && all.isEmpty)
                                        ? '—'
                                        : '$pending',
                                    onTap: () =>
                                        _select(MerchantOrderFilter.pending),
                                    duration: duration,
                                  ),
                                  _Metric(
                                    label: 'PREPARING',
                                    value:
                                        async.hasError ||
                                            (async.isLoading && all.isEmpty)
                                        ? '—'
                                        : '$preparing',
                                    onTap: () =>
                                        _select(MerchantOrderFilter.pickUp),
                                    duration: duration,
                                  ),
                                  _Metric(
                                    label: 'READY',
                                    value:
                                        async.hasError ||
                                            (async.isLoading && all.isEmpty)
                                        ? '—'
                                        : '$ready',
                                    onTap: () =>
                                        _select(MerchantOrderFilter.ready),
                                    duration: duration,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 14,
                            color: OrderQueuePalette.text(context),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search order, customer or item',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 22,
                            ),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => setState(_search.clear),
                                  ),
                            filled: true,
                            fillColor: OrderQueuePalette.surface(context),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: OrderQueuePalette.purple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final filter in MerchantOrderFilter.values)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Semantics(
                                    selected: selected == filter,
                                    button: true,
                                    child: AnimatedContainer(
                                      duration: duration,
                                      curve: Curves.easeOutCubic,
                                      decoration: BoxDecoration(
                                        color: selected == filter
                                            ? OrderQueuePalette.purple
                                            : OrderQueuePalette.surface(
                                                context,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          onTap: () => _select(filter),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14,
                                            ),
                                            child: Text(
                                              '${filter == MerchantOrderFilter.pickUp
                                                  ? 'Preparing'
                                                  : filter == MerchantOrderFilter.pending
                                                  ? 'New'
                                                  : filter.label}  ${filterMerchantOrders(all, filter).length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: selected == filter
                                                    ? Colors.white
                                                    : OrderQueuePalette.muted(
                                                        context,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: duration,
                                child: Text(
                                  '${visible.length} ${visible.length == 1 ? 'order' : 'orders'}',
                                  key: ValueKey(visible.length),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: OrderQueuePalette.text(context),
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuButton<_QueueSort>(
                              tooltip: 'Sort orders',
                              initialValue: _sort,
                              onSelected: (v) => setState(() => _sort = v),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: _QueueSort.attention,
                                  child: Text('Needs attention first'),
                                ),
                                PopupMenuItem(
                                  value: _QueueSort.newest,
                                  child: Text('Newest first'),
                                ),
                                PopupMenuItem(
                                  value: _QueueSort.oldest,
                                  child: Text('Oldest first'),
                                ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sort_rounded,
                                      size: 16,
                                      color: OrderQueuePalette.muted(context),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      switch (_sort) {
                                        _QueueSort.attention =>
                                          'Needs attention',
                                        _QueueSort.newest => 'Newest first',
                                        _QueueSort.oldest => 'Oldest first',
                                      },
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: OrderQueuePalette.muted(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (async.isLoading && all.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(side, 4, side, 28),
                      child: Column(
                        children: [
                          for (var i = 0; i < 2; i++)
                            Container(
                              height: 190,
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: OrderQueuePalette.surface(context),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: 'Loading orders',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else if (async.hasError)
                  SliverToBoxAdapter(
                    child: _QueueEmpty(
                      title: 'Couldn’t load your orders',
                      message: 'Check your connection and try again.',
                      icon: Icons.wifi_off_rounded,
                      action: 'Try again',
                      onAction: _refresh,
                    ),
                  )
                else if (visible.isEmpty)
                  SliverToBoxAdapter(
                    child: _QueueEmpty(
                      title: _search.text.isNotEmpty
                          ? 'No matching orders'
                          : all.isEmpty
                          ? 'Ready for your first order'
                          : 'You’re all caught up',
                      message: _search.text.isNotEmpty
                          ? 'Try an order number, customer or menu item.'
                          : all.isEmpty
                          ? 'Incoming orders will appear here. Pull down to refresh.'
                          : 'No orders in this stage. Check another tab.',
                      icon: _search.text.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.task_alt_rounded,
                      action: _search.text.isNotEmpty
                          ? 'Clear search'
                          : 'Refresh orders',
                      onAction: _search.text.isNotEmpty
                          ? () => setState(_search.clear)
                          : _refresh,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(side, 0, side, 24),
                    sliver: SliverList.builder(
                      itemCount: wide
                          ? (visible.length / 2).ceil()
                          : visible.length,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: card(visible[index * 2], index * 2),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: index * 2 + 1 < visible.length
                                        ? card(
                                            visible[index * 2 + 1],
                                            index * 2 + 1,
                                          )
                                        : const SizedBox(),
                                  ),
                                ],
                              )
                            : card(visible[index], index),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.onTap,
    required this.duration,
  });
  final String label, value;
  final VoidCallback onTap;
  final Duration duration;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .10),
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: duration,
              child: Text(
                value,
                key: ValueKey(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE6D8F7),
                fontSize: 9,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QueueEmpty extends StatelessWidget {
  const _QueueEmpty({
    required this.title,
    required this.message,
    required this.icon,
    required this.action,
    required this.onAction,
  });
  final String title, message, action;
  final IconData icon;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 42),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OrderQueuePalette.purple.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 34, color: OrderQueuePalette.purple),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: OrderQueuePalette.text(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: OrderQueuePalette.muted(context),
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}
