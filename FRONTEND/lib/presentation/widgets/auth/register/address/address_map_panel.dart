import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../provider/register/controller/address.controller.notifier.dart';
import 'address_map_section.dart';

class AddressMapPanel extends StatelessWidget {
  const AddressMapPanel({
    super.key,
    required this.controllers,
    required this.ref,
    required this.onToggleFullscreen,
  });

  final AddressControllers controllers;
  final WidgetRef ref;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    return AddressMapSection(
      key: ValueKey(controllers.isFullscreen),
      mapController: controllers.mapController,
      onMapCreated: (controller) {
        controllers.onMapCreated(controller);
        Future.delayed(const Duration(milliseconds: 50), () {
          controllers.moveSmallMapToMarker(ref);
        });
      },
      onUseCurrentLocation: () =>
          controllers.handleUseCurrentLocation(context, ref),
      onToggleFullscreen: () {
        controllers.toggleFullscreen(ref);
        onToggleFullscreen();
      },
      onMapTap: (location) => controllers.handleMapTap(location, ref, context),
    );
  }
}
