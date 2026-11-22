import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/support/customer_service_chat_provider.dart';

class CustomerServiceMessageBubble extends StatelessWidget {
  final CustomerServiceMessage message;

  const CustomerServiceMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
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
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.spacing(context, 14),
                    vertical: ResponsiveUtils.spacing(context, 10),
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.accent(context, Color(0xFF5F2D82))
                        : AppColors.surface(context, Colors.grey.shade100),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: isUser
                          ? Colors.white
                          : AppColors.foreground(context, Colors.black87),
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 2)),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 11),
                    color: AppColors.foreground(context, Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: ResponsiveUtils.spacing(context, 8)),
            _avatar(context, isUser),
          ],
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, bool isUser) {
    if (!isUser) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFEDE3F7),
        child: ClipOval(
          child: Image.asset(
            'assets/images/ai/ibow_orbit.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.smart_toy_rounded, size: 16),
          ),
        ),
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
