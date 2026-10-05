import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/booking/lesride_location_provider.dart';
import '../../../provider/main/booking/lesride_provider.dart';

class LesrideScreen extends ConsumerStatefulWidget {
  const LesrideScreen({super.key});

  @override
  ConsumerState<LesrideScreen> createState() => _LesrideScreenState();
}

class _LesrideScreenState extends ConsumerState<LesrideScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  LesrideNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notifier = ref.read(lesrideProvider.notifier);
        _notifier?.initialize();
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _notifier?.cleanup();
    super.dispose();
  }

  void _onMainMapCreated(GoogleMapController controller) {
    ref.read(lesrideProvider.notifier).setMapController(controller);
  }

  void _onOverlayMapCreated(GoogleMapController controller) {
    ref.read(lesrideProvider.notifier).setOverlayMapController(controller);
  }

  void _collapseSheet() {
    _notifier?.collapseSheet(_sheetController);
  }

  @override
  Widget build(BuildContext context) {
    final lesrideState = ref.watch(lesrideProvider);
    final notifier = ref.read(lesrideProvider.notifier);

    // Listen to location changes and handle route fetching
    ref.listen<LesrideLocationState>(lesrideLocationProvider, (previous, next) {
      notifier.handleLocationChange(previous, next);
    });

    return Scaffold(
      backgroundColor: AppColors.surface(context, Colors.white),
      appBar: lesrideState.isFullscreen
          ? null
          : const BookingServiceHeader(title: 'LesRide'),
      body: SafeArea(
        child: LesrideMainContent(
          sheetController: _sheetController,
          onMainMapCreated: _onMainMapCreated,
          onOverlayMapCreated: _onOverlayMapCreated,
          onCollapseSheet: _collapseSheet,
        ),
      ),
    );
  }
}
