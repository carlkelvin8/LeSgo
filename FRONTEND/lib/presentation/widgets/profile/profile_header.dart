import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/media_url_utils.dart';

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
  Widget build(BuildContext context) {
    final firstName = name.trim().split(' ').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF271440), Color(0xFF492071), Color(0xFF65379B)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -100,
              end: -88,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x2667F4D0),
                      width: 26,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x30F8DCFF)),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(profileImageUrl: profileImageUrl, onTap: onImageTap),
                  const SizedBox(height: 18),
                  Text(
                    firstName.isEmpty ? 'Hello there!' : 'Hello, $firstName!',
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.9,
                      color: Color(0xFFFFF8FF),
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFFF0E1FF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback? onTap;
  const _Avatar({this.profileImageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    const radius = BorderRadius.all(Radius.circular(24));
    return Tooltip(
      message: onTap == null ? 'Profile photo' : 'Change profile photo',
      child: SizedBox.square(
        dimension: 76,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: const Color(0xB3F0E1FF)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: _buildImage(size),
              ),
            ),
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFCFF9EC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF492071), width: 2),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 15,
                    color: Color(0xFF163C35),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, borderRadius: radius),
              ),
            ),
          ],
        ),
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
          loadingBuilder: (ctx, child, prog) => prog == null
              ? child
              : ColoredBox(
                  color: AppColors.surface(ctx, const Color(0xFFEDD9FF)),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent(ctx, const Color(0xFF5F2D82)),
                    ),
                  ),
                ),
          errorBuilder: (_, _, _) => _placeholder(),
        );
      }
      return Image.file(
        File(profileImageUrl!),
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, _, _) => _placeholder(),
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
