import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/push_notification_service.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../screens/chat/rider_chat_screen.dart';
import '../../../../../data/data_source/chat_remote_datasource.dart';
import '../../../../../data/data_source/dto/chat/chat_dto.dart';

class RiderInboxView extends ConsumerStatefulWidget {
  const RiderInboxView({super.key});

  @override
  ConsumerState<RiderInboxView> createState() => _RiderInboxViewState();
}

class _RiderInboxViewState extends ConsumerState<RiderInboxView> {
  List<ConversationDto> _conversations = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;
  final Map<int, String> _lastMessageByConversation = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Poll every 10 seconds for new conversations/messages
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadConversations(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final dataSource = ChatRemoteDataSource(DioClient());
      final conversations = await dataSource.getConversations();
      if (mounted) {
        for (final conv in conversations) {
          final latest = conv.latestMessage?.content ?? '';
          final previous = _lastMessageByConversation[conv.id];
          if (previous != null &&
              previous != latest &&
              latest.isNotEmpty &&
              silent) {
            PushNotificationService.show(
              title: conv.customer?.name ?? 'New message',
              body: latest,
              payload: 'chat_${conv.id}',
              channelId: 'lezgo_chat',
              channelName: 'Chat Messages',
            );
          }
          _lastMessageByConversation[conv.id] = latest;
        }
        setState(() {
          _conversations = conversations;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _loadConversations(),
      color: const Color(0xFF5F2D82),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
      );
    }

    if (_error != null) {
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
              onPressed: _loadConversations,
              child: const Text('Retry', style: TextStyle(color: Color(0xFF5F2D82))),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chat with customers will appear here\nonce you accept an order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final conv = _conversations[index];
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

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF5F2D82).withOpacity(0.1),
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
          Expanded(
            child: Text(
              customerName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
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
                    ? const Color(0xFF5F2D82).withOpacity(0.1)
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
    );
  }
}
