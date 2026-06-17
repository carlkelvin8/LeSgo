import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_chat_provider.dart';
import '../../../../domain/entities/rider_booking.dart';

class RiderChatScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String customerName;

  const RiderChatScreen({
    super.key,
    required this.orderId,
    required this.customerName,
  });

  @override
  ConsumerState<RiderChatScreen> createState() => _RiderChatScreenState();
}

class _RiderChatScreenState extends ConsumerState<RiderChatScreen> {
  late TextEditingController _messageController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _showQuickReplies = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    // Load messages on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderChatProvider(widget.orderId).notifier).loadMessages();
      ref.read(riderChatProvider(widget.orderId).notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await ref.read(riderChatProvider(widget.orderId).notifier).sendImage(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _pickAndSendDeliveryProof() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await ref.read(riderChatProvider(widget.orderId).notifier).sendDeliveryProof(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(riderChatProvider(widget.orderId));
    final quickReplies = ref.watch(quickRepliesProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5F2D82),
              ),
            ),
            Text(
              'Order #${widget.orderId.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 11),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: chatState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF5F2D82)),
                    ),
                  )
                : chatState.messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(riderChatProvider(widget.orderId).notifier)
                            .refreshMessages(),
                        child: ListView.builder(
                          reverse: true,
                          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatState.messages[index];
                            return _buildMessageBubble(context, message);
                          },
                        ),
                      ),
          ),

          // Quick Replies Toggle
          if (quickReplies.when(
            data: (replies) => replies.isNotEmpty,
            loading: () => false,
            error: (_, __) => false,
          ))
            Container(
              padding: EdgeInsets.symmetric(horizontal: hp, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Icon(
                    Icons.bolt,
                    size: 16,
                    color: const Color(0xFFFF9800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick replies',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showQuickReplies ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _showQuickReplies = !_showQuickReplies),
                  ),
                ],
              ),
            ),

          // Quick Replies Display
          if (_showQuickReplies)
            quickReplies.when(
              data: (replies) => Container(
                color: Colors.white,
                padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: replies
                        .map((reply) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ActionChip(
                                onPressed: () async {
                                  await ref
                                      .read(
                                          riderChatProvider(widget.orderId).notifier)
                                      .sendQuickReply(reply.text);
                                  setState(() => _showQuickReplies = false);
                                },
                                backgroundColor: const Color(0xFF5F2D82).withOpacity(0.1),
                                label: Text(
                                  reply.text,
                                  style: TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize:
                                        ResponsiveUtils.fontSize(context, 11),
                                    color: const Color(0xFF5F2D82),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Input Area
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F2D82),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () async {
                          final text = _messageController.text;
                          if (text.isNotEmpty) {
                            _messageController.clear();
                            await ref
                                .read(riderChatProvider(widget.orderId).notifier)
                                .sendMessage(text);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.image,
                      label: 'Photo',
                      color: const Color(0xFF2196F3),
                      onPressed: _pickAndSendImage,
                    ),
                    _buildActionButton(
                      icon: Icons.camera_alt,
                      label: 'Proof',
                      color: const Color(0xFF4CAF50),
                      onPressed: _pickAndSendDeliveryProof,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isRider = message.isSentByRider;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isRider ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isRider)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF5F2D82).withOpacity(0.2),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Color(0xFF5F2D82),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isRider
                    ? const Color(0xFF5F2D82)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isRider
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: _buildMessageContent(context, message, isRider),
            ),
          ),
          const SizedBox(width: 8),
          if (isRider)
            _buildDeliveryStatus(context, message),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, ChatMessage message, bool isRider) {
    if (message.type == 'image') {
      return GestureDetector(
        onTap: () {
          // Show image preview
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              child: Image.network(
                message.imageUrl ?? '',
                fit: BoxFit.contain,
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Image.network(
            message.imageUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image,
              color: isRider ? Colors.white : Colors.grey,
            ),
          ),
        ),
      );
    }

    if (message.type == 'delivery_proof') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRider
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '📸 Delivery Proof',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isRider ? Colors.white : const Color(0xFF4CAF50),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  child: Image.network(
                    message.imageUrl ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Image.network(
                message.imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image,
                  color: isRider ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: isRider ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 10),
            color: isRider ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryStatus(BuildContext context, ChatMessage message) {
    if (!message.isSentByRider) return const SizedBox.shrink();

    if (message.isSending) {
      return Icon(Icons.schedule, size: 16, color: Colors.grey.shade400);
    }

    if (message.isFailed) {
      return Icon(Icons.error_outline, size: 16, color: Colors.red.shade300);
    }

    if (message.isRead) {
      return Icon(Icons.done_all, size: 16, color: Colors.blue.shade300);
    }

    return Icon(Icons.done, size: 16, color: Colors.grey.shade400);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 10),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
