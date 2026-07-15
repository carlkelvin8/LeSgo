import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/app_logger.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../provider/main/merchantside/merchant_quick_reply_provider.dart';

/// Quick Reply section for the order detail screen.
/// Shows template chips that send a message via the chat API.
class MerchantQuickReplySection extends ConsumerStatefulWidget {
  final int orderId;

  const MerchantQuickReplySection({super.key, required this.orderId});

  @override
  ConsumerState<MerchantQuickReplySection> createState() =>
      _MerchantQuickReplySectionState();
}

class _MerchantQuickReplySectionState
    extends ConsumerState<MerchantQuickReplySection> {
  bool _sending = false;

  Future<void> _sendQuickReply(String message) async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      int? conversationId;

      // Try to get existing conversation for this order
      try {
        final convResponse = await ApiService.dio.get(
          ApiConstants.chatConversationByOrder
              .replaceAll('{order_id}', widget.orderId.toString()),
        );
        final convData = convResponse.data['data'];
        if (convData != null) {
          conversationId = convData['id'] as int;
        }
      } catch (e) {
        // Conversation doesn't exist yet, will create one
        AppLogger.debug('No existing conversation, creating one...');
      }

      // Create conversation if it doesn't exist
      if (conversationId == null) {
        try {
          final createResponse = await ApiService.dio.post(
            ApiConstants.chatConversations,
            data: {'order_id': widget.orderId},
          );
          final createData = createResponse.data['data'];
          if (createData != null) {
            conversationId = createData['id'] as int;
          }
        } catch (e) {
          AppLogger.error('Failed to create conversation', e);
        }
      }

      if (conversationId == null) {
        throw Exception('Could not get or create conversation');
      }

      // Send message
      await ApiService.dio.post(
        ApiConstants.chatSendMessage
            .replaceAll('{id}', conversationId.toString()),
        data: {'message': message},
      );

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Message sent!');
      }
    } catch (e) {
      AppLogger.error('Quick reply send failed', e);
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to send message');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = ref.watch(merchantQuickReplyTemplatesProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quickreply_outlined,
                size: ResponsiveUtils.fontSize(context, 18),
                color: const Color(0xFF5F2D82),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 8)),
              Text(
                'Quick Reply',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              if (_sending) ...[
                const Spacer(),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 10)),
          Wrap(
            spacing: ResponsiveUtils.spacing(context, 8),
            runSpacing: ResponsiveUtils.spacing(context, 8),
            children: templates.map((template) {
              return ActionChip(
                label: Text(
                  template,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: const Color(0xFFF3E5F5),
                side: const BorderSide(color: Color(0xFFCE93D8)),
                onPressed: _sending ? null : () => _sendQuickReply(template),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
