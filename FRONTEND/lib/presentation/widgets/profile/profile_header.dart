import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/media_url_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../global/custom_divider.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String birthdate;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final VoidCallback? onImageTap;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.birthdate,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Here's your information",
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          const CustomDivider(
            indent: 0,
            endIndent: 0,
            height: 1,
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
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      birthdate,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      email,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                    Text(
                      phone,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 16)),
              InkWell(
                onTap: onImageTap != null
                    ? () {
                        print('🔵 ProfileHeader: Profile image tapped!');
                        print('🔵 ProfileHeader: Calling onImageTap callback...');
                        onImageTap!();
                      }
                    : null,
                // Prevent tap from propagating to widgets below
                excludeFromSemantics: false,
                child: Container(
                  width: ResponsiveUtils.spacing(context, 90),
                  height: ResponsiveUtils.spacing(context, 90),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildProfileImage(context, profileImageUrl!),
                        )
                      : SvgPicture.asset(
                          'assets/images/register/10.svg',
                          width: ResponsiveUtils.spacing(context, 90),
                          height: ResponsiveUtils.spacing(context, 90),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, String imagePath) {
    final size = ResponsiveUtils.spacing(context, 90);
    final networkUrl = MediaUrlUtils.resolve(imagePath);

    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF5F2D82),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.person,
              color: Colors.grey,
              size: 40,
            ),
          );
        },
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 40,
          ),
        );
      },
    );
  }
}
