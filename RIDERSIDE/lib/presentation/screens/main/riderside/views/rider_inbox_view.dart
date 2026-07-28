import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/routers/app_router.dart';
import '../../../../../core/constants/routers/main/main_routes.dart';
import '../../../../provider/main/riderside/rider_inbox_provider.dart';
import '../../../../provider/main/riderside/rider_inbox_refresh_provider.dart';
import '../../../../screens/chat/rider_chat_screen.dart';
import '../../../../../data/data_source/dto/chat/chat_dto.dart';

class RiderInboxView extends ConsumerStatefulWidget {
  const RiderInboxView({super.key});

  @override
  ConsumerState<RiderInboxView> createState() => _RiderInboxViewState();
}

class _RiderInboxViewState extends ConsumerState<RiderInboxView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderInboxProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(riderInboxProvider);

    ref.listen<int>(riderInboxRefreshSignalProvider, (previous, next) {
      if (previous == next) return;
      ref.read(riderInboxProvider.notifier).loadConversations(silent: true);
    });

    return RefreshIndicator(
      onRefresh: () => ref.read(riderInboxProvider.notifier).loadConversations(),
      color: const Color(0xFF5F2D82),
      child: _buildBody(inboxState),
    );
  }

  void _openChat(ConversationDto conversation) {
    final orderId = conversation.orderId ?? 0;
    final customerName = conversation.customer?.name ?? 'Customer';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderChatScreen(
          orderId: orderId,
          customerName: customerName,
        ),
      ),
    ).then((_) {
      if (mounted) {
        ref.read(riderInboxProvider.notifier).loadConversations(silent: true);
      }
    });
  }

  Widget _buildBody(RiderInboxState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
      );
    }

    if (state.error != null && state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Could not load messages',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.read(riderInboxProvider.notifier).loadConversations(),
              child: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFF5F2D82)),
              ),
            ),
          ],
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return ListView(
        children: [
          _AdminSupportTile(
            onTap: () => AppRouter.push(context, MainRoutes.riderCustomerServiceChat),
          ),
          const Divider(height: 1, indent: 72),
          const SizedBox(height: 80),
          const Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chat with customers will appear here\nonce you accept an order.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.conversations.length + 1, // +1 for admin support
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        // First item: Admin Support Chat (pinned)
        if (index == 0) {
          return _AdminSupportTile(
            onTap: () => AppRouter.push(context, MainRoutes.riderCustomerServiceChat),
          );
        }
        final conv = state.conversations[index - 1];
        return _ConversationTile(
          conversation: conv,
          onTap: () => _openChat(conv),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationDto conversation;
  final VoidCallback onTap;

  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final customerName = conversation.customer?.name ?? 'Customer';
    final lastMsg = conversation.latestMessage?.content ?? 'No messages yet';
    final orderId = conversation.orderId;
    final isActive = conversation.status == 'active';
    final latest = conversation.latestMessage;
    final hasUnreadFromCustomer = latest != null &&
        latest.readAt == null &&
        latest.senderType.toLowerCase() == 'customer';

    return Semantics(
      button: true,
      label: 'Chat with $customerName. $lastMsg',
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
          child: Text(
            customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5F2D82),
            ),
          ),
        ),
        title: Row(
          children: [
            if (hasUnreadFromCustomer)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF5F2D82),
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                customerName,
                style: TextStyle(
                  fontWeight: hasUnreadFromCustomer
                      ? FontWeight.w800
                      : FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (orderId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF5F2D82).withValues(alpha: 0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Order #$orderId',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? const Color(0xFF5F2D82) : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          lastMsg,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.green : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'Active' : 'Ended',
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.green : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _AdminSupportTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AdminSupportTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.15),
        child: const Icon(
          Icons.support_agent,
          color: Color(0xFF5F2D82),
          size: 24,
        ),
      ),
      title: const Text(
        'Admin Support',
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF5F2D82),
        ),
      ),
      subtitle: const Text(
        'Chat with LeSGo admin support',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF5F2D82),
      ),
    );
  }
}
