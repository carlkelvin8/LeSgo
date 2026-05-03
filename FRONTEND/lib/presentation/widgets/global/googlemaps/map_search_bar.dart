import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/responsive_utils.dart';

class MapSearchBar extends ConsumerStatefulWidget {
  final bool isSelectingDestination;
  final Function(
    LatLng location,
    String? formattedAddress,
    Map<String, String> addressComponents,
  )
  onPlaceSelected;
  final Future<void> Function(LatLng location)? onAnimateToLocation;

  const MapSearchBar({
    super.key,
    required this.isSelectingDestination,
    required this.onPlaceSelected,
    this.onAnimateToLocation,
  });

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      // Use backend proxy to avoid CORS issues
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/v1/google-places/autocomplete'
        '?input=${Uri.encodeComponent(query)}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          
          setState(() {
            _searchResults = predictions.map((prediction) {
              return {
                'place_id': prediction['place_id'],
                'description': prediction['description'],
                'main_text': prediction['structured_formatting']['main_text'],
                'secondary_text': prediction['structured_formatting']['secondary_text'],
              };
            }).toList();
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    _searchController.text = place['description'];
    setState(() {
      _showResults = false;
      _isSearching = true;
    });
    _focusNode.unfocus();

    try {
      // Get place details using backend proxy
      final placeId = place['place_id'];
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/v1/google-places/details'
        '?place_id=$placeId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          
          final latLng = LatLng(lat, lng);
          final formattedAddress = result['formatted_address'];
          
          // Parse address components
          final addressComponents = <String, String>{};
          final components = result['address_components'] as List;
          
          for (var component in components) {
            final types = component['types'] as List;
            final longName = component['long_name'];
            
            if (types.contains('street_number')) {
              addressComponents['street_number'] = longName;
            } else if (types.contains('route')) {
              addressComponents['route'] = longName;
            } else if (types.contains('locality')) {
              addressComponents['city'] = longName;
            } else if (types.contains('administrative_area_level_1')) {
              addressComponents['province'] = longName;
            } else if (types.contains('country')) {
              addressComponents['country'] = longName;
            } else if (types.contains('postal_code')) {
              addressComponents['postal_code'] = longName;
            } else if (types.contains('sublocality') || types.contains('sublocality_level_1')) {
              addressComponents['barangay'] = longName;
            }
          }
          
          // Animate to location if callback provided
          if (widget.onAnimateToLocation != null) {
            await widget.onAnimateToLocation!(latLng);
          }
          
          // Call the callback with location and address
          widget.onPlaceSelected(latLng, formattedAddress, addressComponents);
          
          setState(() {
            _isSearching = false;
          });
        } else {
          setState(() {
            _isSearching = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to get place details: ${data['status']}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isSearching = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get place details'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            left: ResponsiveUtils.spacing(context, 16),
            right: ResponsiveUtils.spacing(
              context,
              80, // Increased from 64 for better spacing with close button
            ),
          ),
          height: 40, // Match X button height exactly
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: IgnorePointer(
            ignoring: false, // Allow interactions with the search bar
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _searchPlaces,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search place',
                hintStyle: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  color: Colors.grey[600],
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F2D82)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _showResults = false;
                          });
                        },
                      )
                    : _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF5F2D82),
                            ),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                  vertical: 0,
                ),
                isDense: true,
              ),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 16),
                height: 1.0, // Remove extra line height
              ),
            ),
          ),
        ),
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(
              left: ResponsiveUtils.spacing(context, 16),
              right: ResponsiveUtils.spacing(
                context,
                80, // Match search bar margin
              ),
              top: ResponsiveUtils.spacing(context, 4),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
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
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFF5F2D82),
                  ),
                  title: Text(
                    place['main_text'],
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    place['secondary_text'],
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
      ],
    );
  }
}
