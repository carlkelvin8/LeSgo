import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/media_url_utils.dart';
import '../../../core/utils/responsive_utils.dart';

class ProfileHeroSection extends StatelessWidget {
  final String name, email, phone, birthdate;
  final String? profileImageUrl;
  final VoidCallback? onImageTap, onChangePhoneTap;
  const ProfileHeroSection({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.birthdate,
    this.profileImageUrl,
    this.onImageTap,
    this.onChangePhoneTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    child: Column(
      children: [
        _Avatar(profileImageUrl: profileImageUrl, onTap: onImageTap),
        const SizedBox(height: 12),
        Text(
          name.isEmpty
              ? 'Hello there!'
              : 'Hello, ${name.trim().split(' ').first}!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 21),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: AppColors.foreground(context, Color(0xFF25232B)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            color: AppColors.foreground(context, Color(0xFF89858E)),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback? onTap;
  const _Avatar({this.profileImageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imgSize = ResponsiveUtils.spacing(context, 64);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent(context, Color(0xFF5F2D82)).withValues(alpha: .10),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(child: _buildImage(imgSize)),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF8B3FC8), width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 11,
                color: Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(double size) {
    if (profileImageUrl?.isNotEmpty == true) {
      final url = MediaUrlUtils.resolve(profileImageUrl!);
      if (url != null) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (_, child, prog) => prog == null
              ? child
              : const ColoredBox(
                  color: Color(0xFFEDD9FF),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF5F2D82),
                    ),
                  ),
                ),
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      }
      return Image.file(
        File(profileImageUrl!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    color: const Color(0xFFDEC4F2),
    child: const Icon(Icons.person_rounded, size: 36, color: Color(0xFF7B3FAA)),
  );
}

typedef ProfileHeader = ProfileHeroSection;
