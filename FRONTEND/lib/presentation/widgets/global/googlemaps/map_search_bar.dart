import 'package:lesgo/core/theme/app_colors.dart';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/map_recent_search_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/main/address/address_provider.dart';
import '../../../provider/main/location/location_provider.dart';
import 'map_place_preview_card.dart';

class MapSearchBar extends ConsumerStatefulWidget {
  final bool isSelectingDestination;
  final Function(
    LatLng location,
    String? formattedAddress,
    Map<String, String> addressComponents,
  )
  onPlaceSelected;
  final Future<void> Function(LatLng location)? onAnimateToLocation;
  final bool requirePreviewConfirmation;
  final bool showSavedAddresses;

  const MapSearchBar({
    super.key,
    required this.isSelectingDestination,
    required this.onPlaceSelected,
    this.onAnimateToLocation,
    this.requirePreviewConfirmation = true,
    this.showSavedAddresses = true,
  });

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _PendingPlacePreview {
  final LatLng location;
  final String? formattedAddress;
  final Map<String, String> addressComponents;
  final String title;
  final String? placeId;

  const _PendingPlacePreview({
    required this.location,
    required this.formattedAddress,
    required this.addressComponents,
    required this.title,
    this.placeId,
  });
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _searchResults = [];
  List<MapRecentPlace> _recentPlaces = [];
  Timer? _debounce;
  bool _isSearching = false;
  bool _showResults = false;
  String? _searchError;
  String _lastQuery = '';
  _PendingPlacePreview? _pendingPreview;

  static const _minQueryLength = 2;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _focusNode.addListener(_onFocusChanged);
    _loadRecent();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _searchController.text.trim().isEmpty) {
      _loadRecent();
      setState(() {
        _showResults = true;
        _searchError = null;
      });
    }
  }

  void _loadRecent() {
    if (getIt.isRegistered<MapRecentSearchService>()) {
      _recentPlaces = getIt<MapRecentSearchService>().getRecent();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  LatLng? _locationBias() {
    final locationState = ref.read(locationProvider);
    return locationState.selectedLocation ??
        locationState.currentLocation ??
        locationState.pickupLocation;
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.length < _minQueryLength) {
      setState(() {
        _lastQuery = trimmed;
        _searchResults.clear();
        _showResults = trimmed.isNotEmpty || _focusNode.hasFocus;
        _searchError = trimmed.isEmpty
            ? null
            : 'Type at least $_minQueryLength characters to search';
        _isSearching = false;
        _pendingPreview = null;
      });
      if (trimmed.isEmpty && _focusNode.hasFocus) _loadRecent();
      return;
    }

    setState(() {
      _lastQuery = trimmed;
      _isSearching = true;
      _showResults = true;
      _searchError = null;
      _pendingPreview = null;
    });

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(trimmed);
    });
  }

  Future<void> _searchPlaces(String query) async {
    try {
      final bias = _locationBias();
      final params = <String, dynamic>{
        'input': query,
        'components': 'country:ph',
      };
      if (bias != null) {
        params['location'] = '${bias.latitude},${bias.longitude}';
        params['radius'] = 50000;
      }

      final dio = getIt<DioClient>().dio;
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/google-places/autocomplete',
        queryParameters: params,
      );

      final data = _unwrapPlacesPayload(response.data);
      final status = data['status']?.toString() ?? '';
      final predictions = data['predictions'];

      if (status == 'OK' && predictions is List) {
        final results = <Map<String, dynamic>>[];
        for (final item in predictions) {
          if (item is! Map) continue;
          final parsed = _parsePrediction(item);
          if (parsed != null) results.add(parsed);
        }

        if (!mounted) return;
        setState(() {
          _searchResults
            ..clear()
            ..addAll(results);
          _isSearching = false;
          _searchError =
              results.isEmpty ? 'No places found. Try a different search.' : null;
        });
        return;
      }

      if (status == 'ZERO_RESULTS') {
        if (!mounted) return;
        setState(() {
          _searchResults.clear();
          _isSearching = false;
          _searchError = 'No places found. Try a different search.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _searchError = 'Place search unavailable ($status).';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _searchError = 'Could not search places. Check your connection.';
      });
      debugPrint('MapSearchBar autocomplete error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _searchError = 'Could not search places. Please try again.';
      });
      debugPrint('MapSearchBar autocomplete error: $e');
    }
  }

  Map<String, dynamic> _unwrapPlacesPayload(Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  Map<String, dynamic>? _parsePrediction(Map item) {
    final map = Map<String, dynamic>.from(item);
    final placeId = map['place_id']?.toString();
    final description = map['description']?.toString();
    if (placeId == null || placeId.isEmpty || description == null) {
      return null;
    }

    final formatting = map['structured_formatting'];
    String mainText = description;
    String secondaryText = '';
    if (formatting is Map) {
      mainText = formatting['main_text']?.toString() ?? mainText;
      secondaryText = formatting['secondary_text']?.toString() ?? '';
    }

    return {
      'place_id': placeId,
      'description': description,
      'main_text': mainText,
      'secondary_text': secondaryText,
    };
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    _searchController.text = place['description']?.toString() ?? '';
    setState(() {
      _showResults = false;
      _isSearching = true;
      _searchError = null;
    });
    _focusNode.unfocus();

    try {
      final placeId = place['place_id']?.toString();
      if (placeId == null || placeId.isEmpty) {
        throw Exception('Missing place id');
      }

      final dio = getIt<DioClient>().dio;
      final response = await dio.get<Map<String, dynamic>>(
        '/v1/google-places/details',
        queryParameters: {'place_id': placeId},
      );

      final data = _unwrapPlacesPayload(response.data);
      final status = data['status']?.toString() ?? '';
      final result = data['result'];

      if (status != 'OK' || result is! Map) {
        throw Exception(status.isEmpty ? 'Invalid place details' : status);
      }

      final geometry = result['geometry'];
      if (geometry is! Map) throw Exception('Missing geometry');

      final location = geometry['location'];
      if (location is! Map) throw Exception('Missing coordinates');

      final lat = _parseDouble(location['lat']);
      final lng = _parseDouble(location['lng']);
      if (lat == null || lng == null) throw Exception('Invalid coordinates');

      final latLng = LatLng(lat, lng);
      final formattedAddress = result['formatted_address']?.toString();
      final addressComponents =
          _parseAddressComponents(result['address_components']);
      final title = place['main_text']?.toString() ??
          formattedAddress ??
          'Selected place';

      if (widget.onAnimateToLocation != null) {
        await widget.onAnimateToLocation!(latLng);
      }

      if (widget.requirePreviewConfirmation) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _pendingPreview = _PendingPlacePreview(
            location: latLng,
            formattedAddress: formattedAddress,
            addressComponents: addressComponents,
            title: title,
            placeId: placeId,
          );
        });
        return;
      }

      await _confirmPlace(
        latLng: latLng,
        formattedAddress: formattedAddress,
        addressComponents: addressComponents,
        placeId: placeId,
        description: place['description']?.toString() ?? title,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Failed to load place details. Please try again.';
      });
      debugPrint('MapSearchBar details error: $e');
    }
  }

  Future<void> _selectSavedAddress({
    required String label,
    required String addressLine,
    required double lat,
    required double lng,
  }) async {
    final latLng = LatLng(lat, lng);
    _searchController.text = addressLine;
    setState(() {
      _showResults = false;
      _pendingPreview = null;
    });
    _focusNode.unfocus();

    if (widget.onAnimateToLocation != null) {
      await widget.onAnimateToLocation!(latLng);
    }

    await _confirmPlace(
      latLng: latLng,
      formattedAddress: addressLine,
      addressComponents: {},
      description: '$label — $addressLine',
    );
  }

  Future<void> _selectRecent(MapRecentPlace place) async {
    _searchController.text = place.description;
    setState(() {
      _showResults = false;
      _pendingPreview = null;
    });
    _focusNode.unfocus();

    final latLng = LatLng(place.latitude, place.longitude);
    if (widget.onAnimateToLocation != null) {
      await widget.onAnimateToLocation!(latLng);
    }

    await _confirmPlace(
      latLng: latLng,
      formattedAddress: place.description,
      addressComponents: {},
      placeId: place.placeId,
      description: place.description,
    );
  }

  Future<void> _confirmPlace({
    required LatLng latLng,
    required String? formattedAddress,
    required Map<String, String> addressComponents,
    String? placeId,
    required String description,
  }) async {
    if (getIt.isRegistered<MapRecentSearchService>() &&
        placeId != null &&
        placeId.isNotEmpty) {
      await getIt<MapRecentSearchService>().addRecent(
        MapRecentPlace(
          placeId: placeId,
          description: description,
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        ),
      );
      _loadRecent();
    }

    widget.onPlaceSelected(latLng, formattedAddress, addressComponents);

    if (!mounted) return;
    setState(() {
      _isSearching = false;
      _pendingPreview = null;
    });
  }

  Map<String, String> _parseAddressComponents(dynamic raw) {
    final addressComponents = <String, String>{};
    if (raw is! List) return addressComponents;

    for (final component in raw) {
      if (component is! Map) continue;
      final types = component['types'];
      final longName = component['long_name']?.toString();
      if (types is! List || longName == null || longName.isEmpty) continue;

      if (types.contains('street_number')) {
        addressComponents['street_number'] = longName;
        addressComponents['houseNumber'] = longName;
      } else if (types.contains('route')) {
        addressComponents['route'] = longName;
        addressComponents['streetName'] = longName;
      } else if (types.contains('locality')) {
        addressComponents['city'] = longName;
      } else if (types.contains('administrative_area_level_1')) {
        addressComponents['province'] = longName;
      } else if (types.contains('country')) {
        addressComponents['country'] = longName;
      } else if (types.contains('postal_code')) {
        addressComponents['postal_code'] = longName;
      } else if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        addressComponents['barangay'] = longName;
      }
    }

    return addressComponents;
  }

  double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  List<Widget> _buildQuickPickList() {
    final items = <Widget>[];
    final addressState = ref.watch(addressProvider);
    final saved = addressState.addresses
        .where((a) => widget.showSavedAddresses && a.latitude != 0 && a.longitude != 0)
        .take(5)
        .toList();

    if (_recentPlaces.isNotEmpty) {
      items.add(_sectionHeader('Recent searches'));
      for (final place in _recentPlaces) {
        items.add(_quickTile(
          icon: Icons.history,
          title: place.description,
          onTap: () => _selectRecent(place),
        ));
      }
    }

    if (saved.isNotEmpty) {
      items.add(_sectionHeader('Saved addresses'));
      for (final addr in saved) {
        items.add(_quickTile(
          icon: Icons.bookmark,
          title: addr.label,
          subtitle: addr.addressLine1,
          onTap: () => _selectSavedAddress(
            label: addr.label,
            addressLine: addr.addressLine1,
            lat: addr.latitude,
            lng: addr.longitude,
          ),
        ));
      }
    }

    if (items.isEmpty) {
      items.add(
        Padding(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
          child: Text(
            'Search for a place or use your current location',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: AppColors.foreground(context, Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return items;
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.spacing(context, 12),
        ResponsiveUtils.spacing(context, 8),
        ResponsiveUtils.spacing(context, 12),
        ResponsiveUtils.spacing(context, 4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 12),
          fontWeight: FontWeight.w700,
          color: AppColors.foreground(context, Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _quickTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.accent(context, Color(0xFF5F2D82))),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 15),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 13),
                color: AppColors.foreground(context, Colors.grey.shade600),
              ),
            ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showQuickPicks =
        _showResults && _searchResults.isEmpty && _lastQuery.length < _minQueryLength;

    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              left: ResponsiveUtils.spacing(context, 16),
              right: ResponsiveUtils.spacing(context, 80),
            ),
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface(context, Colors.white),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onQueryChanged,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search place',
                hintStyle: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  color: AppColors.foreground(context, Colors.grey[600]!),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F2D82)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon:  Icon(Icons.clear, color: AppColors.foreground(context, Colors.grey)),
                        onPressed: () {
                          _debounce?.cancel();
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                            _showResults = _focusNode.hasFocus;
                            _searchError = null;
                            _isSearching = false;
                            _lastQuery = '';
                            _pendingPreview = null;
                          });
                          if (_focusNode.hasFocus) _loadRecent();
                        },
                      )
                    : _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5F2D82),
                              ),
                            ),
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                ),
                isDense: true,
              ),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                height: 1,
              ),
            ),
          ),
          if (showQuickPicks)
            Container(
              margin: EdgeInsets.only(
                left: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 80),
                top: ResponsiveUtils.spacing(context, 4),
              ),
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: ResponsiveUtils.screenHeight(context) * 0.4,
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: _buildQuickPickList(),
              ),
            ),
          if (_showResults && _searchResults.isNotEmpty)
            Container(
              margin: EdgeInsets.only(
                left: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 80),
                top: ResponsiveUtils.spacing(context, 4),
              ),
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: ResponsiveUtils.screenHeight(context) * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: AppColors.border(context, Colors.grey[200]!)),
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFF5F2D82),
                    ),
                    title: Text(
                      place['main_text']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      place['secondary_text']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 14),
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            ),
          if (_showResults &&
              !_isSearching &&
              _searchResults.isEmpty &&
              _searchError != null &&
              _lastQuery.length >= _minQueryLength)
            Container(
              margin: EdgeInsets.only(
                left: ResponsiveUtils.spacing(context, 16),
                right: ResponsiveUtils.spacing(context, 80),
                top: ResponsiveUtils.spacing(context, 4),
              ),
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 12)),
              decoration: BoxDecoration(
                color: AppColors.surface(context, Colors.white),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _searchError!,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 13),
                  color: AppColors.foreground(context, Colors.grey.shade700),
                ),
              ),
            ),
          if (_pendingPreview != null)
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.spacing(context, 8),
              ),
              child: MapPlacePreviewCard(
                title: _pendingPreview!.title,
                subtitle: _pendingPreview!.formattedAddress,
                isLoading: _isSearching,
                onCancel: () => setState(() => _pendingPreview = null),
                onConfirm: () async {
                  final preview = _pendingPreview!;
                  setState(() => _isSearching = true);
                  await _confirmPlace(
                    latLng: preview.location,
                    formattedAddress: preview.formattedAddress,
                    addressComponents: preview.addressComponents,
                    placeId: preview.placeId,
                    description: preview.title,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
