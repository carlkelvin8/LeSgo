import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/register/register_routes.dart';

import '../../../provider/register/merchant/merchant_register_info_provider.dart';
import '../../../widgets/global/primary_button.dart';
import '../../../widgets/global/register_scaffold.dart';
import '../../../widgets/register/merchant/info/merchant_document_upload_list.dart';
import '../../../widgets/register/merchant/info/merchant_info_form_fields.dart';

class MerchantRegisterScreen extends ConsumerStatefulWidget {
  const MerchantRegisterScreen({super.key});

  @override
  ConsumerState<MerchantRegisterScreen> createState() =>
      _MerchantRegisterScreenState();
}

class _MerchantRegisterScreenState
    extends ConsumerState<MerchantRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _ownerFirstNameController = TextEditingController();
  final _ownerLastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _zipCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restaurantNameController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateRestaurantName(_restaurantNameController.text);
    });
    _ownerFirstNameController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateOwnerFirstName(_ownerFirstNameController.text);
    });
    _ownerLastNameController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateOwnerLastName(_ownerLastNameController.text);
    });
    _emailController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateEmail(_emailController.text);
    });
    _contactNumberController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateContactNumber(_contactNumberController.text);
    });
    _addressController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateAddress(_addressController.text);
    });
    _zipCodeController.addListener(() {
      ref
          .read(merchantRegisterInfoProvider.notifier)
          .updateZipCode(_zipCodeController.text);
    });
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _ownerFirstNameController.dispose();
    _ownerLastNameController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // Trigger visual validation in UI
    _formKey.currentState?.validate();
    // Attempt submit (controller handles logic validation)
    ref.read(merchantRegisterInfoProvider.notifier).attemptSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantRegisterInfoProvider);
    final controller = ref.read(merchantRegisterInfoProvider.notifier);

    ref.listen<MerchantRegisterInfoState>(merchantRegisterInfoProvider, (
      previous,
      next,
    ) {
      if (next.errorMessage != null) {
        SnackBarUtils.showError(context, next.errorMessage!);
        controller.clearError();
      }
      if (next.isSubmitted) {
        AppRouter.push(context, RegisterRoutes.merchantComplete);
      }
    });

    return RegisterScaffold(
      title: 'Register',
      headerBottomSpacing: 24,
      body: Form(
        key: _formKey,
        autovalidateMode: state.hasAttemptedSubmit
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Illustration (Placeholder)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9B59F0), width: 2),
                ),
                child: SvgPicture.asset(
                  'assets/images/register/10.svg', // Assuming 10.svg is store
                  height: ResponsiveUtils.imageHeight(context, 180),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            MerchantInfoFormFields(
              restaurantNameController: _restaurantNameController,
              ownerFirstNameController: _ownerFirstNameController,
              ownerLastNameController: _ownerLastNameController,
              emailController: _emailController,
              contactNumberController: _contactNumberController,
              addressController: _addressController,
              zipCodeController: _zipCodeController,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 24)),

            MerchantDocumentUploadList(
              onUploadSelfie: controller.uploadSelfie,
              onUploadValidId: controller.uploadValidId,
              onUploadDigitalSignature: controller.uploadDigitalSignature,
              onUploadBarangayPermit: controller.uploadBarangayPermit,
              onUploadMayorsPermit: controller.uploadMayorsPermit,
              onUploadDtiPermit: controller.uploadDtiPermit,
              isSelfieLoading: state.isSelfieLoading,
              isValidIdLoading: state.isValidIdLoading,
              isSignatureLoading: state.isSignatureLoading,
              isBarangayPermitLoading: state.isBarangayPermitLoading,
              isMayorsPermitLoading: state.isMayorsPermitLoading,
              isDtiPermitLoading: state.isDtiPermitLoading,
              selfiePath: state.documents.selfiePath,
              validIdPath: state.documents.validIdPath,
              digitalSignaturePath: state.documents.digitalSignaturePath,
              barangayPermitPath: state.documents.barangayPermitPath,
              mayorsPermitPath: state.documents.mayorsPermitPath,
              dtiPermitPath: state.documents.dtiPermitPath,
              showError: state.hasAttemptedSubmit,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 32)),

            PrimaryButton(
              text: 'SUBMIT',
              onPressed: state.isSubmitting ? () {} : _handleSubmit,
              isLoading: state.isSubmitting,
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'We appreciate your application and are excited to welcome you aboard!\n\nPlease allow us 24 to 48 hours to carefully review your details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 32)),
          ],
        ),
      ),
    );
  }
}
