import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../widgets/widgets.dart';
import '../../../provider/main/booking/lesgo_location_provider.dart';
import '../../../provider/main/booking/lesgo_provider.dart';

class LesgoScreen extends ConsumerStatefulWidget {
  const LesgoScreen({super.key});

  @override
  ConsumerState<LesgoScreen> createState() => _LesgoScreenState();
}

class _LesgoScreenState extends ConsumerState<LesgoScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  LesgoNotifier? _notifier;

  // Item details controllers
  late final TextEditingController _itemLocationController;
  late final TextEditingController _itemWeightController;

  @override
  void initState() {
    super.initState();
    _itemLocationController = TextEditingController();
    _itemWeightController = TextEditingController();
    Future.microtask(() {
      _notifier = ref.read(lesgoProvider.notifier);
      _notifier?.initialize();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _itemLocationController.dispose();
    _itemWeightController.dispose();
    _notifier?.cleanup();
    super.dispose();
  }

  void _onMainMapCreated(GoogleMapController controller) {
    ref.read(lesgoProvider.notifier).setMapController(controller);
  }

  void _onOverlayMapCreated(GoogleMapController controller) {
    ref.read(lesgoProvider.notifier).setOverlayMapController(controller);
  }

  void _collapseSheet() {
    _notifier?.collapseSheet(_sheetController);
  }

  @override
  Widget build(BuildContext context) {
    final lesgoState = ref.watch(lesgoProvider);
    final notifier = ref.read(lesgoProvider.notifier);

    // Listen to location changes and handle route fetching
    ref.listen<LesgoLocationState>(lesgoLocationProvider, (previous, next) {
      notifier.handleLocationChange(previous, next);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: lesgoState.isFullscreen
          ? null
          : const BookingServiceHeader(
              title: 'LesGo',
              action: SizedBox.shrink(),
            ),
      body: SafeArea(
        child: LesgoMainContent(
          sheetController: _sheetController,
          onMainMapCreated: _onMainMapCreated,
          onOverlayMapCreated: _onOverlayMapCreated,
          onCollapseSheet: _collapseSheet,
          itemLocationController: _itemLocationController,
          itemWeightController: _itemWeightController,
        ),
      ),
    );
  }
}
