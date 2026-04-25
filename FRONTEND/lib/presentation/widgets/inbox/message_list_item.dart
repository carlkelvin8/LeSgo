import 'package:flutter/material.dart';
import '../../../domain/entities/inbox/message.dart';

class MessageListItem extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const MessageListItem({
    super.key,
    required this.message,
    required this.onTap,
  });

  String _getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(message.timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[message.timestamp.month - 1]} ${message.timestamp.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = message.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: hasUnread ? Colors.purple.withValues(alpha: 0.05) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF7B3FF2),
              child: Text(
                message.senderName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message.senderName,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    
                      Text(
                        _getFormattedTime(),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: hasUnread ? const Color(0xFF7B3FF2) : Colors.grey[600],
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.messagePreview,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 14,
                            color: hasUnread ? Colors.black87 : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B3FF2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${message.unreadCount}',
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
