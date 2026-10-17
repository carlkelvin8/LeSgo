import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/app_localization.dart';

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
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _vehicleController = TextEditingController();
    _plateController = TextEditingController();

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
          final dp = user is Map
              ? user['driver_profile'] as Map<String, dynamic>?
              : null;
          final driverProfileId = dp?['id'];
          if (driverProfileId != null) {
            await ApiService.dio.patch(
              '/v1/drivers/$driverProfileId',
              data: {
                if (vehicleText.isNotEmpty) 'vehicle_type': vehicleText,
                if (plateText.isNotEmpty) 'plate_number': plateText,
              },
            );
          }
        } catch (e) {
          AppLogger.error('Driver profile update error', e);
        }
      }

      await ref.read(riderProfileProvider.notifier).loadProfile();

      if (mounted) {
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalization.translate('profile_updated', lang)),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final lang = ref.read(appLanguageProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalization.translate(
                'failed_to_update_profile',
                lang,
              ).replaceAll('{{error}}', ApiService.extractError(e)),
            ),
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
    final lang = ref.watch(appLanguageProvider);
    final profile = ref.watch(riderProfileProvider);
    _hydrateFromProfile(profile);
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final purple = dark ? const Color(0xFFD8B6F4) : const Color(0xFF5F2D82);
    final busy = _isSaving || profile.isLoading;
    String tr(String key) => AppLocalization.translate(key, lang);
    String copy(String en, String tl) => lang == AppLanguage.filipino ? tl : en;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: dark ? colors.surface : Colors.white,
        appBar: AppBar(
          backgroundColor: dark ? colors.surface : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.arrow_back_rounded, color: purple),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
          title: Text(
            tr('edit_profile'),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: dark ? colors.surface : Colors.white,
              border: Border(
                top: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF5F2D82),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            tr('save_changes'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: profile.isLoading && !_hydrated
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section(
                            context,
                            icon: Icons.person_outline_rounded,
                            title: copy(
                              'Personal details',
                              'Personal na detalye',
                            ),
                            children: [
                              _buildField(
                                context,
                                label: tr('full_name'),
                                controller: _nameController,
                                hint: tr('enter_full_name'),
                                icon: Icons.person_outline_rounded,
                                autofillHints: const [AutofillHints.name],
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? tr('name_required')
                                    : null,
                              ),
                              _buildField(
                                context,
                                label: tr('contact_number'),
                                controller: _phoneController,
                                hint: '+639XXXXXXXXX',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber,
                                ],
                              ),
                              _buildField(
                                context,
                                label: tr('address'),
                                controller: _addressController,
                                hint: tr('enter_address'),
                                icon: Icons.location_on_outlined,
                                autofillHints: const [
                                  AutofillHints.fullStreetAddress,
                                ],
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _section(
                            context,
                            icon: Icons.two_wheeler_outlined,
                            title: copy(
                              'Vehicle details',
                              'Detalye ng sasakyan',
                            ),
                            children: [
                              _buildField(
                                context,
                                label: tr('vehicle_type'),
                                controller: _vehicleController,
                                hint: copy(
                                  'e.g. Motorcycle, Bicycle',
                                  'Hal. Motorsiklo, Bisikleta',
                                ),
                                icon: Icons.two_wheeler_outlined,
                              ),
                              _buildField(
                                context,
                                label: tr('plate_number'),
                                controller: _plateController,
                                hint: tr('plate_number_hint'),
                                icon: Icons.confirmation_number_outlined,
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final purple = dark ? const Color(0xFFD8B6F4) : const Color(0xFF5F2D82);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? colors.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: purple, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
    Iterable<String>? autofillHints,
  }) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final purple = dark ? const Color(0xFFD8B6F4) : const Color(0xFF5F2D82);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !_isSaving,
          keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
          maxLines: maxLines,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          textCapitalization: textCapitalization,
          validator: validator,
          autofillHints: autofillHints,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 15,
            color: colors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintMaxLines: 2,
            errorMaxLines: 3,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: purple.withValues(alpha: 0.75),
            ),
            hintStyle: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 14,
              color: colors.onSurfaceVariant.withValues(alpha: 0.65),
            ),
            filled: true,
            fillColor: dark ? colors.surface : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: purple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
