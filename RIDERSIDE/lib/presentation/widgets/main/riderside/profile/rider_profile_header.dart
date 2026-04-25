import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/riderside/rider_profile_provider.dart';

class RiderProfileHeader extends ConsumerStatefulWidget {
  const RiderProfileHeader({super.key});

  @override
  ConsumerState<RiderProfileHeader> createState() => _RiderProfileHeaderState();
}

class _RiderProfileHeaderState extends ConsumerState<RiderProfileHeader> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      if (!mounted) return;
      
      // Upload the image - pass XFile directly for web compatibility
      final success = await ref.read(riderProfileProvider.notifier).uploadProfilePicture(image);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(riderProfileProvider).error ?? 'Failed to upload';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final profileState = ref.watch(riderProfileProvider);

    // Extract first name from full name
    final firstName = profileState.name.split(' ').first;
    final greeting = firstName.isNotEmpty ? 'LeSgo,\n$firstName!' : 'LeSgo,\nRider!';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: ResponsiveUtils.spacing(context, 24),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: profileState.isUploading ? null : _pickAndUploadImage,
            child: Stack(
              children: [
                Container(
                  width: ResponsiveUtils.spacing(context, 120),
                  height: ResponsiveUtils.spacing(context, 120),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.spacing(context, 12),
                    ),
                  ),
                  child: profileState.profilePictureUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.spacing(context, 12),
                          ),
                          child: Image.network(
                            profileState.profilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              size: ResponsiveUtils.spacing(context, 80),
                              color: Colors.grey.shade500,
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF5F2D82),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: ResponsiveUtils.spacing(context, 80),
                          color: Colors.grey.shade500,
                        ),
                ),
                // Upload indicator overlay
                if (profileState.isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.spacing(context, 12),
                        ),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                // Camera icon overlay
                if (!profileState.isUploading)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF5F2D82),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 20)),
          // Name Text
          Expanded(
            child: profileState.isLoading
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                  )
                : Text(
                    greeting,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 32),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5F2D82),
                      height: 1.1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
