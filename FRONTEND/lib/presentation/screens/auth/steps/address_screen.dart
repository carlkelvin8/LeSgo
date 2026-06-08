import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../provider/register/controller/address.controller.notifier.dart';
import '../../../provider/register/register_provider.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/constants/routers/register/register_routes.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../widgets/widgets.dart';

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  late final AddressControllers _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = AddressControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllers.initialize(ref);
    });
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(
                    ResponsiveUtils.horizontalPadding(context),
                  ),
                  child: const AuthHeader(title: 'SIGN UP'),
                ),
                AddressMapPanel(
                  controllers: _controllers,
                  ref: ref,
                  onToggleFullscreen: () => setState(() {}),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                AddressFormPanel(
                  controllers: _controllers,
                  registerState: registerState,
                  onDefaultChanged: (value) {
                    ref
                        .read(registerProvider.notifier)
                        .updateAddress(isDefault: value ?? false);
                  },
                ),
              ],
            ),
            AddressContinueBar(
              isLoading: registerState.isLoading,
              onPressed: () async {
                if (!context.mounted) return;
                final success = await _controllers.validateAndSaveAddress(
                  context,
                  ref,
                );
                if (success && context.mounted) {
                  final registered = await ref
                      .read(registerProvider.notifier)
                      .submitRegistration();
                  if (!context.mounted) return;
                  if (registered) {
                    AppRouter.push(context, RegisterRoutes.success);
                  } else {
                    final error = ref.read(registerProvider).error;
                    if (error != null) {
                      SnackBarUtils.showError(context, error);
                    }
                  }
                }
              },
            ),
            if (_controllers.isFullscreen &&
                registerState.selectedLocation != null)
              FullscreenMapOverlay(
                onMapCreated: _controllers.onFullscreenMapCreated,
                onUseCurrentLocation: () =>
                    _controllers.handleUseCurrentLocation(context, ref),
                onToggleFullscreen: () {
                  _controllers.toggleFullscreen(ref);
                  setState(() {});
                },
                onMapTap: (location) =>
                    _controllers.handleMapTap(location, ref, context),
                showSearchBar: true,
                onPlaceSelected: (latLng, formattedAddress, addressComponents) async {
                  await ref
                      .read(registerProvider.notifier)
                      .updateSelectedLocationWithAddress(
                        latLng,
                        formattedAddress,
                        addressComponents,
                      );
                  _controllers.updateFormFromProvider(ref);
                },
                onAnimateToLocation: (location) =>
                    _controllers.animateOverlayToLocation(location),
              ),
          ],
        ),
      ),
    );
  }
}
