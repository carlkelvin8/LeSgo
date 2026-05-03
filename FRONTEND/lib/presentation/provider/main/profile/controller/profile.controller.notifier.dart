import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../profile_provider.dart';

class ProfileControllers {
  final TextEditingController nameController;
  final TextEditingController address1Controller;
  final TextEditingController address2Controller;
  
  // Flag to prevent accidental updates while modal is open
  bool _isModalOpen = false;

  ProfileControllers({
    String name = '',
    String address1 = '',
    String address2 = '',
  })  : nameController = TextEditingController(text: name),
        address1Controller = TextEditingController(text: address1),
        address2Controller = TextEditingController(text: address2);

  Future<void> showImagePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    print('🔵 ProfileControllers: showImagePicker called!');
    
    // Set flag to prevent accidental updates
    _isModalOpen = true;
    
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: false,
      useRootNavigator: true, // Use root navigator to prevent conflicts
      builder: (BuildContext modalContext) {
        print('🔵 ProfileControllers: Building modal bottom sheet...');
        return WillPopScope(
          onWillPop: () async {
            print('🔵 ProfileControllers: Modal being dismissed via back button');
            _isModalOpen = false;
            return true;
          },
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(modalContext, 20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      print('🔵 ProfileControllers: Gallery option tapped');
                      _isModalOpen = false;
                      Navigator.pop(modalContext);
                      Future.delayed(const Duration(milliseconds: 150), () {
                        _pickImageFromGallery(context, ref, picker);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Color(0xFF5F2D82),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Choose from gallery',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      print('🔵 ProfileControllers: Camera option tapped');
                      _isModalOpen = false;
                      Navigator.pop(modalContext);
                      Future.delayed(const Duration(milliseconds: 150), () {
                        _pickImageFromCamera(context, ref, picker);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF5F2D82),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Take a photo',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(modalContext, 10)),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    _isModalOpen = false;
    print('🔵 ProfileControllers: Modal dismissed');
  }


  Future<void> _pickImageFromGallery(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
  ) async {
    print('🔵 ProfileControllers: Picking image from gallery...');
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null && context.mounted) {
      print('🔵 ProfileControllers: Image selected: ${image.path}');
      await _updateProfileImage(context, ref, image);
    } else {
      print('🔵 ProfileControllers: No image selected');
    }
  }

  Future<void> _pickImageFromCamera(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
  ) async {
    print('🔵 ProfileControllers: Picking image from camera...');
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null && context.mounted) {
      print('🔵 ProfileControllers: Image captured: ${image.path}');
      await _updateProfileImage(context, ref, image);
    } else {
      print('🔵 ProfileControllers: No image captured');
    }
  }


  Future<void> _updateProfileImage(
    BuildContext context,
    WidgetRef ref,
    XFile imageFile,
  ) async {
    print('🔵 ProfileControllers: Starting profile image update...');
    print('🔵 ProfileControllers: Image path: ${imageFile.path}');
    print('🔵 ProfileControllers: Image name: ${imageFile.name}');
    
    await ref.read(profileProvider.notifier).updateProfileImage(imageFile);
    
    if (context.mounted) {
      SnackBarUtils.showSuccess(
        context,
        'Profile picture updated successfully!',
      );
    }
  }

  Future<void> updateProfile(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Prevent accidental updates while modal is open
    if (_isModalOpen) {
      print('🔴 ProfileControllers: Blocked updateProfile call - modal is open!');
      print('🔴 ProfileControllers: Stack trace:');
      print(StackTrace.current);
      return;
    }
    
    print('🔵 ProfileControllers: Updating profile...');
    print('🔵 Name: ${nameController.text}');
    print('🔵 Address 1: ${address1Controller.text}');
    print('🔵 Address 2: ${address2Controller.text}');
    
    final success = await ref.read(profileProvider.notifier).updateProfile(
          name: nameController.text.isNotEmpty ? nameController.text : null,
          address1: address1Controller.text,
          address2: address2Controller.text,
        );
    
    print('🔵 ProfileControllers: Update result - success: $success');
    
    if (context.mounted) {
      if (success) {
        SnackBarUtils.showSuccess(context, 'Profile updated successfully!');
      } else {
        SnackBarUtils.showError(context, 'Failed to update profile');
      }
    }
  }

  /// Dispose controllers
  void dispose() {
    nameController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
  }
}
