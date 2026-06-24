import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_customer_service_chat_provider.dart';

class RiderCustomerServiceChatScreen extends ConsumerStatefulWidget {
  const RiderCustomerServiceChatScreen({super.key});

  @override
  ConsumerState<RiderCustomerServiceChatScreen> createState() =>
      _RiderCustomerServiceChatScreenState();
}

class _RiderCustomerServiceChatScreenState
    extends ConsumerState<RiderCustomerServiceChatScreen> {
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
    await ref.read(riderCustomerServiceChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final chatState = ref.watch(riderCustomerServiceChatProvider);
    ref.listen(riderCustomerServiceChatProvider, (_, __) => _scrollToBottom());

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
                  'LeSGo Partner Assistant',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  chatState.isConfigured ? 'AI Support' : 'Setup required',
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
                  AppRouter.push(context, MainRoutes.riderSupportTickets);
                  break;
                case 'clear':
                  ref.read(riderCustomerServiceChatProvider.notifier).clearChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'human',
                child: Text(AppLocalization.translate('talk_to_human_support', lang)),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text(AppLocalization.translate('clear_chat', lang)),
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
                horizontal: ResponsiveUtils.spacing(context, 16),
              ),
              itemCount:
                  chatState.messages.length + (chatState.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= chatState.messages.length) {
                  return _typingIndicator(context);
                }
                final msg = chatState.messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                chatState.error!,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          _inputBar(chatState.isSending),
        ],
      ),
    );
  }

  Widget _typingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE8D9F5),
            child: Icon(Icons.support_agent, size: 16, color: Color(0xFF5F2D82)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(bool isSending) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                  hintText: 'Orders, earnings, LesPay, documents...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Color(0xFF5F2D82)),
              ),
              onPressed: isSending ? null : _send,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CustomerServiceMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF5F2D82) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
