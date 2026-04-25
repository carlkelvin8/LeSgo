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

    // For now, disable search to avoid CORS issues
    // TODO: Implement proper Places API integration
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _showResults = false;
    });
    
    // Show a message that search is temporarily disabled
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search temporarily disabled. Please tap on the map to select location.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    _searchController.text = place['description'];
    setState(() {
      _showResults = false;
    });
    _focusNode.unfocus();

    // For now, disable place selection to avoid CORS issues
    // TODO: Implement proper Places API integration
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
              64,
            ), // Space for close button (40px button + 16px spacing + 8px gap)
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
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: EdgeInsets.only(
              left: ResponsiveUtils.spacing(context, 16),
              right: ResponsiveUtils.spacing(
                context,
                64,
              ), // Space for close button
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
