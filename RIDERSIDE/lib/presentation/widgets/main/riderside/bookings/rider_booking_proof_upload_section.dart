import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/app_localization.dart';

class RiderBookingProofUploadSection extends ConsumerWidget {
  const RiderBookingProofUploadSection({
    super.key,
    required this.selectedImages,
    required this.isUploading,
    required this.onPickImages,
    required this.onTakePhoto,
    required this.onRemoveImage,
    required this.onUpload,
  });

  final List<XFile> selectedImages;
  final bool isUploading;
  final VoidCallback onPickImages;
  final VoidCallback onTakePhoto;
  final void Function(int index) onRemoveImage;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Padding(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
      child: Column(
        children: [
          if (selectedImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                final image = selectedImages[index];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                image.path,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.file(
                                File(image.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file,
                  size: 64,
                  color: const Color(0xFF5F2D82).withValues(alpha: 0.5),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Text(
                  AppLocalization.translate('upload_proof_delivery', lang),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                Text(
                  AppLocalization.translate('take_photos_or_gallery', lang),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  AppLocalization.translate('max_5_images', lang),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade500,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!kIsWeb) ...[
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : onTakePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(AppLocalization.translate('camera', lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF5F2D82),
                          side: const BorderSide(color: Color(0xFF5F2D82)),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtils.spacing(context, 12)),
                    ],
                    ElevatedButton.icon(
                      onPressed: isUploading ? null : onPickImages,
                      icon: const Icon(Icons.photo_library),
                      label: Text(AppLocalization.translate('gallery', lang)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F2D82),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (selectedImages.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUploading ? null : onUpload,
                icon: isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  isUploading
                      ? AppLocalization.translate('uploading_images', lang)
                      : AppLocalization.translate('upload_images_count', lang)
                          .replaceAll('{{count}}', '${selectedImages.length}'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.spacing(context, 16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
