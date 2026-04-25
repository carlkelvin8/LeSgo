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
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF5F2D82),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  onTap: () => _pickImageFromGallery(context, ref, picker),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF5F2D82),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(fontFamily: 'TT Fors'),
                  ),
                  onTap: () => _pickImageFromCamera(context, ref, picker),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _pickImageFromGallery(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
  ) async {
    if (!context.mounted) return;
    Navigator.pop(context);
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null && context.mounted) {
      await _updateProfileImage(context, ref, image);
    }
  }

  Future<void> _pickImageFromCamera(
    BuildContext context,
    WidgetRef ref,
    ImagePicker picker,
  ) async {
    if (!context.mounted) return;
    Navigator.pop(context);
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );
    if (image != null && context.mounted) {
      await _updateProfileImage(context, ref, image);
    }
  }


  Future<void> _updateProfileImage(
    BuildContext context,
    WidgetRef ref,
    XFile imageFile,
  ) async {
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
