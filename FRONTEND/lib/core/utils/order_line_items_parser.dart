import '../../data/data_source/dto/order/lesbuy_item_dto.dart';
import '../../data/data_source/dto/order/order_dto.dart';

class OrderLineItem {
  final String name;
  final double price;
  final int quantity;

  const OrderLineItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}

/// Parses order line items from API payloads without placeholder names.
class OrderLineItemsParser {
  OrderLineItemsParser._();

  static List<OrderLineItem> fromOrderDto(OrderDto order) {
    final dtoItems = order.effectiveItems;
    if (dtoItems.isNotEmpty) {
      return dtoItems.map(_fromLesbuyItem).toList();
    }

    return fromOrderDataMap({
      'lesbuy_items': order.lesbuyItems?.map((e) => e.toJson()).toList(),
      'items': order.meta?['items'] ?? order.meta?['order_items'],
      'storeItems': order.meta?['store_items'],
      'manualItems': order.meta?['manual_items'],
      'itemDescription': order.itemDescription,
      'notes': order.notes,
    });
  }

  static List<OrderLineItem> fromOrderDataMap(Map<String, dynamic> orderData) {
    final items = <OrderLineItem>[];

    void addItem({
      required String? name,
      dynamic price,
      dynamic quantity,
    }) {
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) return;
      items.add(
        OrderLineItem(
          name: trimmed,
          price: _toDouble(price),
          quantity: _toInt(quantity, fallback: 1),
        ),
      );
    }

    final lesbuyItems = orderData['lesbuy_items'];
    if (lesbuyItems is List && lesbuyItems.isNotEmpty) {
      for (final raw in lesbuyItems) {
        if (raw is Map) {
          addItem(
            name: raw['name']?.toString(),
            price: raw['actual_price'] ?? raw['estimated_price'] ?? raw['price'],
            quantity: raw['quantity'],
          );
        }
      }
      if (items.isNotEmpty) return items;
    }

    final storeItems = orderData['storeItems'];
    if (storeItems is List) {
      for (final raw in storeItems) {
        if (raw is Map) {
          addItem(
            name: raw['productName']?.toString() ?? raw['name']?.toString(),
            price: raw['price'] ?? raw['estimated_price'],
            quantity: raw['quantity'],
          );
        }
      }
    }

    final manualItems = orderData['manualItems'];
    if (manualItems is List) {
      for (final raw in manualItems) {
        if (raw is Map) {
          addItem(
            name: raw['name']?.toString(),
            price: raw['price'] ?? raw['estimated_price'],
            quantity: raw['quantity'],
          );
        }
      }
    }

    final genericItems = orderData['items'];
    if (genericItems is List) {
      for (final raw in genericItems) {
        if (raw is Map) {
          addItem(
            name: raw['name']?.toString() ?? raw['productName']?.toString(),
            price: raw['price'] ??
                raw['actual_price'] ??
                raw['estimated_price'],
            quantity: raw['quantity'],
          );
        } else if (raw is String && raw.trim().isNotEmpty) {
          addItem(name: raw, price: 0, quantity: 1);
        }
      }
    }

    if (items.isNotEmpty) return items;

    final description = orderData['itemDescription']?.toString().trim();
    if (description != null && description.isNotEmpty) {
      return [
        OrderLineItem(name: description, price: 0, quantity: 1),
      ];
    }

    final notes = orderData['notes']?.toString().trim();
    if (notes != null && notes.isNotEmpty) {
      return [OrderLineItem(name: notes, price: 0, quantity: 1)];
    }

    return items;
  }

  static OrderLineItem _fromLesbuyItem(LesbuyItemDto item) {
    return OrderLineItem(
      name: item.name,
      price: item.actualPrice ?? item.estimatedPrice ?? 0,
      quantity: item.quantity,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value == null) return fallback;
    if (value is num) return value.round();
    return int.tryParse(value.toString()) ?? fallback;
  }
}
