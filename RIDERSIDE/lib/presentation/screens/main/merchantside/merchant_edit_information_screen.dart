import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../provider/main/merchantside/merchant_edit_profile_provider.dart';
import '../../../widgets/widgets.dart';

class MerchantEditInformationScreen extends ConsumerStatefulWidget {
  const MerchantEditInformationScreen({super.key});

  @override
  ConsumerState<MerchantEditInformationScreen> createState() =>
      _MerchantEditInformationScreenState();
}

class _MerchantEditInformationScreenState
    extends ConsumerState<MerchantEditInformationScreen> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _restaurantController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _referralController;

  @override
  void initState() {
    super.initState();
    _restaurantController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _referralController = TextEditingController();
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final notifier = ref.read(merchantEditProfileProvider.notifier);
    final success = await notifier.attemptSave();

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSuccess(context, 'Information updated successfully');
      Navigator.pop(context);
    } else {
      final errorMessage = ref.read(merchantEditProfileProvider).errorMessage;
      SnackBarUtils.showError(
        context,
        errorMessage ?? 'Failed to update information',
      );
    }
  }

  Future<void> _pickLogo() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        ref.read(merchantEditProfileProvider.notifier).updateLogoPath(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to pick image');
    }
  }

  Future<void> _copyReferralCode() async {
    final referralCode = ref.read(merchantEditProfileProvider).referralCode;
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!mounted) return;
    SnackBarUtils.showInfo(context, 'Referral code copied');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantEditProfileProvider);

    // Update controllers when state changes
    if (_restaurantController.text != state.restaurantName) {
      _restaurantController.text = state.restaurantName;
    }
    if (_contactController.text != state.contactNumber) {
      _contactController.text = state.contactNumber;
    }
    if (_emailController.text != state.email) {
      _emailController.text = state.email;
    }
    if (_referralController.text != state.referralCode) {
      _referralController.text = state.referralCode;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: MerchantEditInformationActionBar(
        onCancel: () => Navigator.pop(context),
        onSave: state.isSubmitting ? null : _saveChanges,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(
              showBackButton: true,
              backgroundColor: Colors.white,
              borderColor: Color(0xFFE5E5E5),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context),
                  vertical: ResponsiveUtils.spacing(context, 16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: MerchantEditInformationHeaderSection(
                        restaurantName: state.restaurantName,
                        logoUrl: state.logoUrl,
                        logoPath: state.logoPath,
                        onCameraTap: _pickLogo,
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 26)),
                    MerchantEditInformationField(
                      label: 'RESTAURANT NAME',
                      controller: _restaurantController,
                      onChanged: (value) => ref
                          .read(merchantEditProfileProvider.notifier)
                          .updateRestaurantName(value),
                    ),
                    MerchantEditInformationField(
                      label: 'CONTACT NUMBER',
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => ref
                          .read(merchantEditProfileProvider.notifier)
                          .updateContactNumber(value),
                    ),
                    MerchantEditInformationField(
                      label: 'EMAIL',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => ref
                          .read(merchantEditProfileProvider.notifier)
                          .updateEmail(value),
                    ),
                    MerchantReferralCodeField(
                      controller: _referralController,
                      onCopyTap: _copyReferralCode,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 6)),
                    Padding(
                      padding: EdgeInsets.only(
                        left: ResponsiveUtils.spacing(context, 2),
                        bottom: ResponsiveUtils.spacing(context, 8),
                      ),
                      child: Text(
                        'Share this code to earn partner rewards.',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 10),
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF6B6570),
                        ),
                      ),
                    ),
                    if (state.isSubmitting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
