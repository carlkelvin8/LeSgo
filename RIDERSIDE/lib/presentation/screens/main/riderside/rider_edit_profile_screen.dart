import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/services/api_service.dart';
import '../../../provider/main/riderside/rider_profile_provider.dart';

class RiderEditProfileScreen extends ConsumerStatefulWidget {
  const RiderEditProfileScreen({super.key});

  @override
  ConsumerState<RiderEditProfileScreen> createState() =>
      _RiderEditProfileScreenState();
}

class _RiderEditProfileScreenState
    extends ConsumerState<RiderEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _vehicleController;
  late final TextEditingController _plateController;
  late final TextEditingController _referralController;

  bool _isSaving = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _vehicleController = TextEditingController();
    _plateController = TextEditingController();
    _referralController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderProfileProvider.notifier).loadProfile();
    });
  }

  void _hydrateFromProfile(RiderProfileState profile) {
    if (_hydrated || profile.isLoading) return;
    _hydrated = true;
    _nameController.text = profile.name;
    _phoneController.text = profile.contact;
    _addressController.text = profile.address;
    _vehicleController.text = profile.vehicle;
    _plateController.text = profile.plateNumber;
    _referralController.text = profile.referralCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _copyReferralCode() async {
    final code = _referralController.text.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral code copied')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ApiService.updateProfile({
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address_line1': _addressController.text.trim(),
      });

      final vehicleText = _vehicleController.text.trim();
      final plateText = _plateController.text.trim();
      if (vehicleText.isNotEmpty || plateText.isNotEmpty) {
        try {
          final meData = await ApiService.getMe();
          final user = meData['user'] ?? meData['data'] ?? meData;
          final dp =
              user is Map ? user['driver_profile'] as Map<String, dynamic>? : null;
          final driverProfileId = dp?['id'];
          if (driverProfileId != null) {
            await ApiService.dio.patch('/v1/drivers/$driverProfileId', data: {
              if (vehicleText.isNotEmpty) 'vehicle_type': vehicleText,
              if (plateText.isNotEmpty) 'plate_number': plateText,
            });
          }
        } catch (e) {
          print('Driver profile update error: $e');
        }
      }

      await ref.read(riderProfileProvider.notifier).loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${ApiService.extractError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(riderProfileProvider);
    _hydrateFromProfile(profile);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5F2D82)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving || profile.isLoading ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
                    ),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5F2D82),
                    ),
                  ),
          ),
        ],
      ),
      body: profile.isLoading && !_hydrated
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F2D82)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: hp,
                vertical: ResponsiveUtils.spacing(context, 24),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      context,
                      label: 'Full Name',
                      controller: _nameController,
                      hint: 'Enter your full name',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildField(
                      context,
                      label: 'Contact Number',
                      controller: _phoneController,
                      hint: '+639XXXXXXXXX',
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildField(
                      context,
                      label: 'Address',
                      controller: _addressController,
                      hint: 'Enter your address',
                      maxLines: 2,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildField(
                      context,
                      label: 'Vehicle Type',
                      controller: _vehicleController,
                      hint: 'e.g. Motorcycle, Bicycle',
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildField(
                      context,
                      label: 'Plate Number',
                      controller: _plateController,
                      hint: 'e.g. ABC 1234',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildField(
                      context,
                      label: 'Referral Code',
                      controller: _referralController,
                      hint: 'Loading referral code…',
                      readOnly: true,
                      suffix: IconButton(
                        onPressed: _referralController.text.trim().isEmpty
                            ? null
                            : _copyReferralCode,
                        icon: const Icon(Icons.copy, color: Color(0xFF5F2D82)),
                        tooltip: 'Copy referral code',
                      ),
                    ),
                    SizedBox(height: ResponsiveUtils.spacing(context, 40)),
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.spacing(context, 52),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F2D82),
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize:
                                      ResponsiveUtils.fontSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 6)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            color: readOnly ? Colors.grey.shade700 : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            hintStyle: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF5F2D82), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.spacing(context, 16),
              vertical: ResponsiveUtils.spacing(context, 14),
            ),
          ),
        ),
      ],
    );
  }
}
