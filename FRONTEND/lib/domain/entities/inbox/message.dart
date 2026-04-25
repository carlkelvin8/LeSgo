class Message {
  final String id;
  final String senderName;
  final String avatarUrl;
  final String messagePreview;
  final DateTime timestamp;
  final int unreadCount;

  Message({
    required this.id,
    required this.senderName,
    required this.avatarUrl,
    required this.messagePreview,
    required this.timestamp,
    required this.unreadCount,
  });
}
