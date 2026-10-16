import 'dart:async';
import '../../../../../core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/utils/responsive_utils.dart';

/// Map pin picker for merchant restaurant location during registration.
class MerchantLocationPinPicker extends StatefulWidget {
  const MerchantLocationPinPicker({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationChanged,
    this.hasError = false,
    this.onAddressSelected,
  });

  final double? latitude;
  final double? longitude;
  final void Function(double latitude, double longitude) onLocationChanged;
  final bool hasError;
  final ValueChanged<String>? onAddressSelected;

  static const LatLng defaultCenter = LatLng(8.4542, 124.6319);

  @override
  State<MerchantLocationPinPicker> createState() =>
      _MerchantLocationPinPickerState();
}

class _MerchantLocationPinPickerState extends State<MerchantLocationPinPicker> {
  GoogleMapController? _mapController;
  late LatLng _pin;
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _searchVersion = 0;
  bool _searching = false;
  List<Map<String, dynamic>> _results = [];
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _search(String input) {
    _debounce?.cancel();
    final version = ++_searchVersion;
    setState(() { _results = []; _searchError = null; _searching = false; });
    if (input.trim().length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _searching = true);
      try {
        final response = await ApiService.dio.get('/v1/google-places/autocomplete',
          queryParameters: {'input': input.trim()});
        if (!mounted || version != _searchVersion) return;
        final data = response.data as Map;
        if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
          throw Exception('Search is unavailable. Try again or pin the map.');
        }
        setState(() {
          _results = (data['predictions'] as List? ?? [])
              .whereType<Map>().map((row) => Map<String, dynamic>.from(row)).take(5).toList();
          if (_results.isEmpty) _searchError = 'No places found. Try a nearby landmark.';
        });
      } catch (_) {
        if (mounted && version == _searchVersion) {
          setState(() => _searchError = 'Search is unavailable. Try again or pin the map.');
        }
      } finally {
        if (mounted && version == _searchVersion) setState(() => _searching = false);
      }
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    _debounce?.cancel();
    final version = ++_searchVersion;
    setState(() { _searching = true; _results = []; _searchError = null; });
    try {
      final response = await ApiService.dio.get('/v1/google-places/details',
        queryParameters: {'place_id': place['place_id']});
      if (!mounted || version != _searchVersion) return;
      final data = response.data as Map;
      final result = data['result'] as Map?;
      final location = result?['geometry']?['location'] as Map?;
      if (data['status'] != 'OK' || location == null) throw Exception('Missing location');
      final point = LatLng((location['lat'] as num).toDouble(), (location['lng'] as num).toDouble());
      final address = result?['formatted_address']?.toString() ?? place['description'].toString();
      setState(() { _pin = point; _searchController.text = address; });
      widget.onLocationChanged(point.latitude, point.longitude);
      widget.onAddressSelected?.call(address);
      FocusScope.of(context).unfocus();
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 17));
    } catch (_) {
      if (mounted && version == _searchVersion) {
        setState(() => _searchError = 'Could not load this place. Try another result.');
      }
    } finally {
      if (mounted && version == _searchVersion) setState(() => _searching = false);
    }
  }


  @override
  void initState() {
    super.initState();
    _pin = _initialPin();
  }

  LatLng _initialPin() {
    if (widget.latitude != null && widget.longitude != null) {
      return LatLng(widget.latitude!, widget.longitude!);
    }
    return MerchantLocationPinPicker.defaultCenter;
  }

  @override
  void didUpdateWidget(covariant MerchantLocationPinPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != null &&
        widget.longitude != null &&
        (widget.latitude != oldWidget.latitude ||
            widget.longitude != oldWidget.longitude)) {
      _pin = LatLng(widget.latitude!, widget.longitude!);
      _mapController?.animateCamera(CameraUpdate.newLatLng(_pin));
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Turn on location services to use your current position.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required to pin your restaurant.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _pin = location);
      widget.onLocationChanged(location.latitude, location.longitude);
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 16));
    } catch (e) {
      _showMessage('Could not get current location. Drag the pin instead.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = widget.latitude != null && widget.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _search,
          decoration: InputDecoration(
            hintText: 'Search place, street or landmark',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searching
                ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded),
                    onPressed: () { _searchController.clear(); _search(''); }),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (_searchError != null) Padding(padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(_searchError!, style: const TextStyle(fontSize: 12, color: Color(0xFF8A5260)))),
        ..._results.map((place) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined, color: Color(0xFF5F2D82)),
          title: Text(place['description']?.toString() ?? '', maxLines: 2,
            overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          onTap: () => _selectPlace(place),
        )),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Pin restaurant location on map',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _useCurrentLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Use my location'),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 280,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _pin, zoom: 15),
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (latLng) {
                    setState(() => _pin = latLng);
                    widget.onLocationChanged(latLng.latitude, latLng.longitude);
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    Marker(
                      markerId: const MarkerId('restaurant_pin'),
                      position: _pin,
                      draggable: true,
                      onDragEnd: (latLng) {
                        setState(() => _pin = latLng);
                        widget.onLocationChanged(
                          latLng.latitude,
                          latLng.longitude,
                        );
                      },
                    ),
                  },
                ),
                Positioned(right: 10, bottom: 16, child: Material(
                  color: Colors.white, elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(tooltip: 'Zoom in', icon: const Icon(Icons.add),
                      onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                    const SizedBox(width: 28, child: Divider(height: 1)),
                    IconButton(tooltip: 'Zoom out', icon: const Icon(Icons.remove),
                      onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                  ]),
                )),
                if (!hasPin)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.04),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Tap map or drag pin to set location',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.hasError) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Text(
            'Please pin your restaurant location on the map.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 12),
              color: Colors.red.shade700,
            ),
          ),
        ] else if (hasPin) ...[
          SizedBox(height: ResponsiveUtils.spacing(context, 6)),
          Text(
            'Pinned: ${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 11),
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}
