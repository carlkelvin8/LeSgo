import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../provider/chat/chat_provider.dart';
import 'chat_bubble_widget.dart';
import 'chat_input_widget.dart';

class OrderChatWidget extends ConsumerStatefulWidget {
  final int orderId;
  final String orderType; // 'leseat', 'lesgo', 'lesbuy'
  final bool showHeader;
  final double? height;

  const OrderChatWidget({
    super.key,
    required this.orderId,
    required this.orderType,
    this.showHeader = true,
    this.height,
  });

  @override
  ConsumerState<OrderChatWidget> createState() => _OrderChatWidgetState();
}

class _OrderChatWidgetState extends ConsumerState<OrderChatWidget> {
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (_isInitialized) return;
    
    final chatNotifier = ref.read(chatProvider(widget.orderId).notifier);
    await chatNotifier.getOrCreateConversation(widget.orderId);
    _isInitialized = true;
    
    // Scroll to bottom after messages load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    // With reverse: true, the bottom is actually 0.0
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    final chatState = ref.read(chatProvider(widget.orderId));
    
    // If conversation not loaded yet, try to initialize first
    if (chatState.currentConversation == null) {
      await _initializeChat();
    }
    
    final chatNotifier = ref.read(chatProvider(widget.orderId).notifier);
    final success = await chatNotifier.sendMessage(message);
    
    if (success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to send message');
      }
    }
  }

  void _onLocationTap(Map<String, dynamic>? metadata) {
    if (metadata == null) return;
    try {
      final lat = metadata['latitude'];
      final lng = metadata['longitude'];
      if (lat != null && lng != null) {
        SnackBarUtils.showInfo(context, 'Location: $lat, $lng');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Invalid location data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.orderId));
    
    return Container(
      height: widget.height ?? MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.showHeader 
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : null,
        boxShadow: widget.showHeader ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Header
          if (widget.showHeader) _buildHeader(context),
          
          // Messages list
          Expanded(
            child: _buildMessagesList(chatState),
          ),
          
          // Input — always allow typing; send is blocked internally if no conversation
          ChatInputWidget(
            onSendMessage: _sendMessage,
            isLoading: chatState.isSending,
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          
          // Title
          Text(
            'Chat with Driver',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 16),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          
          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.isLoading && chatState.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
        ),
      );
    }

    if (chatState.messages.isEmpty) {
      return Center(
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
              'Start a conversation',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              'Send a message to your driver',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 16),
      ),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        // Assume current user is customer (you can get this from auth state)
        final isCurrentUser = message.senderType == 'customer';
        
        return ChatBubbleWidget(
          message: message,
          isCurrentUser: isCurrentUser,
          onLocationTap: () => _onLocationTap(message.metadata),
        );
      },
    );
  }
}