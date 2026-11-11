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

  static const _violet = Color(0xFF5F2D82);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF1E1730) : Colors.white;
    final border = dark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2);
    final title = dark ? Colors.white : const Color(0xFF1A0A2E);
    final muted = dark ? const Color(0xFF9A85B8) : Colors.grey.shade600;
    final canAddMore = selectedImages.length < 5;

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 18)),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: dark ? .10 : .06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _violet.withValues(alpha: dark ? .30 : .10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.add_a_photo_outlined,
                    size: 26, color: dark ? const Color(0xFFD9C2F5) : _violet),
              ),
              SizedBox(width: ResponsiveUtils.spacing(context, 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalization.translate('upload_proof_delivery', lang),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppLocalization.translate('take_photos_or_gallery', lang),
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12.5),
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF2A2140) : const Color(0xFFF4F2F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedImages.length}/5',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          if (selectedImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                final image = selectedImages[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(image.path, fit: BoxFit.cover)
                          : Image.file(File(image.path), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: isUploading ? null : () => onRemoveImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
          ],
          Row(
            children: [
              if (!kIsWeb) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUploading || !canAddMore ? null : onTakePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(AppLocalization.translate('camera', lang)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: dark ? const Color(0xFFD9C2F5) : _violet,
                      side: BorderSide(
                          color: dark ? const Color(0xFF6E4A9A) : _violet,
                          width: 1.4),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 12)),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading || !canAddMore ? null : onPickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(AppLocalization.translate('gallery', lang)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dark ? const Color(0xFFD9C2F5) : _violet,
                    side: BorderSide(
                        color: dark ? const Color(0xFF6E4A9A) : _violet,
                        width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 10)),
          Text(
            AppLocalization.translate('max_5_images', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11.5),
              color: muted,
            ),
          ),
          if (selectedImages.isNotEmpty) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            FilledButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                isUploading
                    ? AppLocalization.translate('uploading_images', lang)
                    : AppLocalization.translate('upload_images_count', lang)
                        .replaceAll('{{count}}', '${selectedImages.length}'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 15,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
