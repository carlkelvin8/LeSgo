import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../widgets/main/riderside/profile/profile_panel.dart';
import '../../../provider/main/riderside/rider_customer_service_chat_provider.dart';

class RiderCustomerServiceChatScreen extends ConsumerStatefulWidget {
  final bool requestAdminCallbackOnOpen;

  const RiderCustomerServiceChatScreen({
    super.key,
    this.requestAdminCallbackOnOpen = false,
  });

  @override
  ConsumerState<RiderCustomerServiceChatScreen> createState() =>
      _RiderCustomerServiceChatScreenState();
}

class _RiderCustomerServiceChatScreenState
    extends ConsumerState<RiderCustomerServiceChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.requestAdminCallbackOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(riderCustomerServiceChatProvider.notifier)
            .requestAdminCallback();
      });
    }
  }

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
    final chat = ref.read(riderCustomerServiceChatProvider);
    if (text.trim().isEmpty || chat.isSending) return;
    await ref.read(riderCustomerServiceChatProvider.notifier).sendMessage(text);
    if (!mounted) return;
    if (ref.read(riderCustomerServiceChatProvider).error == null) {
      setState(() => _controller.clear());
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final chatState = ref.watch(riderCustomerServiceChatProvider);
    final dark = profileDark(context);
    final accent = dark ? const Color(0xFFCFACED) : const Color(0xFF5F2D82);
    ref.listen(
      riderCustomerServiceChatProvider,
      (previous, next) => _scrollToBottom(),
    );

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF17121F) : Colors.white,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF17121F) : Colors.white,
        foregroundColor: profileText(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: dark ? const Color(0xFF30233F) : Colors.white,
              child: Icon(Icons.support_agent_outlined, color: accent),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 10)),
            Expanded(
              child: Text(
                AppLocalization.translate('lesgo_rider_support', lang),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'callback':
                  ref
                      .read(riderCustomerServiceChatProvider.notifier)
                      .requestAdminCallback();
                  break;
                case 'clear':
                  ref
                      .read(riderCustomerServiceChatProvider.notifier)
                      .clearChat();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'callback',
                enabled: !chatState.isSending,
                child: Text(AppLocalization.translate('rs_live_agent', lang)),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text(
                  AppLocalization.translate(
                    chatState.isLiveAgent ? 'refresh_status' : 'clear_chat',
                    lang,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.spacing(context, 12),
                horizontal: ResponsiveUtils.spacing(context, 16),
              ),
              itemCount:
                  chatState.messages.length + 1 + (chatState.isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0) return _intro(lang, !chatState.isLiveAgent);
                if (index > chatState.messages.length) {
                  return _typingIndicator(context);
                }
                final msg = chatState.messages[index - 1];
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
          _inputBar(chatState.isSending, lang),
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
            child: Icon(
              Icons.support_agent,
              size: 16,
              color: Color(0xFF5F2D82),
            ),
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

  Widget _intro(AppLanguage lang, bool configured) {
    String tr(String key) => AppLocalization.translate(key, lang);
    final accent = profileDark(context)
        ? const Color(0xFFCFACED)
        : const Color(0xFF5F2D82);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!configured)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ProfilePanel(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalization.translate('rs_chat_unavailable', lang),
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          height: 1.5,
                          color: profileMuted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Text(
            tr('rs_help_title'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: profileText(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr('rs_help_hint'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              height: 1.5,
              color: profileMuted(context),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in ['bookings', 'earnings', 'wallet', 'documents'])
                ActionChip(
                  label: Text(tr(key)),
                  backgroundColor: profileDark(context)
                      ? const Color(0xFF241D30)
                      : Colors.white,
                  labelStyle: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: accent,
                  ),
                  onPressed: () {
                    final draft = tr(
                      'rs_topic_draft',
                    ).replaceAll('{{topic}}', tr(key));
                    setState(() => _controller.text = draft);
                    _controller.selection = TextSelection.collapsed(
                      offset: draft.length,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputBar(bool isSending, AppLanguage lang) {
    final dark = profileDark(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF17121F) : Colors.white,
          border: Border(
            top: BorderSide(
              color: dark ? const Color(0xFF393044) : const Color(0xFFEDE9F2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !isSending,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 14,
                  color: profileText(context),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: AppLocalization.translate('rs_message_hint', lang),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintStyle: TextStyle(
                    color: profileMuted(context),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: dark ? const Color(0xFF241D30) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5DEEC)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: AppLocalization.translate('rs_send', lang),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                disabledBackgroundColor: dark
                    ? const Color(0xFF352D3F)
                    : const Color(0xFFE9E3EE),
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isSending || _controller.text.trim().isEmpty
                  ? null
                  : _send,
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
          color: isUser
              ? const Color(0xFF5F2D82)
              : (profileDark(context) ? const Color(0xFF241D30) : Colors.white),
          border: isUser
              ? null
              : Border.all(
                  color: profileDark(context)
                      ? const Color(0xFF393044)
                      : const Color(0xFFEDE9F2),
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            color: isUser ? Colors.white : profileText(context),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
