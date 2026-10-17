import '../../core/utils/menu_item_options.dart';
import '../../core/utils/rider_commission_utils.dart';

int? extractDriverId(Map<String, dynamic> json) {
  final direct = json['driver_id'];
  if (direct is num) return direct.toInt();
  if (direct is String) return int.tryParse(direct);

  final driverProfile = json['driver_profile'];
  if (driverProfile is Map) {
    final id = driverProfile['id'];
    if (id is num) return id.toInt();
    if (id is String) return int.tryParse(id);
  }
  return null;
}

String? _formatItemOptions(dynamic item) {
  if (item is! Map) return null;

  final display = item['options_display']?.toString();
  if (display != null && display.trim().isNotEmpty) return display.trim();

  final notes = item['notes']?.toString();
  if (notes != null && notes.trim().isNotEmpty) return notes.trim();

  final selectedRaw = item['selected_options'];
  if (selectedRaw is Map) {
    final selected = SelectedMenuOptions.fromApiMap(
      Map<String, dynamic>.from(selectedRaw),
    );
    if (!selected.isEmpty) return selected.formatDisplay();
  }

  final legacyOptions = item['options']?.toString();
  if (legacyOptions != null && legacyOptions.trim().isNotEmpty) {
    return legacyOptions.trim();
  }
  return null;
}

double _itemLineTotal(dynamic item, int qty) {
  if (item is! Map) return 0;
  final explicitTotal = item['total'];
  if (explicitTotal != null) {
    final totalVal = RiderOrder.parseDouble(explicitTotal);
    if (totalVal > 0) return totalVal;
  }
  final actual = item['actual_price'];
  if (actual != null) {
    final actualVal = RiderOrder.parseDouble(actual);
    if (actualVal > 0) return actualVal;
  }
  final unit = RiderOrder.parseDouble(item['estimated_price'] ?? item['price']);
  return unit * qty;
}

class RiderOrder {
  final int id;
  final int serviceId;
  final String status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String pickupContactName;
  final String pickupContactPhone;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffContactName;
  final String dropoffContactPhone;
  final double estimatedFare;
  final double? driverShare;
  final int estimatedDistanceM;
  final String paymentMethod;
  final String? notes;
  final int? driverId;
  final double? totalAmount;
  final double itemsTotal;
  final double discount;
  final double shippingFee;
  final double? commissionRate;
  final List<String> parsedItems;

  RiderOrder({
    required this.id,
    required this.serviceId,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffContactName,
    required this.dropoffContactPhone,
    required this.estimatedFare,
    this.driverShare,
    required this.estimatedDistanceM,
    required this.paymentMethod,
    this.notes,
    this.driverId,
    this.totalAmount,
    this.itemsTotal = 0.0,
    this.discount = 0.0,
    this.shippingFee = 0.0,
    this.commissionRate,
    this.parsedItems = const [],
  });

  double get displayShippingFee =>
      shippingFee > 0 ? shippingFee : estimatedFare;

  double get walletDeductionAmount => displayShippingFee;

  double get displayTotalAmount {
    if (totalAmount != null && totalAmount! > 0) return totalAmount!;
    if (itemsTotal > 0) {
      return itemsTotal + displayShippingFee - discount;
    }
    return displayShippingFee > 0 ? displayShippingFee : estimatedFare;
  }

  static double parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String get serviceName {
    switch (serviceId) {
      case 1:
        return 'LesGo';
      case 2:
        return 'LesRide';
      case 3:
        return 'LesEat';
      case 4:
        return 'LesBuy';
      case 5:
        return 'LesTransport';
      default:
        return 'Order';
    }
  }

  double get distanceKm => estimatedDistanceM / 1000.0;

  double estimatedEarningsFor(String? packageTier) {
    return RiderCommissionUtils.earningsFromShipping(
      shippingFee: displayShippingFee,
      driverShare: driverShare,
      packageTier: packageTier,
    );
  }

  factory RiderOrder.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> endpoint(String prefix) {
      final direct = j['${prefix}_address'];
      if (direct is Map) return Map<String, dynamic>.from(direct);
      final meta = j['meta'];
      final nested = j[prefix] ?? (meta is Map ? meta[prefix] : null);
      return nested is Map ? Map<String, dynamic>.from(nested) : {};
    }

    double coordinate(String prefix, bool latitude) {
      final data = endpoint(prefix);
      return parseDouble(
        j['${prefix}_${latitude ? 'lat' : 'lng'}'] ??
            data[latitude ? 'latitude' : 'longitude'] ??
            data[latitude ? 'lat' : 'lng'],
      );
    }

    String extractAddress(String prefix) {
      final data = endpoint(prefix);
      final values = [
        j['${prefix}_address'],
        data['address_line1'],
        data['formatted_address'],
        data['address'],
        data['name'],
      ];
      for (final value in values) {
        if (value is! String) continue;
        final address = value.trim();
        if (address.isNotEmpty && !address.startsWith('Instance of '))
          return address;
      }
      final lat = coordinate(prefix, true), lng = coordinate(prefix, false);
      if (lat.isFinite &&
          lng.isFinite &&
          lat.abs() <= 90 &&
          lng.abs() <= 180 &&
          (lat != 0 || lng != 0)) {
        return 'Map pin: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      }
      return 'Address unavailable';
    }

    final extractedItems = <String>[];
    var calculatedItemsTotal = 0.0;

    void addItemLine(dynamic item) {
      if (item is! Map) return;
      final name = item['name'] ?? 'Item';
      final qtyStr = item['quantity']?.toString() ?? '1';
      final qty = int.tryParse(qtyStr) ?? 1;
      final lineTotal = _itemLineTotal(item, qty);
      calculatedItemsTotal += lineTotal;
      final optionsText = _formatItemOptions(item);
      var line = '${qty}x $name';
      if (lineTotal > 0) {
        line += ' (PHP ${lineTotal.toStringAsFixed(2)})';
      }
      if (optionsText != null && optionsText.isNotEmpty) {
        line += '\n   $optionsText';
      }
      extractedItems.add(line);
    }

    if (j['lesbuy_items'] is List && (j['lesbuy_items'] as List).isNotEmpty) {
      for (final item in j['lesbuy_items']) {
        addItemLine(item);
      }
    } else if (j['meta'] is Map &&
        j['meta']['items'] is List &&
        (j['meta']['items'] as List).isNotEmpty) {
      for (final item in j['meta']['items']) {
        addItemLine(item);
      }
    } else if (j['item_description'] != null &&
        j['item_description'].toString().isNotEmpty) {
      extractedItems.add(j['item_description'].toString());
    } else if (j['notes'] != null && j['notes'].toString().isNotEmpty) {
      extractedItems.add(j['notes'].toString());
    }

    var extractedDiscount = 0.0;
    if (j['discount_amount'] != null) {
      extractedDiscount = parseDouble(j['discount_amount']);
    } else if (j['meta'] is Map && j['meta']['discount'] != null) {
      extractedDiscount = parseDouble(j['meta']['discount']);
    }

    double? extractedTotal;
    var extractedShipping = parseDouble(j['estimated_fare']);
    double? extractedCommissionRate;
    if (j['meta'] is Map) {
      final meta = j['meta'] as Map<String, dynamic>;
      if (calculatedItemsTotal <= 0 && meta['subtotal'] != null) {
        calculatedItemsTotal = parseDouble(meta['subtotal']);
      }
      if (meta['grand_total'] != null) {
        extractedTotal = parseDouble(meta['grand_total']);
      } else if (meta['total'] != null) {
        extractedTotal = parseDouble(meta['total']);
      }
      if (meta['shipping_fee'] != null) {
        extractedShipping = parseDouble(meta['shipping_fee']);
      } else if (meta['delivery_fee'] != null) {
        extractedShipping = parseDouble(meta['delivery_fee']);
      }
      if (meta['driver_commission_rate'] != null) {
        extractedCommissionRate = parseDouble(meta['driver_commission_rate']);
      }
    }

    final user = j['user'] is Map<String, dynamic>
        ? j['user'] as Map<String, dynamic>
        : (j['customer'] is Map<String, dynamic>
              ? j['customer'] as Map<String, dynamic>
              : null);

    var dropoffName = j['dropoff_contact_name']?.toString().trim() ?? '';
    var dropoffPhone = j['dropoff_contact_phone']?.toString().trim() ?? '';
    if (user != null) {
      if (dropoffName.isEmpty) {
        dropoffName = user['name']?.toString().trim() ?? '';
      }
      if (dropoffPhone.isEmpty) {
        dropoffPhone =
            user['phone_number']?.toString().trim() ??
            user['phone']?.toString().trim() ??
            '';
      }
    }

    return RiderOrder(
      id: j['id'] as int,
      serviceId: j['service_id'] as int? ?? 1,
      status: j['status'] as String? ?? 'pending',
      pickupAddress: extractAddress('pickup'),
      pickupLat: coordinate('pickup', true),
      pickupLng: coordinate('pickup', false),
      pickupContactName: j['pickup_contact_name'] as String? ?? '',
      pickupContactPhone: j['pickup_contact_phone'] as String? ?? '',
      dropoffAddress: extractAddress('dropoff'),
      dropoffLat: coordinate('dropoff', true),
      dropoffLng: coordinate('dropoff', false),
      dropoffContactName: dropoffName,
      dropoffContactPhone: dropoffPhone,
      estimatedFare: parseDouble(j['estimated_fare']),
      driverShare: j['driver_share'] != null
          ? parseDouble(j['driver_share'])
          : null,
      estimatedDistanceM: j['estimated_distance_m'] as int? ?? 0,
      paymentMethod: j['payment_method'] as String? ?? 'cash',
      notes: j['notes'] as String?,
      driverId: extractDriverId(j),
      totalAmount:
          extractedTotal ??
          (j['total_amount'] != null ? parseDouble(j['total_amount']) : null),
      itemsTotal: calculatedItemsTotal,
      discount: extractedDiscount,
      shippingFee: extractedShipping,
      commissionRate: extractedCommissionRate,
      parsedItems: extractedItems,
    );
  }

  double earningsFor({String? packageTier, double? riderCommissionRate}) {
    if (driverShare != null && driverShare! > 0) return driverShare!;
    final rate =
        commissionRate ??
        riderCommissionRate ??
        RiderCommissionUtils.rateForPackage(packageTier);
    return displayShippingFee * rate;
  }

  double get displayEarnings => displayShippingFee;

  double driverEarningsFor(
    String? packageTier, {
    double? riderCommissionRate,
  }) => earningsFor(
    packageTier: packageTier,
    riderCommissionRate: riderCommissionRate,
  );

  RiderOrder copyWith({String? status, int? driverId}) {
    return RiderOrder(
      id: id,
      serviceId: serviceId,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupContactName: pickupContactName,
      pickupContactPhone: pickupContactPhone,
      dropoffAddress: dropoffAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      dropoffContactName: dropoffContactName,
      dropoffContactPhone: dropoffContactPhone,
      estimatedFare: estimatedFare,
      driverShare: driverShare,
      estimatedDistanceM: estimatedDistanceM,
      paymentMethod: paymentMethod,
      notes: notes,
      driverId: driverId ?? this.driverId,
      totalAmount: totalAmount,
      itemsTotal: itemsTotal,
      discount: discount,
      shippingFee: shippingFee,
      commissionRate: commissionRate,
      parsedItems: parsedItems,
    );
  }
}
