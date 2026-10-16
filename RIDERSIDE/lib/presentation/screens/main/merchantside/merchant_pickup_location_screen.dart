import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../widgets/register/merchant/info/merchant_location_pin_picker.dart';

class MerchantPickupLocationScreen extends ConsumerStatefulWidget {
  const MerchantPickupLocationScreen({super.key});
  @override
  ConsumerState<MerchantPickupLocationScreen> createState() => _PickupState();
}

class _PickupState extends ConsumerState<MerchantPickupLocationScreen> {
  final _address = TextEditingController();
  double? _lat;
  double? _lng;
  int? _branchId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final partner = await ref.read(merchantProfileProvider.future);
      if (partner == null) throw Exception('Merchant profile is unavailable');
      final response = await ApiService.dio.get('/v1/partners/${partner.id}/branches');
      final rows = response.data['data'] as List;
      if (!mounted) return;
      if (rows.isNotEmpty) {
        final branch = rows.firstWhere((row) => row['is_primary'] == true || row['is_primary'] == 1,
            orElse: () => rows.first) as Map;
        _branchId = (branch['id'] as num).toInt();
        _address.text = branch['address_line1']?.toString() ?? '';
        _lat = double.tryParse('${branch['latitude']}');
        _lng = double.tryParse('${branch['longitude']}');
      }
    } catch (e) {
      if (mounted) _error = ApiService.extractError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving || _lat == null || _lng == null || _address.text.trim().isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      final partner = await ref.read(merchantProfileProvider.future);
      if (partner == null) throw Exception('Merchant profile is unavailable');
      final data = {
        'name': partner.name,
        'address_line1': _address.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'is_primary': true,
      };
      if (_branchId == null) {
        await ApiService.dio.post('/v1/partners/${partner.id}/branches', data: data);
      } else {
        await ApiService.dio.patch('/v1/branches/$_branchId', data: data);
      }
      ref.invalidate(merchantProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup location saved')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiService.extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _address.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(title: const Text('Store pickup location')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Pin the exact entrance where riders collect orders.',
          style: TextStyle(fontSize: 14)),
        const SizedBox(height: 20),
        TextField(controller: _address, maxLength: 255,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Store address',
            hintText: 'Building, street and barangay', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        MerchantLocationPinPicker(latitude: _lat, longitude: _lng,
          onLocationChanged: (lat, lng) => setState(() { _lat = lat; _lng = lng; })),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_error!, style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving || _lat == null || _lng == null || _address.text.trim().isEmpty
            ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save pickup location')),
      ],
    ),
  );
}
