import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/chat_agent.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../domain/entities/support/ibow_expression.dart';
import '../../provider/main/support/customer_service_chat_provider.dart';
import 'ibow_orbit_avatar.dart';

class CustomerServiceMessageBubble extends StatelessWidget {
  final CustomerServiceMessage message;

  /// Where an action button is right now (defaults to ready).
  final AgentActionStatus Function(AgentAction action)? statusOf;

  /// The customer tapped an action's button.
  final void Function(AgentAction action)? onRunAction;

  /// The customer chose "Not now" on the message's actions.
  final VoidCallback? onDismissActions;

  /// The customer tapped a link button.
  final void Function(AgentLink link)? onOpenLink;

  final VoidCallback? onToggleSpeech;
  final bool isPlayingSpeech;

  const CustomerServiceMessageBubble({
    super.key,
    required this.message,
    this.statusOf,
    this.onRunAction,
    this.onDismissActions,
    this.onOpenLink,
    this.onToggleSpeech,
    this.isPlayingSpeech = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    // Messages that just arrived pop in with a little spring; older ones that
    // scroll back into view just appear.
    final fresh =
        DateTime.now().difference(message.timestamp).inMilliseconds < 1500 &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

    final bubble = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _avatar(context, isUser),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 16),
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7A3FB0), Color(0xFF4F2270)],
                          )
                        : null,
                    color: isUser
                        ? null
                        : AppColors.surface(context, Colors.white),

                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.border(
                              context,
                              const Color(0xFFE6E3EA),
                            ),
                            width: 1,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isUser ? 22 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF5F2D82).withValues(alpha: 0.22)
                            : Colors.transparent,
                        blurRadius: isUser ? 14 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: ChatType.body(
                      context,
                      color: isUser
                          ? Colors.white
                          : AppColors.foreground(context, Colors.black),
                    ),
                  ),
                ),
                if (!isUser && message.actions.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  for (final action in message.actions)
                    _ActionCard(
                      action: action,
                      status: statusOf?.call(action) ?? AgentActionStatus.ready,
                      onRun: () => onRunAction?.call(action),
                      onDismiss: onDismissActions,
                    ),
                ],
                if (!isUser && message.links.isNotEmpty) ...[
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final link in message.links)
                        ActionChip(
                          avatar: Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: AppColors.accent(
                              context,
                              const Color(0xFF5F2D82),
                            ),
                          ),
                          label: Text(link.label),
                          onPressed: () => onOpenLink?.call(link),
                          labelStyle: ChatType.chip(context),
                          backgroundColor: AppColors.surface(
                            context,
                            Colors.white,
                          ),
                          elevation: 1.5,
                          shadowColor: const Color(
                            0xFF5F2D82,
                          ).withValues(alpha: 0.25),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: AppColors.accent(
                                context,
                                const Color(0xFF5F2D82),
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: ChatType.meta(context),
                      ),
                    ),
                    if (!isUser && onToggleSpeech != null)
                      IconButton(
                        tooltip: isPlayingSpeech
                            ? 'Stop Ibow speech'
                            : 'Read Ibow reply aloud',
                        iconSize: 18,
                        onPressed: onToggleSpeech,
                        icon: Icon(
                          isPlayingSpeech
                              ? Icons.stop_rounded
                              : Icons.volume_up_outlined,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!fresh) return bubble;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.7 + 0.3 * v,
          alignment: isUser ? Alignment.bottomRight : Alignment.bottomLeft,
          child: child,
        ),
      ),
      child: bubble,
    );
  }

  Widget _avatar(BuildContext context, bool isUser) {
    if (!isUser) {
      return IbowOrbitAvatar(
        size: 36,
        animated: false,
        expression: message.mood ?? IbowExpression.neutral,
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? AppColors.accent(context, const Color(0xFF5F2D82))
          : AppColors.surface(context, const Color(0xFFE8D9F5)),
      child: Icon(
        isUser ? Icons.person : Icons.support_agent,
        size: 16,
        color: isUser
            ? AppColors.onAccent(context)
            : AppColors.accent(context, const Color(0xFF5F2D82)),
      ),
    );
  }
}

/// A confirm card for something IBOW can do. The customer must tap the
/// button; nothing runs on its own.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.status,
    required this.onRun,
    required this.onDismiss,
  });

  final AgentAction action;
  final AgentActionStatus status;
  final VoidCallback onRun;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final destructive = action.kind == AgentActionKind.cancelOrder;
    final tone = destructive
        ? const Color(0xFFE5484D)
        : AppColors.accent(context, const Color(0xFF5F2D82));

    Widget footer;
    switch (status) {
      case AgentActionStatus.ready:
        footer = Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: onRun,
                style: FilledButton.styleFrom(
                  backgroundColor: tone,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onDismiss, child: const Text('Not now')),
          ],
        );
      case AgentActionStatus.running:
        footer = Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: tone),
            ),
            const SizedBox(width: 10),
            const Text('Working on it...'),
          ],
        );
      case AgentActionStatus.done:
        footer = const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E9E5B),
              size: 18,
            ),
            SizedBox(width: 8),
            Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        );
      case AgentActionStatus.dismissed:
        footer = Text(
          'Dismissed',
          style: TextStyle(color: AppColors.foreground(context, Colors.grey)),
        );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            action.detail,
            style: ChatType.body(context, size: 13.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          footer,
        ],
      ),
    );
  }
}

/// The chat's type scale. TT Fors is wide, so body text sits at a medium
/// weight with slightly tightened spacing to read like a messenger, not a
/// poster.
class ChatType {
  const ChatType._();

  static TextStyle body(
    BuildContext context, {
    Color? color,
    double size = 14.5,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: 'TT Fors',
    fontSize: ResponsiveUtils.fontSize(context, size),
    fontWeight: weight,
    height: 1.42,
    letterSpacing: -0.12,
    color: color ?? AppColors.foreground(context, const Color(0xFF2A1B38)),
  );

  static TextStyle meta(BuildContext context) => TextStyle(
    fontFamily: 'TT Fors',
    fontSize: ResponsiveUtils.fontSize(context, 10.5),
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.foreground(context, Colors.grey.shade500),
  );

  static TextStyle chip(BuildContext context) => TextStyle(
    fontFamily: 'TT Fors',
    fontSize: ResponsiveUtils.fontSize(context, 13),
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: AppColors.accent(context, const Color(0xFF5F2D82)),
  );
}
