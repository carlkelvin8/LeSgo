import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/map_styles.dart';
import '../../../../../core/utils/booking_geo_utils.dart';
import '../../../../provider/main/address/address_provider.dart';
import '../../../../provider/main/booking/lesbuy/manual_order_provider.dart';
import '../../../global/googlemaps/map_search_bar.dart';

/// The buying location belongs to this order, not the delivery address book.
class ManualPickupSection extends ConsumerStatefulWidget {
  const ManualPickupSection({super.key});

  @override
  ConsumerState<ManualPickupSection> createState() =>
      _ManualPickupSectionState();
}

class _ManualPickupSectionState extends ConsumerState<ManualPickupSection> {
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(
      text: ref.read(manualOrderProvider).pickupLocationName ?? '',
    );
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(manualOrderProvider);
    ref.listen(
      manualOrderProvider.select((order) => order.pickupLocationName),
      (_, address) {
        final text = address ?? '';
        if (_address.text != text && _address.text.trim() != text.trim()) {
          _address.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
        }
      },
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where should the rider buy?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose the store where the rider will buy your items. This is the pickup point.',
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _address,
              keyboardType: TextInputType.streetAddress,
              minLines: 1,
              maxLines: 3,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Store / buying address',
                hintText: 'SM Fairview, Quirino Highway, Quezon City',
                border: OutlineInputBorder(),
              ),
              onChanged: ref
                  .read(manualOrderProvider.notifier)
                  .setPickupAddress,
            ),
            Text(
              order.hasPickupLocation
                  ? 'Pickup pin saved • ${order.pickupLat!.toStringAsFixed(6)}, ${order.pickupLng!.toStringAsFixed(6)}'
                  : 'Pin the store entrance so the rider knows exactly where to buy.',
              style: TextStyle(
                color: order.hasPickupLocation ? Colors.green : null,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                order.hasPickupLocation
                    ? 'Edit pickup pin'
                    : 'Pin pickup location',
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const ManualPickupScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ManualPickupScreen extends ConsumerStatefulWidget {
  const ManualPickupScreen({super.key});

  @override
  ConsumerState<ManualPickupScreen> createState() => _ManualPickupScreenState();
}

class _ManualPickupScreenState extends ConsumerState<ManualPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _address;
  late final LatLng _initialCenter;
  LatLng? _pin;
  GoogleMapController? _map;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    final order = ref.read(manualOrderProvider);
    _address = TextEditingController(text: order.pickupLocationName ?? '');
    if (order.hasPickupLocation) {
      _pin = LatLng(order.pickupLat!, order.pickupLng!);
    }
    final delivery = ref.read(addressProvider).deliveryAddress;
    // The delivery location is only a camera starting point, never a pickup.
    _initialCenter =
        _pin ??
        BookingGeoUtils.resolveCoords(
          lat: delivery?.latitude,
          lng: delivery?.longitude,
        );
  }

  @override
  void dispose() {
    _address.dispose();
    _map?.dispose();
    super.dispose();
  }

  void _selectPin(LatLng point) {
    setState(() {
      _pin = point;
      _pinError = null;
    });
  }

  void _save() {
    final validAddress = _formKey.currentState!.validate();
    final validPin = BookingGeoUtils.hasValidCoords(
      _pin?.latitude,
      _pin?.longitude,
    );
    setState(
      () => _pinError = validPin
          ? null
          : 'Tap the map to set the store pickup pin.',
    );
    if (!validAddress || !validPin) return;
    ref
        .read(manualOrderProvider.notifier)
        .setPickupLocation(
          _address.text.trim(),
          _pin!.latitude,
          _pin!.longitude,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Where should the rider buy?')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _address,
                  maxLines: 2,
                  maxLength: 255,
                  onChanged: (_) {
                    // An edited store address must not retain a different
                    // store's previously selected coordinates.
                    setState(() {
                      _pin = null;
                      _pinError = null;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Store / buying address',
                    hintText: 'SM Fairview, Quirino Highway, Quezon City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the address where the rider should buy.'
                      : value.trim().length > 255
                      ? 'Keep the address within 255 characters.'
                      : null,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Search for the store, then tap the map or drag the pin to its entrance.',
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    style: MapStyles.darkIfDark(context),
                    initialCameraPosition: CameraPosition(
                      target: _initialCenter,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) => _map = controller,
                    onTap: (point) {
                      FocusScope.of(context).unfocus();
                      _selectPin(point);
                    },
                    markers: {
                      if (_pin != null)
                        Marker(
                          markerId: const MarkerId('manual_store_pickup'),
                          position: _pin!,
                          draggable: true,
                          onDragEnd: _selectPin,
                          infoWindow: const InfoWindow(
                            title: 'Rider pickup point',
                          ),
                        ),
                    },
                    mapToolbarEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: MapSearchBar(
                      isSelectingDestination: false,
                      requirePreviewConfirmation: false,
                      showSavedAddresses: false,
                      onPlaceSelected: (point, address, components) {
                        if (!mounted) return;
                        _selectPin(point);
                        if (address != null && address.trim().isNotEmpty) {
                          _address.text = address;
                        }
                        _map?.animateCamera(
                          CameraUpdate.newLatLngZoom(point, 17),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_pinError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _pinError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save pickup point'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
