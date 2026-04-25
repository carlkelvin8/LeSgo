import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../controllers/merchantside/merchant_edit_information_controller.dart';
import '../../../widgets/widgets.dart';

class MerchantEditInformationScreen extends StatefulWidget {
  const MerchantEditInformationScreen({super.key});

  @override
  State<MerchantEditInformationScreen> createState() =>
      _MerchantEditInformationScreenState();
}

class _MerchantEditInformationScreenState
    extends State<MerchantEditInformationScreen> {
  late final MerchantEditInformationController _controller;

  Future<void> _saveChanges() async {
    final isSaved = _controller.saveChanges();
    if (!mounted) return;

    if (!isSaved) {
      SnackBarUtils.showError(context, 'Please complete all required fields');
      return;
    }

    SnackBarUtils.showSuccess(context, 'Information updated successfully');
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    _controller = MerchantEditInformationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyReferralCode() async {
    await Clipboard.setData(ClipboardData(text: _controller.referralController.text));
    if (!mounted) return;
    SnackBarUtils.showInfo(context, 'Referral code copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: MerchantEditInformationActionBar(
        onCancel: () => Navigator.pop(context),
        onSave: _saveChanges,
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
                        restaurantName: _controller.restaurantName,
                        onCameraTap: () {},
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 26)),
                    MerchantEditInformationField(
                      label: 'RESTAURANT NAME',
                      controller: _controller.restaurantController,
                    ),
                    MerchantEditInformationField(
                      label: 'CONTACT NUMBER',
                      controller: _controller.contactController,
                      keyboardType: TextInputType.phone,
                    ),
                    MerchantEditInformationField(
                      label: 'ADDRESS',
                      controller: _controller.addressController,
                      maxLines: 4,
                    ),
                    MerchantReferralCodeField(
                      controller: _controller.referralController,
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
