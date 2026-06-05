import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/dto/geofence/geofence_dto.dart';
import '../../../../data/data_source/geofence_remote_datasource.dart';

class LestransportCoverageMap extends ConsumerStatefulWidget {
  const LestransportCoverageMap({super.key});

  @override
  ConsumerState<LestransportCoverageMap> createState() =>
      _LestransportCoverageMapState();
}

class _LestransportCoverageMapState
    extends ConsumerState<LestransportCoverageMap> {
  List<GeofenceDto> _geofences = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGeofences();
  }

  Future<void> _loadGeofences() async {
    try {
      final geofences = await getIt<GeofenceRemoteDataSource>().getGeofences();
      if (!mounted) return;
      setState(() {
        _geofences = geofences.where((g) => g.isActive).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Set<Circle> _buildCircles() {
    return _geofences.map((g) {
      return Circle(
        circleId: CircleId('geofence_${g.id}'),
        center: LatLng(g.latitude, g.longitude),
        radius: g.radiusKm * 1000,
        fillColor: const Color(0xFF5F2D82).withValues(alpha: 0.15),
        strokeColor: const Color(0xFF5F2D82),
        strokeWidth: 1,
      );
    }).toSet();
  }

  LatLng _mapCenter() {
    if (_geofences.isEmpty) {
      return const LatLng(14.5995, 120.9842);
    }
    final lat =
        _geofences.map((g) => g.latitude).reduce((a, b) => a + b) /
            _geofences.length;
    final lng =
        _geofences.map((g) => g.longitude).reduce((a, b) => a + b) /
            _geofences.length;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Area coverage of LesTransport',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.black87,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Container(
            width: double.infinity,
            height: ResponsiveUtils.imageHeight(context, 160),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F2D82),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: TextButton(
                            onPressed: _loadGeofences,
                            child: const Text('Retry loading coverage'),
                          ),
                        )
                      : kIsWeb
                          ? _CoverageList(geofences: _geofences)
                          : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _mapCenter(),
                                zoom: 10,
                              ),
                              circles: _buildCircles(),
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
            ),
          ),
          if (_geofences.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.spacing(context, 8),
              ),
              child: Text(
                '${_geofences.length} active service area(s)',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoverageList extends StatelessWidget {
  const _CoverageList({required this.geofences});

  final List<GeofenceDto> geofences;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: geofences.length,
      itemBuilder: (context, index) {
        final g = geofences[index];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.place, color: Color(0xFF5F2D82)),
          title: Text(
            g.name,
            style: const TextStyle(fontFamily: 'TT Fors', fontSize: 13),
          ),
          subtitle: Text(
            '${g.radiusKm} km radius',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        );
      },
    );
  }
}
