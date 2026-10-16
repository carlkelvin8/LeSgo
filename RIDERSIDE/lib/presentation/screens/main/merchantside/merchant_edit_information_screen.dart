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
  bool _isPickingLogo = false;
  late final TextEditingController _restaurantController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _referralController;
  late final TextEditingController _prepTimeController;

  @override
  void initState() {
    super.initState();
    _restaurantController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _referralController = TextEditingController();
    _prepTimeController = TextEditingController();
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    _prepTimeController.dispose();
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
    if (_isPickingLogo) return;
    _isPickingLogo = true;
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        ref.read(merchantEditProfileProvider.notifier).updateLogoPath(image.path);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, 'Failed to pick image');
    } finally {
      _isPickingLogo = false;
    }
  }

  Future<void> _copyReferralCode() async {
    final referralCode = ref.read(merchantEditProfileProvider).referralCode;
    await Clipboard.setData(ClipboardData(text: referralCode));
    if (!mounted) return;
    SnackBarUtils.showInfo(context, 'Referral code copied');
  }

  void _openHoursSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _MerchantOperatingHoursScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantEditProfileProvider);

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
    if (_prepTimeController.text != state.prepTime.toString()) {
      _prepTimeController.text = state.prepTime.toString();
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
                    const Divider(height: 36, color: Color(0xFFEDE7F2)),
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
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                    _buildSectionLabel(context, 'Store operations'),
                    SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                    _buildPrepTimeField(context, state),
                    SizedBox(height: ResponsiveUtils.spacing(context, 12)),
                    _buildHoursScheduleTile(context, state),
                    SizedBox(height: ResponsiveUtils.spacing(context, 16)),
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

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 12),
        fontWeight: FontWeight.w700,
        color: const Color(0xFF5F2D82),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildPrepTimeField(BuildContext context, MerchantEditProfileState state) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ESTIMATED PREPARATION TIME',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _prepTimeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: ResponsiveUtils.spacing(context, 10),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    suffixText: 'minutes',
                    suffixStyle: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null) {
                      ref
                          .read(merchantEditProfileProvider.notifier)
                          .updatePrepTime(minutes);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            'How long it typically takes to prepare an order (5-180 min)',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 10),
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursScheduleTile(BuildContext context, MerchantEditProfileState state) {
    final hasHours = state.openingHours != null && state.openingHours!.isNotEmpty;
    final daysCount = hasHours ? state.openingHours!.length : 0;

    return GestureDetector(
      onTap: _openHoursSchedule,
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: const Color(0xFF5F2D82),
              size: ResponsiveUtils.fontSize(context, 20),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERATING HOURS',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Text(
                    hasHours
                        ? '$daysCount day(s) configured — tap to edit'
                        : 'Set your store opening hours',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: hasHours ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantOperatingHoursScreen extends ConsumerStatefulWidget {
  const _MerchantOperatingHoursScreen();

  @override
  ConsumerState<_MerchantOperatingHoursScreen> createState() =>
      _MerchantOperatingHoursScreenState();
}

class _MerchantOperatingHoursScreenState
    extends ConsumerState<_MerchantOperatingHoursScreen> {
  late Map<String, Map<String, dynamic>> _hours;

  static const _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _hours = {};
    final existing = ref.read(merchantEditProfileProvider).openingHours;
    if (existing != null) {
      for (final entry in existing.entries) {
        _hours[entry.key] = Map<String, dynamic>.from(
          entry.value as Map,
        );
      }
    }
  }

  TimeOfDay _parseTime(dynamic value, {int defaultHour = 8, int defaultMinute = 0}) {
    if (value is String) {
      final parts = value.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
      }
    }
    return TimeOfDay(hour: defaultHour, minute: defaultMinute);
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final current = _hours[day];
    final initial = isOpen
        ? _parseTime(current?['open'], defaultHour: 8)
        : _parseTime(current?['close'], defaultHour: 17);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        _hours[day] ??= {'open': '08:00', 'close': '17:00', 'closed': false};
        if (isOpen) {
          _hours[day]!['open'] =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        } else {
          _hours[day]!['close'] =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      });
    }
  }

  void _toggleClosed(String day) {
    setState(() {
      _hours[day] ??= {'open': '08:00', 'close': '17:00', 'closed': false};
      _hours[day]!['closed'] = !(_hours[day]!['closed'] as bool? ?? false);
    });
  }

  void _save() {
    final data = <String, dynamic>{};
    for (final entry in _hours.entries) {
      data[entry.key] = entry.value;
    }
    ref.read(merchantEditProfileProvider.notifier).updateOpeningHours(data);
    Navigator.pop(context);
    SnackBarUtils.showSuccess(context, 'Operating hours saved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Operating Hours',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F2D82),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5F2D82)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F2D82),
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        itemCount: _dayLabels.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final day = _dayLabels.keys.elementAt(index);
          final label = _dayLabels.values.elementAt(index);
          final dayHours = _hours[day];
          final isClosed = dayHours?['closed'] as bool? ?? false;
          final openTime = dayHours?['open'] as String? ?? '08:00';
          final closeTime = dayHours?['close'] as String? ?? '17:00';

          return Padding(
            padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.spacing(context, 8)),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: isClosed
                      ? GestureDetector(
                          onTap: () => _toggleClosed(day),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              'Closed',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: ResponsiveUtils.fontSize(context, 12),
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _TimeSlot(
                                label: openTime,
                                onTap: () => _pickTime(day, true),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveUtils.spacing(context, 6),
                              ),
                              child: Text(
                                '—',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: _TimeSlot(
                                label: closeTime,
                                onTap: () => _pickTime(day, false),
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(width: ResponsiveUtils.spacing(context, 4)),
                GestureDetector(
                  onTap: () => _toggleClosed(day),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isClosed ? 'Open' : 'Close',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 10),
                        fontWeight: FontWeight.w600,
                        color: isClosed ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimeSlot({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: ResponsiveUtils.spacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 13),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5F2D82),
          ),
        ),
      ),
    );
  }
}
