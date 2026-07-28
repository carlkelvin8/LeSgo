import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// Manual Order Item Model
class ManualOrderItem {
  final String id;
  final String name;
  final String description;
  final int quantity;

  ManualOrderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
  });

  ManualOrderItem copyWith({
    String? id,
    String? name,
    String? description,
    int? quantity,
  }) {
    return ManualOrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }
}

// Manual Order State
class ManualOrderState {
  final List<ManualOrderItem>
  items; // Items in "Your List" on Manual Order screen
  final List<ManualOrderItem> confirmedItems; // Items confirmed for checkout
  final bool isLoading;
  final String? error;
  final String? pickupLocationName; // Where rider should buy the items
  final double? pickupLat;
  final double? pickupLng;

  ManualOrderState({
    List<ManualOrderItem>? items,
    List<ManualOrderItem>? confirmedItems,
    this.isLoading = false,
    this.error,
    this.pickupLocationName,
    this.pickupLat,
    this.pickupLng,
  }) : items = items ?? [],
       confirmedItems = confirmedItems ?? [];

  bool get hasPickupLocation =>
      pickupLocationName != null &&
      pickupLocationName!.isNotEmpty &&
      pickupLat != null &&
      pickupLng != null;

  ManualOrderState copyWith({
    List<ManualOrderItem>? items,
    List<ManualOrderItem>? confirmedItems,
    bool? isLoading,
    String? error,
    String? pickupLocationName,
    double? pickupLat,
    double? pickupLng,
    bool clearPickupLocation = false,
  }) {
    return ManualOrderState(
      items: items ?? this.items,
      confirmedItems: confirmedItems ?? this.confirmedItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pickupLocationName: clearPickupLocation ? null : (pickupLocationName ?? this.pickupLocationName),
      pickupLat: clearPickupLocation ? null : (pickupLat ?? this.pickupLat),
      pickupLng: clearPickupLocation ? null : (pickupLng ?? this.pickupLng),
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get totalConfirmedItems =>
      confirmedItems.fold(0, (sum, item) => sum + item.quantity);
}

// Manual Order Notifier
class ManualOrderNotifier extends StateNotifier<ManualOrderState> {
  ManualOrderNotifier() : super(ManualOrderState());

  /// Set the pickup location where rider should buy the items
  void setPickupLocation(String name, double lat, double lng) {
    state = state.copyWith(
      pickupLocationName: name,
      pickupLat: lat,
      pickupLng: lng,
    );
  }

  void clearPickupLocation() {
    state = state.copyWith(clearPickupLocation: true);
  }

  final _uuid = const Uuid();

  void addItem(String name, String description, int quantity) {
    if (name.trim().isEmpty) return;

    final properName = name.trim();
    final properDesc = description.trim();
    final properQty = quantity > 0 ? quantity : 1;

    // Check if item already exists (case-insensitive name check)
    final existingItemIndex = state.items.indexWhere(
      (item) => item.name.toLowerCase() == properName.toLowerCase(),
    );

    if (existingItemIndex >= 0) {
      // Update quantity of existing item
      final updatedItems = List<ManualOrderItem>.from(state.items);
      final existingItem = updatedItems[existingItemIndex];

      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + properQty,
        description: properDesc.isNotEmpty
            ? properDesc
            : existingItem.description,
      );

      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = ManualOrderItem(
        id: _uuid.v4(),
        name: properName,
        description: properDesc,
        quantity: properQty,
      );

      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void incrementQuantity(String itemId) {
    final item = state.items.firstWhere((item) => item.id == itemId);
    updateQuantity(itemId, item.quantity + 1);
  }

  void decrementQuantity(String itemId) {
    final item = state.items.firstWhere((item) => item.id == itemId);
    updateQuantity(itemId, item.quantity - 1);
  }

  void removeItem(String itemId) {
    final updatedItems = state.items
        .where((item) => item.id != itemId)
        .toList();
    state = state.copyWith(items: updatedItems);
  }

  // Move all items from "Your List" to confirmed items for checkout
  // Move all items from "Your List" to confirmed items for checkout
  void confirmItems() {
    if (state.items.isEmpty) return;

    final currentConfirmed = List<ManualOrderItem>.from(state.confirmedItems);

    for (final newItem in state.items) {
      // Check if item already exists in confirmed list (case-insensitive)
      final existingIndex = currentConfirmed.indexWhere(
        (item) => item.name.toLowerCase() == newItem.name.toLowerCase(),
      );

      if (existingIndex >= 0) {
        // Merge quantity
        final existingItem = currentConfirmed[existingIndex];
        currentConfirmed[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + newItem.quantity,
          // Optionally update description if the new one is more detailed?
          // For now, keeping original unless we want to concat descriptions.
        );
      } else {
        // Add new item
        currentConfirmed.add(newItem);
      }
    }

    state = state.copyWith(
      confirmedItems: currentConfirmed,
      items: [], // Clear the pending list
    );
  }

  // Methods for confirmed items in checkout
  void incrementConfirmedQuantity(String itemId) {
    final item = state.confirmedItems.firstWhere((item) => item.id == itemId);
    final updatedItems = state.confirmedItems.map((i) {
      if (i.id == itemId) {
        return i.copyWith(quantity: item.quantity + 1);
      }
      return i;
    }).toList();
    state = state.copyWith(confirmedItems: updatedItems);
  }

  void decrementConfirmedQuantity(String itemId) {
    final item = state.confirmedItems.firstWhere((i) => i.id == itemId);
    if (item.quantity <= 1) {
      removeConfirmedItem(itemId);
      return;
    }
    final updatedItems = state.confirmedItems.map((i) {
      if (i.id == itemId) {
        return i.copyWith(quantity: item.quantity - 1);
      }
      return i;
    }).toList();
    state = state.copyWith(confirmedItems: updatedItems);
  }

  void removeConfirmedItem(String itemId) {
    final updatedItems = state.confirmedItems
        .where((item) => item.id != itemId)
        .toList();
    state = state.copyWith(confirmedItems: updatedItems);
  }

  void clearAll() {
    state = ManualOrderState();
  }

  void reset() {
    state = ManualOrderState();
  }
}

// Provider
final manualOrderProvider =
    StateNotifierProvider<ManualOrderNotifier, ManualOrderState>((ref) {
      return ManualOrderNotifier();
    });
