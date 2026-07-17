import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/services/api_service.dart';
import '../../provider/cart/cart_checkout_provider.dart';
import '../../provider/cart/cart_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';
    LatLng? pinLocation;
    String? pinAddress;

    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Details',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5F2D82),
                  ),
                ),
                const SizedBox(height: 16),

                // Pin location button
                InkWell(
                  onTap: () async {
                    final result = await _openMapPicker(context, pinLocation);
                    if (result != null) {
                      setState(() {
                        pinLocation = result['latLng'] as LatLng;
                        pinAddress = result['address'] as String?;
                        // Always update the address field with pinned location
                        if (pinAddress != null && pinAddress!.isNotEmpty) {
                          addressController.text = pinAddress!;
                        } else {
                          // Fallback to coordinates if geocoding failed
                          final lat = (result['latLng'] as LatLng).latitude.toStringAsFixed(5);
                          final lng = (result['latLng'] as LatLng).longitude.toStringAsFixed(5);
                          addressController.text = '$lat, $lng';
                        }
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: pinLocation != null
                            ? const Color(0xFF5F2D82)
                            : Colors.grey.shade300,
                        width: pinLocation != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: pinLocation != null
                          ? const Color(0xFF5F2D82).withOpacity(0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pinLocation != null
                              ? Icons.check_circle
                              : Icons.location_on_outlined,
                          color: pinLocation != null
                              ? const Color(0xFF5F2D82)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pinLocation != null
                                    ? '📍 Pin location set'
                                    : 'Pin exact location on map',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: pinLocation != null
                                      ? const Color(0xFF5F2D82)
                                      : Colors.black87,
                                ),
                              ),
                              if (pinAddress != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    pinAddress!,
                                    style: TextStyle(
                                      fontFamily: 'TT Fors',
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.map_outlined, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Manual address input
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Delivery address',
                    hintText: 'Street, Barangay, City',
                    prefixIcon: const Icon(Icons.home_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5F2D82)),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Additional notes (unit, floor, landmark)
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Unit / Floor / Landmark (optional)',
                    hintText: 'e.g. Unit 5B, 3rd Floor, near gate',
                    prefixIcon: const Icon(Icons.apartment_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF5F2D82)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Payment method
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment method',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'gcash', child: Text('GCash')),
                    DropdownMenuItem(value: 'wallet', child: Text('LesPay Wallet')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => paymentMethod = value);
                  },
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F2D82),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Place Order',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (proceed != true || !context.mounted) return;

    final address = addressController.text.trim();
    final notes = notesController.text.trim();
    final fullAddress = notes.isNotEmpty ? '$address ($notes)' : address;
    addressController.dispose();
    notesController.dispose();

    if (fullAddress.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a delivery address');
      return;
    }

    final success = await ref.read(cartCheckoutStateProvider.notifier).checkout(
          deliveryAddress: fullAddress,
          paymentMethod: paymentMethod,
          deliveryLat: pinLocation?.latitude,
          deliveryLng: pinLocation?.longitude,
        );

    if (!context.mounted) return;

    if (success) {
      final orderId = ref.read(cartCheckoutStateProvider).orderId;
      SnackBarUtils.showSuccess(
        context,
        orderId != null ? 'Order #$orderId placed successfully!' : 'Order placed successfully!',
      );
      Navigator.pop(context);
    } else {
      SnackBarUtils.showError(
        context,
        ref.read(cartCheckoutStateProvider).errorMessage ?? 'Checkout failed',
      );
    }
  }

  Future<Map<String, dynamic>?> _openMapPicker(BuildContext context, LatLng? initial) async {
    LatLng selectedLatLng = initial ?? const LatLng(18.6058, 121.0779); // Default: Claveria
    String? selectedAddress;
    bool isGeocoding = false;

    Future<String?> reverseGeocode(LatLng latLng) async {
      try {
        final apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
        if (apiKey.isEmpty) return null;
        final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey';
        final response = await ApiService.dio.get(url);
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['formatted_address'] as String?;
        }
      } catch (_) {}
      return null;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Pin Delivery Location',
                style: TextStyle(fontFamily: 'TT Fors', fontWeight: FontWeight.w700),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, {
                    'latLng': selectedLatLng,
                    'address': selectedAddress,
                  }),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5F2D82),
                    ),
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLatLng,
                    zoom: 16,
                  ),
                  onTap: (latLng) async {
                    setState(() {
                      selectedLatLng = latLng;
                      selectedAddress = 'Getting address...';
                      isGeocoding = true;
                    });
                    final addr = await reverseGeocode(latLng);
                    setState(() {
                      selectedAddress = addr ?? '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
                      isGeocoding = false;
                    });
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('delivery_pin'),
                      position: selectedLatLng,
                      draggable: true,
                      onDragEnd: (latLng) async {
                        setState(() {
                          selectedLatLng = latLng;
                          selectedAddress = 'Getting address...';
                          isGeocoding = true;
                        });
                        final addr = await reverseGeocode(latLng);
                        setState(() {
                          selectedAddress = addr ?? '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
                          isGeocoding = false;
                        });
                      },
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedAddress != null && selectedAddress!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF5F2D82), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedAddress!,
                                  style: const TextStyle(
                                    fontFamily: 'TT Fors',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isGeocoding)
                                const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ] else
                          Text(
                            '📍 Tap on the map or drag the pin to set delivery location',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final checkoutSummary = ref.watch(cartCheckoutProvider);
    final checkoutState = ref.watch(cartCheckoutStateProvider);
    final cartItems = cartState.items;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(
              showBackButton: true,
              backgroundColor: Colors.white,
              borderColor: Color(0xFFE8E8E8),
            ),
            if (cartItems.isEmpty)
              const Expanded(child: CartEmptyState())
            else
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context),
                    vertical: ResponsiveUtils.spacing(context, 12),
                  ),
                  child: SingleChildScrollView(
                    child: CartOrderSection(
                      items: cartItems,
                      onDecrease: (itemId) {
                        ref.read(cartProvider.notifier).decrementItemQuantity(itemId);
                      },
                      onIncrease: (itemId) {
                        ref.read(cartProvider.notifier).incrementItemQuantity(itemId);
                      },
                      onRemove: (itemId) {
                        ref.read(cartProvider.notifier).removeItem(itemId);
                      },
                      onAddMoreItems: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            if (cartItems.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.horizontalPadding(context),
                ),
                child: const CartVoucherCard(),
              ),
            if (cartItems.isNotEmpty)
              CartPriceSummary(
                subtotal: checkoutSummary.subtotal,
                deliveryFee: checkoutSummary.deliveryFee,
                itemCount: checkoutSummary.itemCount,
                total: checkoutSummary.total,
              ),
          ],
        ),
      ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.horizontalPadding(context),
                0,
                ResponsiveUtils.horizontalPadding(context),
                ResponsiveUtils.spacing(context, 18),
              ),
              child: PrimaryButton(
                text: checkoutState.isSubmitting ? 'Placing order...' : 'Checkout',
                isLoading: checkoutState.isSubmitting,
                onPressed: checkoutState.isSubmitting ? null : () => _checkout(context, ref),
              ),
            ),
    );
  }
}
