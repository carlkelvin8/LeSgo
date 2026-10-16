import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/media_url_utils.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class MerchantEditInformationHeaderSection extends StatelessWidget {
  const MerchantEditInformationHeaderSection({
    super.key,
    required this.restaurantName,
    required this.logoUrl,
    required this.logoPath,
    required this.onCameraTap,
  });

  final String restaurantName;
  final String? logoUrl;
  final String? logoPath;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MerchantLogoBadge(logoUrl: logoUrl, logoPath: logoPath,
          restaurantName: restaurantName, onCameraTap: onCameraTap),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('BUSINESS PROFILE', style: TextStyle(fontFamily: 'TT Fors',
            fontSize: 10, letterSpacing: 1.4, color: Color(0xFF8A8292), fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(restaurantName, style: const TextStyle(fontFamily: 'TT Fors',
            fontSize: 22, height: 1.2, fontWeight: FontWeight.w800, color: Color(0xFF332A3B))),
          TextButton(onPressed: onCameraTap,
            style: TextButton.styleFrom(padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft, foregroundColor: const Color(0xFF5F2D82)),
            child: const Text('Change photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        ])),
      ],
    );
  }

}

class _MerchantLogoBadge extends StatelessWidget {
  const _MerchantLogoBadge({
    required this.logoUrl,
    required this.logoPath,
    required this.restaurantName,
    required this.onCameraTap,
  });

  final String? logoUrl;
  final String? logoPath;
  final String restaurantName;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.spacing(context, 86);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              width: size,
              height: size,
              color: const Color(0xFFF0E8F5),
              child: _buildLogoContent(context),
            ),
          ),
          Positioned(
            right: ResponsiveUtils.spacing(context, -2),
            bottom: ResponsiveUtils.spacing(context, 8),
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                width: ResponsiveUtils.spacing(context, 34),
                height: ResponsiveUtils.spacing(context, 34),
                decoration: const BoxDecoration(
                  color: Color(0xFF5A1D8D),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: ResponsiveUtils.spacing(context, 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoContent(BuildContext context) {
    if (logoPath != null && MediaUrlUtils.isLocalFilePath(logoPath)) {
      if (logoPath!.startsWith('content://') ||
          logoPath!.startsWith('file://')) {
        return FutureBuilder<Uint8List>(
          future: XFile(logoPath!).readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            }
            return _initials(context);
          },
        );
      }
      return Image.file(
        File(logoPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final resolved = MediaUrlUtils.resolve(logoPath ?? logoUrl);
    if (resolved != null) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _initials(context),
      );
    }

    return _initials(context);
  }

  Widget _initials(BuildContext context) {
    final words = restaurantName.split(' ').take(2).toList();
    final initials = words.map((w) => w.isNotEmpty ? w[0] : '').join();

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 32),
          fontWeight: FontWeight.w900,
          color: const Color(0xFF5F2D82),
        ),
      ),
    );
  }
}
