import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../provider/chat/chat_provider.dart';
import '../../widgets/widgets.dart';
import '../../widgets/chat/order_chat_widget.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/order_service_labels.dart';
import '../../../data/data_source/dto/chat/message_dto.dart';

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

  void _openConversation(ConversationDto conversation, {String? driverName}) {
    final orderType = conversation.serviceType ??
        conversation.serviceName ??
        OrderServiceLabels.fromServiceId(conversation.serviceId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderChatWidget(
        orderId: conversation.orderId,
        orderType: orderType,
        driverName: driverName,
      ),
    );
  }

  String _formatMessageTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return 'Now';
    }
  }

  String _getOrderDisplayName(ConversationDto conversation) {
    return OrderServiceLabels.conversationTitle(
      serviceName: conversation.serviceName,
      serviceId: conversation.serviceId,
      serviceType: conversation.serviceType ??
          conversation.order?['service_type']?.toString(),
      orderId: conversation.orderId,
    );
  }

  IconData _getOrderIcon(ConversationDto conversation) {
    final label = conversation.serviceName ??
        OrderServiceLabels.fromServiceType(conversation.serviceType ??
            OrderServiceLabels.fromServiceId(conversation.serviceId));

    switch (label.toLowerCase()) {
      case 'lesride':
        return Icons.directions_car;
      case 'leseat':
        return Icons.restaurant;
      case 'lesbuy':
        return Icons.shopping_bag;
      case 'lestransport':
        return Icons.airport_shuttle;
      case 'lesgo':
      default:
        return Icons.local_shipping;
    }
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
            Expanded(
              child: chatState.isLoading && conversations.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
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
                              SizedBox(
                                  height:
                                      ResponsiveUtils.spacing(context, 16)),
                              Text(
                                'No conversations yet',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 16),
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(
                                  height: ResponsiveUtils.spacing(context, 8)),
                              Text(
                                'Start chatting with your drivers',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 14),
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(chatProviderGlobal.notifier)
                              .loadConversations(),
                          color: const Color(0xFF5F2D82),
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              vertical: ResponsiveUtils.spacing(context, 8),
                            ),
                            itemCount: conversations.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final conversation = conversations[index];
                              return _buildConversationItem(
                                  context, conversation);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(
      BuildContext context, ConversationDto conversation) {
    final lastMessage = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;
    final orderName = _getOrderDisplayName(conversation);
    final driverName = conversation.driver?.name;
    final displayTitle =
        driverName != null ? 'Chat with $driverName' : orderName;

    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openConversation(
          conversation,
          driverName: driverName,
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        const Color(0xFF5F2D82).withOpacity(0.1),
                    child: driverName != null
                        ? Text(
                            driverName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5F2D82),
                            ),
                          )
                        : Icon(
                            _getOrderIcon(conversation),
                            color: const Color(0xFF5F2D82),
                            size: 28,
                          ),
                  ),
                  if (hasUnread)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              Expanded(
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
                                displayTitle,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 16),
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                              if (driverName != null)
                                Text(
                                  orderName,
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize:
                                        ResponsiveUtils.fontSize(context, 12),
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (lastMessage != null)
                          Text(
                            _formatMessageTime(lastMessage.createdAt),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 12),
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
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 14),
                              color: hasUnread
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
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
