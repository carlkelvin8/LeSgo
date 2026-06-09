import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/support/customer_service_chat_provider.dart';
import '../../../widgets/support/customer_service_message_bubble.dart';

class CustomerServiceChatScreen extends ConsumerStatefulWidget {
  const CustomerServiceChatScreen({super.key});

  @override
  ConsumerState<CustomerServiceChatScreen> createState() =>
      _CustomerServiceChatScreenState();
}

class _CustomerServiceChatScreenState
    extends ConsumerState<CustomerServiceChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(customerServiceChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(customerServiceChatProvider);
    ref.listen(customerServiceChatProvider, (previous, next) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.support_agent, color: Colors.white),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 10)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LeSGo Assistant',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  chatState.isConfigured ? 'AI Customer Service' : 'Setup required',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'human':
                  AppRouter.push(context, MainRoutes.supportTickets);
                  break;
                case 'clear':
                  ref.read(customerServiceChatProvider.notifier).clearChat();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'human',
                child: Text('Talk to human support'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!chatState.isConfigured)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8E1),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
              child: Text(
                'Add GEMINI_API_KEY to secrets.json and restart the app to enable AI replies.',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.orange.shade900,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 12),
              ),
              itemCount:
                  chatState.messages.length + (chatState.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= chatState.messages.length) {
                  return _typingIndicator(context);
                }
                return CustomerServiceMessageBubble(
                  message: chatState.messages[index],
                );
              },
            ),
          ),
          if (chatState.error != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.spacing(context, 16),
                vertical: ResponsiveUtils.spacing(context, 4),
              ),
              child: Text(
                chatState.error!,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.red.shade700,
                ),
              ),
            ),
          _inputBar(context, chatState.isSending),
        ],
      ),
    );
  }

  Widget _typingIndicator(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE8D9F5),
            child: const Icon(
              Icons.support_agent,
              size: 16,
              color: Color(0xFF5F2D82),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 14),
              vertical: ResponsiveUtils.spacing(context, 10),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: ResponsiveUtils.spacing(context, 20),
              height: ResponsiveUtils.spacing(context, 20),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(BuildContext context, bool isSending) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtils.spacing(context, 12),
          ResponsiveUtils.spacing(context, 8),
          ResponsiveUtils.spacing(context, 12),
          ResponsiveUtils.spacing(context, 12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !isSending,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'LeSGo app help: orders, LesPay, vouchers...',
                  hintStyle: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: Colors.grey.shade500,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 16),
                    vertical: ResponsiveUtils.spacing(context, 10),
                  ),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            Material(
              color: const Color(0xFF5F2D82),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: isSending ? null : _send,
                child: SizedBox(
                  width: ResponsiveUtils.spacing(context, 48),
                  height: ResponsiveUtils.spacing(context, 48),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: ResponsiveUtils.fontSize(context, 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
