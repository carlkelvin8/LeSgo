import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/responsive_utils.dart';
import 'rider_chat_screen.dart';

class RiderChatListScreen extends ConsumerWidget {
  const RiderChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 20),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '3', // Mock: replace with actual unread count
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  backgroundColor: const Color(0xFFF44336),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 8)),
        children: [
          // Mock conversation list
          ..._buildMockConversations(context, hp),
        ],
      ),
    );
  }

  List<Widget> _buildMockConversations(BuildContext context, double hp) {
    final conversations = [
      {
        'orderId': 'ORD-001',
        'customerName': 'John Doe',
        'lastMessage': 'On my way, I will be there in 5 minutes',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
        'unread': 1,
        'avatar': '🧑',
      },
      {
        'orderId': 'ORD-002',
        'customerName': 'Maria Santos',
        'lastMessage': 'Thank you for the fast delivery!',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
        'unread': 0,
        'avatar': '👩',
      },
      {
        'orderId': 'ORD-003',
        'customerName': 'Ahmed Hassan',
        'lastMessage': 'Can you wait 5 minutes?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
        'unread': 0,
        'avatar': '🧔',
      },
    ];

    return conversations.map((conv) {
      final orderId = conv['orderId'] as String;
      final customerName = conv['customerName'] as String;
      final lastMessage = conv['lastMessage'] as String;
      final timestamp = conv['timestamp'] as DateTime;
      final unread = conv['unread'] as int;
      final avatar = conv['avatar'] as String;

      return _buildConversationItem(
        context: context,
        hp: hp,
        orderId: orderId,
        customerName: customerName,
        lastMessage: lastMessage,
        timestamp: timestamp,
        unread: unread,
        avatar: avatar,
      );
    }).toList();
  }

  Widget _buildConversationItem({
    required BuildContext context,
    required double hp,
    required String orderId,
    required String customerName,
    required String lastMessage,
    required DateTime timestamp,
    required int unread,
    required String avatar,
  }) {
    final isUnread = unread > 0;
    final timeAgo = _getTimeAgo(timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => RiderChatScreen(
                orderId: orderId,
                customerName: customerName,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          margin: EdgeInsets.symmetric(
            horizontal: hp,
            vertical: ResponsiveUtils.spacing(context, 4),
          ),
          decoration: BoxDecoration(
            color: isUnread ? Colors.white : const Color(0xFFF8F9FA),
            border: isUnread
                ? Border(
                    left: BorderSide(
                      color: const Color(0xFF5F2D82),
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF5F2D82).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          customerName,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 11),
                            color: isUnread
                                ? const Color(0xFF5F2D82)
                                : Colors.grey.shade600,
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: isUnread
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              fontWeight:
                                  isUnread ? FontWeight.w500 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5F2D82),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unread.toString(),
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize:
                                    ResponsiveUtils.fontSize(context, 10),
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
