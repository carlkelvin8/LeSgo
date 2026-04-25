import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../widgets.dart';

class VerificationContent extends StatelessWidget {
  const VerificationContent({
    super.key,
    required this.selfiePath,
    required this.isLoading,
    required this.onStart,
    required this.onNext,
  });

  final String selfiePath;
  final bool isLoading;
  final Future<void> Function() onStart;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(title: 'SIGN UP'),
          SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    'Selfie for verification',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  Center(
                    child: selfiePath.isNotEmpty
                        ? Container(
                            width: ResponsiveUtils.imageHeight(context, 400),
                            height: ResponsiveUtils.imageHeight(context, 400),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: kIsWeb
                                  ? Image.network(
                                      selfiePath,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / 
                                                    loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Image loading error on web: $error');
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                                size: 50,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : Image.file(
                                      File(selfiePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Image loading error on mobile: $error');
                                        return Container(
                                          color: Colors.grey[300],
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                                size: 50,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/images/register/10.svg',
                            width: ResponsiveUtils.imageHeight(context, 400),
                            height: ResponsiveUtils.imageHeight(context, 400),
                            fit: BoxFit.contain,
                          ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                  Container(
                    padding: EdgeInsets.all(
                      ResponsiveUtils.spacing(context, 8),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECC9FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color.fromRGBO(100, 45, 130, 1),
                          size: ResponsiveUtils.fontSize(context, 20),
                        ),
                        SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                        Expanded(
                          child: Text(
                            kIsWeb 
                                ? 'Click "Start Verification" to take a photo using your camera. If camera access is blocked, you can select a photo from your files instead.'
                                : 'Make sure you are in a place where there is enough light to take a clear photo.',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: Colors.grey[800],
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          PrimaryButton(
            text: selfiePath.isEmpty ? 'Start Verification' : 'Retake Photo',
            onPressed: isLoading ? null : onStart,
            backgroundColor: const Color(0xFF5F2D82),
            isLoading: isLoading,
          ),
          if (selfiePath.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 12)),
            PrimaryButton(
              text: 'Next',
              onPressed: isLoading ? null : onNext,
              backgroundColor: const Color(0xFF5F2D82),
              isLoading: false,
            ),
          ],
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        ],
      ),
    );
  }
}

