import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/partner_branch.dart';
import '../../../provider/main/merchantside/merchant_branches_provider.dart';
import '../../../widgets/register/merchant/info/merchant_location_pin_picker.dart';
import '../../../../core/utils/dark_aware_colors.dart';

const _purple = Color(0xFF5F2D82);

/// Add or edit a branch, including its pickup pin on the map.
class MerchantBranchFormScreen extends ConsumerStatefulWidget {
  final PartnerBranch? branch;

  const MerchantBranchFormScreen({super.key, this.branch});

  @override
  ConsumerState<MerchantBranchFormScreen> createState() =>
      _MerchantBranchFormScreenState();
}

class _MerchantBranchFormScreenState
    extends ConsumerState<MerchantBranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _region;
  late final TextEditingController _phone;
  double? _lat;
  double? _lng;
  bool _pinError = false;

  bool get _isEdit => widget.branch != null;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _name = TextEditingController(text: b?.name ?? '');
    _address = TextEditingController(text: b?.addressLine1 ?? '');
    _city = TextEditingController(text: b?.city ?? '');
    _region = TextEditingController(text: b?.region ?? '');
    _phone = TextEditingController(text: b?.phoneNumber ?? '');
    _lat = b?.latitude;
    _lng = b?.longitude;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _region.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _pinError = _lat == null || _lng == null);
    if (!valid || _pinError) return;

    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final error = await ref.read(merchantBranchesProvider.notifier).saveBranch(
          branchId: widget.branch?.id,
          body: {
            'name': _name.text.trim(),
            'address_line1': _address.text.trim(),
            'city': orNull(_city),
            'region': orNull(_region),
            'phone_number': orNull(_phone),
            'country': 'Philippines',
            'latitude': _lat,
            'longitude': _lng,
          },
        );
    if (!mounted) return;
    if (error == null) {
      SnackBarUtils.showSuccess(context, _isEdit ? 'Branch updated' : 'Branch added');
      Navigator.of(context).pop();
    } else {
      SnackBarUtils.showError(context, error);
    }
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(merchantBranchesProvider).isSaving;

    return Scaffold(
      backgroundColor: context.bg(Colors.white),
      appBar: AppBar(
        backgroundColor: context.surf(Colors.white),
        elevation: 0,
        iconTheme: IconThemeData(color: context.txt(Colors.black87)),
        title: Text(
          _isEdit ? 'Edit Branch' : 'Add Branch',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            color: context.txt(Colors.black87),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Branch name', hint: 'e.g. SM City Branch'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a branch name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Street address'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter the street address' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _city,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration('City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _region,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration('Province'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _decoration('Branch phone (optional)',
                    hint: 'Riders call this number at pickup'),
              ),
              const SizedBox(height: 16),
              MerchantLocationPinPicker(
                latitude: _lat,
                longitude: _lng,
                hasError: _pinError,
                onLocationChanged: (lat, lng) => setState(() {
                  _lat = lat;
                  _lng = lng;
                  _pinError = false;
                }),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: saving ? null : _save,
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Add branch'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
