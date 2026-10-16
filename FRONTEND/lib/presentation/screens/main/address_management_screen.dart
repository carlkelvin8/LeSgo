import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/utils/booking_geo_utils.dart';
import '../../../data/data_source/dto/address/address_dto.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/main/address/address_provider.dart';
import '../../widgets/widgets.dart';

class AddressManagementScreen extends ConsumerStatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  ConsumerState<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState
    extends ConsumerState<AddressManagementScreen> {
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      _userId = int.tryParse(authState.user?.id ?? '0') ?? 0;
      if (_userId > 0) {
        ref.read(addressProvider.notifier).loadAddresses(_userId);
      }
    });
  }

  void _showAddEditSheet({AddressDto? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context, Colors.white),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _AddEditAddressSheet(userId: _userId, existing: existing),
      ),
    );
  }

  Future<void> _deleteAddress(AddressDto address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Address',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove "${address.label}" from your saved addresses?',
          style: const TextStyle(fontFamily: 'TT Fors'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: AppColors.foreground(context, Colors.grey),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'TT Fors', color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(addressProvider.notifier)
          .deleteAddress(
            userId: _userId,
            addressId: address.id,
            context: context,
          );
    }
  }

  Future<void> _setDefault(AddressDto address) async {
    if (address.isDefault) return;
    await ref
        .read(addressProvider.notifier)
        .setAsDefault(userId: _userId, addressId: address.id, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.grey[50]!),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.surface(context, Colors.white),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const AuthHeader(title: 'Saved Addresses'),
            ),
            Container(
              height: 1,
              color: AppColors.surface(context, Colors.grey[200]!),
            ),

            Expanded(
              child: addressState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2D82),
                      ),
                    )
                  : addressState.addresses.isEmpty
                  ? _EmptyState(onAdd: () => _showAddEditSheet())
                  : RefreshIndicator(
                      color: AppColors.accent(context, Color(0xFF5F2D82)),
                      onRefresh: () => ref
                          .read(addressProvider.notifier)
                          .loadAddresses(_userId),
                      child: ListView.separated(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.spacing(context, 16),
                        ),
                        itemCount: addressState.addresses.length,
                        separatorBuilder: (_, __) => SizedBox(
                          height: ResponsiveUtils.spacing(context, 10),
                        ),
                        itemBuilder: (_, i) {
                          final addr = addressState.addresses[i];
                          return _AddressTile(
                            address: addr,
                            onEdit: () => _showAddEditSheet(existing: addr),
                            onDelete: () => _deleteAddress(addr),
                            onSetDefault: () => _setDefault(addr),
                            isSettingDefault: addressState.isUpdating,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        backgroundColor: const Color(0xFF5F2D82),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Address',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address Tile
// ─────────────────────────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  final AddressDto address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final bool isSettingDefault;

  const _AddressTile({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.isSettingDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isDefault
              ? AppColors.accent(
                  context,
                  Color(0xFF5F2D82),
                ).withValues(alpha: 0.4)
              : AppColors.border(context, Colors.grey.shade200),
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: address.isDefault
                      ? AppColors.accent(context, Color(0xFF5F2D82))
                      : AppColors.surface(context, Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  address.label,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: address.isDefault
                        ? Colors.white
                        : AppColors.foreground(context, Colors.grey.shade700),
                  ),
                ),
              ),
              if (address.isDefault) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Default',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 10,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Actions
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.foreground(context, Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red.shade400,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Address line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.foreground(context, Colors.grey.shade500),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.addressLine1,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 13,
                    color: AppColors.foreground(context, Colors.black87),
                  ),
                ),
              ),
            ],
          ),

          // Contact
          if (address.contactName?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.foreground(context, Colors.grey.shade400),
                ),
                const SizedBox(width: 6),
                Text(
                  '${address.contactName ?? ''} · ${address.contactPhone ?? ''}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12,
                    color: AppColors.foreground(context, Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ],

          // Set as default button
          if (!address.isDefault) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: isSettingDefault ? null : onSetDefault,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent(context, Color(0xFF5F2D82)),
                disabledForegroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 8),
                  vertical: 6,
                ),
                minimumSize: const Size(48, 44),
                visualDensity: VisualDensity.compact,
                textStyle: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF5F2D82),
                ),
              ),
              child: const Text('Set as default'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 64,
            color: AppColors.foreground(context, Colors.grey[300]!),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 16,
              color: AppColors.foreground(context, Colors.grey[600]!),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an address to speed up checkout',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: AppColors.foreground(context, Colors.grey[400]!),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Add Address',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Address Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddEditAddressSheet extends ConsumerStatefulWidget {
  final int userId;
  final AddressDto? existing;

  const _AddEditAddressSheet({required this.userId, this.existing});

  @override
  ConsumerState<_AddEditAddressSheet> createState() =>
      _AddEditAddressSheetState();
}

class _AddEditAddressSheetState extends ConsumerState<_AddEditAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _contactNameCtrl;
  late final TextEditingController _contactPhoneCtrl;
  late final TextEditingController _addressLine1Ctrl;
  late final TextEditingController _addressLine2Ctrl;
  bool _isDefault = false;
  bool _isSaving = false;
  LatLng? _selectedLocation;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _contactNameCtrl = TextEditingController(text: e?.contactName ?? '');
    _contactPhoneCtrl = TextEditingController(text: e?.contactPhone ?? '');
    _addressLine1Ctrl = TextEditingController(text: e?.addressLine1 ?? '');
    _addressLine2Ctrl = TextEditingController(text: e?.addressLine2 ?? '');
    _isDefault = e?.isDefault ?? false;
    if (BookingGeoUtils.hasValidCoords(e?.latitude, e?.longitude)) {
      _selectedLocation = LatLng(e!.latitude, e.longitude);
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap the map to pin this address location.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    bool success;
    if (_isEditing) {
      success = await ref
          .read(addressProvider.notifier)
          .updateAddress(
            userId: widget.userId,
            addressId: widget.existing!.id,
            label: _labelCtrl.text.trim(),
            contactName: _contactNameCtrl.text.trim(),
            contactPhone: _contactPhoneCtrl.text.trim(),
            addressLine1: _addressLine1Ctrl.text.trim(),
            addressLine2: _addressLine2Ctrl.text.trim().isEmpty
                ? null
                : _addressLine2Ctrl.text.trim(),
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            isDefault: _isDefault,
            context: context,
          );
    } else {
      success = await ref
          .read(addressProvider.notifier)
          .createAddress(
            userId: widget.userId,
            label: _labelCtrl.text.trim(),
            contactName: _contactNameCtrl.text.trim(),
            contactPhone: _contactPhoneCtrl.text.trim(),
            addressLine1: _addressLine1Ctrl.text.trim(),
            addressLine2: _addressLine2Ctrl.text.trim().isEmpty
                ? null
                : _addressLine2Ctrl.text.trim(),
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            isDefault: _isDefault,
            context: context,
          );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.grey[300]!),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Edit Address' : 'Add New Address',
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pin the exact delivery location',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground(context, Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 190,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target:
                                  _selectedLocation ??
                                  BookingGeoUtils.defaultLatLng,
                              zoom: 15,
                            ),
                            myLocationButtonEnabled: false,
                            myLocationEnabled: false,
                            onTap: (location) =>
                                setState(() => _selectedLocation = location),
                            markers: _selectedLocation == null
                                ? const <Marker>{}
                                : {
                                    Marker(
                                      markerId: const MarkerId('saved_address'),
                                      position: _selectedLocation!,
                                    ),
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedLocation == null
                            ? 'Tap the map to select a pin.'
                            : 'Pinned: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: AppColors.foreground(
                            context,
                            Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        controller: _labelCtrl,
                        label: 'Label',
                        hint: 'e.g. Home, Office, School',
                        icon: Icons.label_outline,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _addressLine1Ctrl,
                        label: 'Address',
                        hint: 'Street, Barangay, City',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _addressLine2Ctrl,
                        label: 'Address Line 2 (optional)',
                        hint: 'Unit, Floor, Building',
                        icon: Icons.apartment_outlined,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _contactNameCtrl,
                        label: 'Contact Name',
                        hint: 'Full name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _contactPhoneCtrl,
                        label: 'Contact Phone',
                        hint: '+63 9XX XXX XXXX',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Set as default toggle
                      GestureDetector(
                        onTap: () => setState(() => _isDefault = !_isDefault),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _isDefault
                                      ? AppColors.accent(
                                          context,
                                          Color(0xFF5F2D82),
                                        )
                                      : AppColors.surface(
                                          context,
                                          Colors.white,
                                        ),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _isDefault
                                        ? AppColors.accent(
                                            context,
                                            Color(0xFF5F2D82),
                                          )
                                        : AppColors.border(
                                            context,
                                            Colors.grey.shade400,
                                          ),
                                    width: 1.5,
                                  ),
                                ),
                                child: _isDefault
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Set as default address',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14,
                                  color: AppColors.foreground(
                                    context,
                                    Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F2D82),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'Save Changes' : 'Add Address',
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form field
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground(context, Colors.black54),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontFamily: 'TT Fors', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 13,
              color: AppColors.foreground(context, Colors.grey[400]!),
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: AppColors.foreground(context, Colors.grey[500]!),
            ),
            filled: true,
            fillColor: AppColors.surface(context, Colors.grey[50]!),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.border(context, Colors.grey.shade300),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.border(context, Colors.grey.shade300),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF5F2D82),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
