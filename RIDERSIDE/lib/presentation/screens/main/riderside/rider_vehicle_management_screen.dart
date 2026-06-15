import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/riderside/rider_vehicle_provider.dart';

IconData _vehicleIcon(VehicleType type) {
  switch (type) {
    case VehicleType.motorcycle:
      return Icons.motorcycle_outlined;
    case VehicleType.bicycle:
      return Icons.pedal_bike_outlined;
    case VehicleType.car:
      return Icons.directions_car_outlined;
    case VehicleType.scooter:
      return Icons.electric_scooter_outlined;
  }
}

class RiderVehicleManagementScreen extends ConsumerStatefulWidget {
  const RiderVehicleManagementScreen({super.key});

  @override
  ConsumerState<RiderVehicleManagementScreen> createState() =>
      _RiderVehicleManagementScreenState();
}

class _RiderVehicleManagementScreenState
    extends ConsumerState<RiderVehicleManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(riderVehicleProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5F2D82)),
        title: Text(
          'My Vehicles',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () =>
            ref.read(riderVehicleProvider.notifier).loadVehicles(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            hp,
            ResponsiveUtils.spacing(context, 16),
            hp,
            ResponsiveUtils.scrollBottomPaddingForBottomNav(context),
          ),
          children: [
            if (vehicleState.isLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (vehicleState.vehicles.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveUtils.spacing(context, 48),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_bike_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtils.spacing(context, 12)),
                      Text(
                        'No vehicles added yet',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize:
                              ResponsiveUtils.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...vehicleState.vehicles.map(
                  (vehicle) => _VehicleCard(
                    vehicle: vehicle,
                    onEdit: () => _showVehicleForm(context, vehicle: vehicle),
                    onDelete: () => _confirmDelete(vehicle),
                  ),
                ),
              SizedBox(height: ResponsiveUtils.spacing(context, 20)),
              SizedBox(
                width: double.infinity,
                height: ResponsiveUtils.buttonHeight(context),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showVehicleForm(context),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Vehicle',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize:
                          ResponsiveUtils.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(RiderVehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Remove Vehicle',
          style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to remove ${vehicle.makeModel} (${vehicle.plateNumber})?',
          style: const TextStyle(fontFamily: 'TT Fors'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: Colors.grey.shade700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(riderVehicleProvider.notifier)
                  .deleteVehicle(vehicle.id);
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                fontFamily: 'TT Fors',
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVehicleForm(BuildContext context, {RiderVehicle? vehicle}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VehicleFormScreen(
          existingVehicle: vehicle,
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final RiderVehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          bottom: ResponsiveUtils.spacing(context, 10)),
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveUtils.spacing(context, 48),
            height: ResponsiveUtils.spacing(context, 48),
            decoration: BoxDecoration(
              color: const Color(0xFF5F2D82).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _vehicleIcon(vehicle.type),
              color: const Color(0xFF5F2D82),
              size: ResponsiveUtils.fontSize(context, 24),
            ),
          ),
          SizedBox(width: ResponsiveUtils.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vehicle.type.label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveUtils.fontSize(context, 14),
                      ),
                    ),
                    if (vehicle.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F2D82),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize:
                                ResponsiveUtils.fontSize(context, 9),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(
                    height:
                        ResponsiveUtils.spacing(context, 4)),
                Text(
                  '${vehicle.makeModel} • ${vehicle.color}',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize:
                        ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  vehicle.plateNumber,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize:
                        ResponsiveUtils.fontSize(context, 12),
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: Color(0xFF5F2D82), size: 20),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleFormScreen extends ConsumerStatefulWidget {
  final RiderVehicle? existingVehicle;

  const _VehicleFormScreen({this.existingVehicle});

  @override
  ConsumerState<_VehicleFormScreen> createState() =>
      _VehicleFormScreenState();
}

class _VehicleFormScreenState
    extends ConsumerState<_VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _makeModelController;
  late final TextEditingController _colorController;
  late VehicleType _selectedType;
  bool _isSaving = false;

  bool get _isEditing => widget.existingVehicle != null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingVehicle?.type ?? VehicleType.motorcycle;
    _plateController =
        TextEditingController(text: widget.existingVehicle?.plateNumber ?? '');
    _makeModelController =
        TextEditingController(text: widget.existingVehicle?.makeModel ?? '');
    _colorController =
        TextEditingController(text: widget.existingVehicle?.color ?? '');
  }

  @override
  void dispose() {
    _plateController.dispose();
    _makeModelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final vehicle = RiderVehicle(
      id: widget.existingVehicle?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      plateNumber: _plateController.text.trim(),
      makeModel: _makeModelController.text.trim(),
      color: _colorController.text.trim(),
      isDefault: widget.existingVehicle?.isDefault ?? false,
    );

    bool success;
    if (_isEditing) {
      success = await ref
          .read(riderVehicleProvider.notifier)
          .updateVehicle(widget.existingVehicle!.id, vehicle);
    } else {
      success = await ref
          .read(riderVehicleProvider.notifier)
          .addVehicle(vehicle);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Vehicle updated successfully'
                  : 'Vehicle added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save vehicle'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF5F2D82)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5F2D82),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          hp,
          ResponsiveUtils.spacing(context, 24),
          hp,
          ResponsiveUtils.scrollBottomPaddingForKeyboard(context),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Type',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize:
                      ResponsiveUtils.fontSize(context, 13),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.spacing(context, 8)),
              DropdownButtonFormField<VehicleType>(
                value: _selectedType,
                items: VehicleType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_vehicleIcon(type),
                            size: 20,
                            color: const Color(0xFF5F2D82)),
                        const SizedBox(width: 10),
                        Text(
                          type.label,
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF5F2D82), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal:
                        ResponsiveUtils.spacing(context, 16),
                    vertical:
                        ResponsiveUtils.spacing(context, 14),
                  ),
                ),
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.spacing(context, 16)),
              _buildField(
                context,
                label: 'Plate Number',
                controller: _plateController,
                hint: 'e.g. ABC 1234',
                textCapitalization:
                    TextCapitalization.characters,
                validator: (v) {
                  if (_selectedType != VehicleType.bicycle &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Plate number is required';
                  }
                  return null;
                },
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.spacing(context, 16)),
              _buildField(
                context,
                label: 'Make & Model',
                controller: _makeModelController,
                hint: 'e.g. Honda Beat 2023',
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Make & model is required'
                        : null,
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.spacing(context, 16)),
              _buildField(
                context,
                label: 'Color',
                controller: _colorController,
                hint: 'e.g. Red',
                validator: (v) =>
                    v == null || v.trim().isEmpty
                        ? 'Color is required'
                        : null,
              ),
              SizedBox(
                  height:
                      ResponsiveUtils.spacing(context, 40)),
              SizedBox(
                width: double.infinity,
                height:
                    ResponsiveUtils.spacing(context, 52),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF5F2D82),
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                        )
                      : Text(
                          _isEditing
                              ? 'Save Changes'
                              : 'Add Vehicle',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(
                                context, 16),
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
