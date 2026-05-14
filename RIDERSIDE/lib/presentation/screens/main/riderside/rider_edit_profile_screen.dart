import 'package:flutter/material.dart';
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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(riderProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.contact);
    _addressController = TextEditingController(text: profile.address);
    _vehicleController = TextEditingController(text: profile.vehicle);
    _plateController = TextEditingController(text: profile.plateNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _vehicleController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Update user profile
      await ApiService.updateProfile({
        'name': _nameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address_line1': _addressController.text.trim(),
      });

      // Update driver profile fields if vehicle/plate changed
      final vehicleText = _vehicleController.text.trim();
      final plateText = _plateController.text.trim();
      if (vehicleText.isNotEmpty || plateText.isNotEmpty) {
        try {
          // Get driver profile ID from the /me response
          final meData = await ApiService.getMe();
          final dp = (meData['user'] ?? meData)['driver_profile'] as Map<String, dynamic>?;
          final driverProfileId = dp?['id'];
          if (driverProfileId != null) {
            await ApiService.dio.patch('/v1/drivers/$driverProfileId', data: {
              if (vehicleText.isNotEmpty) 'vehicle_type': vehicleText,
              if (plateText.isNotEmpty) 'plate_number': plateText,
            });
          }
        } catch (e) {
          print('Driver profile update error: $e');
          // Best-effort, don't fail the whole save
        }
      }

      // Reload profile to reflect changes
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
            onPressed: _isSaving ? null : _save,
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
      body: SingleChildScrollView(
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 16),
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
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 15),
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
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
