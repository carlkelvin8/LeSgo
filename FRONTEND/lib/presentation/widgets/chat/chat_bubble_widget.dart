import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/data_source/dto/chat/message_dto.dart';
import '../../../core/utils/responsive_utils.dart';

class ChatBubbleWidget extends StatelessWidget {
  final MessageDto message;
  final bool isCurrentUser;
  final VoidCallback? onLocationTap;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
        vertical: ResponsiveUtils.spacing(context, 4),
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                _buildTimestamp(context),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isCurrentUser ? const Color(0xFF5F2D82) : Colors.grey[400],
      child: Icon(
        message.senderType == 'driver' ? Icons.directions_car : Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 12),
        vertical: ResponsiveUtils.spacing(context, 8),
      ),
      decoration: BoxDecoration(
      color: _getBubbleColor(context),
      borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
          bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMessageContent(context),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case 'location':
        return _buildLocationMessage(context);
      case 'system':
        return _buildSystemMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Text(
      message.message,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 14),
        color: _getTextColor(context),
        height: 1.4,
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    return GestureDetector(
      onTap: onLocationTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 8)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: _getTextColor(context),
              size: 20,
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Shared',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(context),
                    ),
                  ),
                  Text(
                    'Tap to view on map',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 12),
                      color: _getTextColor(context).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info_outline,
          color: _getTextColor(context),
          size: 16,
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 6)),
        Flexible(
          child: Text(
            message.message,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
            fontStyle: FontStyle.italic,
            color: _getTextColor(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    try {
      // Parse the string date from backend
      final date = DateTime.parse(message.createdAt);
      return Text(
        DateFormat('HH:mm').format(date),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 11),
          color: AppColors.foreground(context, Colors.grey[600]!),
        ),
      );
    } catch (e) {
      // Fallback if date parsing fails
      return Text(
        message.createdAt,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 11),
          color: AppColors.foreground(context, Colors.grey[600]!),
        ),
      );
    }
  }

  Color _getBubbleColor(BuildContext context) {
    if (message.messageType == 'system') {
      return AppColors.surface(context, Colors.grey[200]!);
    }
    return isCurrentUser ? const Color(0xFF5F2D82) : AppColors.surface(context, Colors.grey[200]!);
  }

  Color _getTextColor(BuildContext context) {
    if (message.messageType == 'system') {
      return AppColors.foreground(context, Colors.grey[700]!);
    }
    return isCurrentUser ? Colors.white : AppColors.foreground(context, Colors.black87);
  }
}
