import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/data_source/dto/chat/chat_dto.dart';
import '../../provider/chat/chat_provider.dart';

class RiderChatScreen extends ConsumerStatefulWidget {
  final int orderId;
  final String? customerName;

  const RiderChatScreen({
    super.key,
    required this.orderId,
    this.customerName,
  });

  @override
  ConsumerState<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends ConsumerState<RiderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Stop polling without using ref (which is invalid after dispose)
    // The provider will be disposed by Riverpod automatically
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    _isInitialized = true;
    final notifier = ref.read(chatProviderFamily(widget.orderId).notifier);
    await notifier.getOrCreateConversation(widget.orderId);
    await notifier.markAsRead();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // With reverse: true, the bottom is actually 0.0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final success = await ref
        .read(chatProviderFamily(widget.orderId).notifier)
        .sendMessage(text);

    if (success) {
      _scrollToBottom();
    } else {
      _messageController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProviderFamily(widget.orderId));

    // Auto-scroll when new messages arrive
    ref.listen(chatProviderFamily(widget.orderId), (prev, next) {
      if (prev != null && next.messages.length > prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName ?? 'Customer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Order #${widget.orderId}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF5F2D82)),
            onSelected: (value) async {
              if (value != 'end') return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('End chat?'),
                  content: const Text(
                    'This will close the conversation with the customer. You can still view past messages in Inbox.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('End chat'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              final ok = await ref
                  .read(chatProviderFamily(widget.orderId).notifier)
                  .endConversation();
              if (!context.mounted) return;
              if (ok) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not end conversation.'),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'end',
                child: Text('End conversation'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5F2D82)),
            onPressed: () => ref
                .read(chatProviderFamily(widget.orderId).notifier)
                .loadMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          if (chatState.isLoading && chatState.messages.isEmpty)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Color(0xFF5F2D82),
            ),

          // Error banner
          if (chatState.error != null && chatState.messages.isEmpty)
            Container(
              width: double.infinity,
              color: Colors.red[50],
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _initializeChat,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: chatState.messages.isEmpty && !chatState.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello to your customer!',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      final isMe = msg.senderType == 'driver';
                      return _MessageBubble(message: msg, isMe: isMe);
                    },
                  ),
          ),

          // Input bar
          _buildInputBar(chatState.isSending),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isSending) {
    final conversation = ref.watch(chatProviderFamily(widget.orderId)).currentConversation;
    final isActive = conversation?.status == 'active' || conversation == null;

    if (!isActive) {
      return Container(
        width: double.infinity,
        color: Colors.grey.shade200,
        padding: const EdgeInsets.all(16),
        child: const Text(
          'This conversation has ended.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isSending,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                onChanged: (_) => ref
                    .read(chatProviderFamily(widget.orderId).notifier)
                    .notifyTyping(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isSending ? null : _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSending
                      ? Colors.grey[300]
                      : const Color(0xFF5F2D82),
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageDto message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                (message.sender?.name.isNotEmpty == true)
                    ? message.sender!.name[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF5F2D82) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && message.sender?.name != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender!.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
