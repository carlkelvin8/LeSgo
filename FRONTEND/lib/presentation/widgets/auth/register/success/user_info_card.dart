import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive_utils.dart';

class UserInfoCard extends StatelessWidget {
  final String name;
  final String birthday;
  final String email;
  final String phoneNumber;
  final Widget? avatarWidget;

  const UserInfoCard({
    super.key,
    required this.name,
    required this.birthday,
    required this.email,
    required this.phoneNumber,
    this.avatarWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Here's your information:",
            style: TextStyle(
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      birthday,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (avatarWidget != null) avatarWidget!,
            ],
          ),
        ],
      ),
    );
  }
}
