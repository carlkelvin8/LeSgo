import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../provider/chat/chat_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chat/order_chat_widget.dart';
import '../../../core/utils/responsive_utils.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProviderGlobal.notifier).loadConversations();
    });
  }

  void _openConversation(int orderId, String orderType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatWidget(
        orderId: orderId,
        orderType: orderType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProviderGlobal);
    final conversations = chatState.conversations;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: Row(
                children: [
                  const Expanded(
                    child: AuthHeader(
                      title: 'Messages',
                    ),
                  ),
                  // Unread badge
                  if (chatState.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F2D82),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${chatState.unreadCount} new',
                        style: const TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Conversations list
            Expanded(
              child: chatState.isLoading && conversations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                      ),
                    )
                  : conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                              Text(
                                'No conversations yet',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 16),
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                              Text(
                                'Start chatting with your drivers',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: ResponsiveUtils.fontSize(context, 14),
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(chatProviderGlobal.notifier).loadConversations(),
                          color: const Color(0xFF5F2D82),
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.spacing(context, 8),
                            ),
                            itemCount: conversations.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              return _buildConversationItem(context, conversation);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, conversation) {
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openConversation(
          conversation.orderId,
          'order', // You can determine this from order data
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF5F2D82).withOpacity(0.1),
                    child: const Icon(
                      Icons.directions_car,
                      color: Color(0xFF5F2D82),
                      size: 28,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order #${conversation.orderId}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (lastMessage != null)
                          Text(
                            DateFormat('HH:mm').format(lastMessage.createdAt),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage?.message ?? 'No messages yet',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: EdgeInsets.only(
                              left: ResponsiveUtils.spacing(context, 8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5F2D82),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
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
