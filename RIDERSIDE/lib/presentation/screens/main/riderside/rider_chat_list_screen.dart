import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/dto/chat/chat_dto.dart';
import '../../../provider/main/riderside/rider_inbox_provider.dart';
import '../../../provider/main/riderside/rider_inbox_refresh_provider.dart';
import '../../chat/rider_chat_screen.dart';

class RiderChatListScreen extends ConsumerStatefulWidget {
  const RiderChatListScreen({super.key});

  @override
  ConsumerState<RiderChatListScreen> createState() =>
      _RiderChatListScreenState();
}

class _RiderChatListScreenState extends ConsumerState<RiderChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderInboxProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final inboxState = ref.watch(riderInboxProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    ref.listen<int>(riderInboxRefreshSignalProvider, (previous, next) {
      if (previous == next) return;
      ref.read(riderInboxProvider.notifier).loadConversations(silent: true);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalization.translate('messages', lang),
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 20),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: false,
        actions: [
          if (inboxState.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    inboxState.unreadCount > 99
                        ? '99+'
                        : inboxState.unreadCount.toString(),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () =>
            ref.read(riderInboxProvider.notifier).loadConversations(),
        child: _buildBody(inboxState, hp, lang),
      ),
    );
  }

  Widget _buildBody(RiderInboxState state, double hp, AppLanguage lang) {
    if (state.isLoading && state.conversations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
          ),
        ],
      );
    }

    if (state.error != null && state.conversations.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: ResponsiveUtils.spacing(context, 120)),
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  AppLocalization.translate('could_not_load_messages', lang),
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref
                      .read(riderInboxProvider.notifier)
                      .loadConversations(),
                  child: Text(
                    AppLocalization.translate('retry', lang),
                    style: const TextStyle(color: Color(0xFF5F2D82)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.conversations.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: ResponsiveUtils.spacing(context, 120)),
          Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  AppLocalization.translate('no_conversations_yet', lang),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hp),
                  child: Text(
                    AppLocalization.translate(
                        'chat_appears_after_accept_order', lang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.spacing(context, 8),
        horizontal: hp,
      ),
      itemCount: state.conversations.length,
      itemBuilder: (context, index) {
        final conv = state.conversations[index];
        return _ConversationTile(
          conversation: conv,
          onTap: () => _openChat(conv),
        );
      },
    );
  }

  void _openChat(ConversationDto conversation) {
    final orderId = conversation.orderId ?? 0;
    if (orderId <= 0) return;

    final customerName = conversation.customer?.name ?? 'Customer';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiderChatScreen(
          orderId: orderId,
          customerName: customerName,
        ),
      ),
    ).then((_) {
      if (mounted) {
        ref.read(riderInboxProvider.notifier).loadConversations(silent: true);
      }
    });
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final ConversationDto conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final customerName = conversation.customer?.name ?? 'Customer';
    final lastMsg = conversation.latestMessage?.content ?? 'No messages yet';
    final orderId = conversation.orderId;
    final isActive = conversation.status == 'active';
    final latest = conversation.latestMessage;
    final hasUnread = latest != null &&
        latest.readAt == null &&
        latest.senderType.toLowerCase() == 'customer';
    final timestamp = _parseTimestamp(
      conversation.lastMessageAt ?? latest?.createdAt,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 4)),
          decoration: BoxDecoration(
            color: hasUnread ? Colors.white : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: hasUnread
                ? Border.all(color: const Color(0xFF5F2D82).withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
                child: Text(
                  customerName.isNotEmpty
                      ? customerName[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5F2D82),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customerName,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 14),
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            _formatTimeAgo(timestamp),
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 11),
                              color: hasUnread
                                  ? const Color(0xFF5F2D82)
                                  : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 12),
                              color: hasUnread
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (orderId != null)
                          Text(
                            '#$orderId',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize:
                                  ResponsiveUtils.fontSize(context, 10),
                              color: isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade500,
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

  DateTime? _parseTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return DateFormat('MMM d').format(dateTime);
  }
}
