import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MerchantFoodSizeOption {
  nineInches,
  twelveInches,
  regular,
  large,
  solo,
  sharing,
  boxOf6,
  boxOf12,
  oz12,
  oz16,
}

extension MerchantFoodSizeOptionX on MerchantFoodSizeOption {
  String get label {
    switch (this) {
      case MerchantFoodSizeOption.nineInches:
        return '9 INCHES';
      case MerchantFoodSizeOption.twelveInches:
        return '12 INCHES';
      case MerchantFoodSizeOption.regular:
        return 'Regular';
      case MerchantFoodSizeOption.large:
        return 'Large';
      case MerchantFoodSizeOption.solo:
        return 'Solo';
      case MerchantFoodSizeOption.sharing:
        return 'Sharing';
      case MerchantFoodSizeOption.boxOf6:
        return 'Box of 6';
      case MerchantFoodSizeOption.boxOf12:
        return 'Box of 12';
      case MerchantFoodSizeOption.oz12:
        return '12 OZ';
      case MerchantFoodSizeOption.oz16:
        return '16 OZ';
    }
  }

  static MerchantFoodSizeOption? fromLabel(String raw) {
    final normalized = raw.trim().toUpperCase();
    switch (normalized) {
      case '9 INCHES':
        return MerchantFoodSizeOption.nineInches;
      case '12 INCHES':
        return MerchantFoodSizeOption.twelveInches;
      case 'REGULAR':
        return MerchantFoodSizeOption.regular;
      case 'LARGE':
        return MerchantFoodSizeOption.large;
      case 'SOLO':
        return MerchantFoodSizeOption.solo;
      case 'SHARING':
        return MerchantFoodSizeOption.sharing;
      case 'BOX OF 6':
        return MerchantFoodSizeOption.boxOf6;
      case 'BOX OF 12':
        return MerchantFoodSizeOption.boxOf12;
      case '12 OZ':
        return MerchantFoodSizeOption.oz12;
      case '16 OZ':
        return MerchantFoodSizeOption.oz16;
      default:
        return null;
    }
  }
}

class MerchantFoodDetailInput {
  final String foodName;
  final String price;
  final List<String> sizes;

  const MerchantFoodDetailInput({
    required this.foodName,
    required this.price,
    required this.sizes,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MerchantFoodDetailInput &&
        other.foodName == foodName &&
        other.price == price &&
        _listEquals(other.sizes, sizes);
  }

  @override
  int get hashCode => Object.hash(
        foodName,
        price,
        Object.hashAll(sizes),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class MerchantFoodDetailState {
  final List<MerchantFoodSizeOption> sizes;
  final MerchantFoodSizeOption selectedSize;
  final int quantity;
  final double unitPrice;

  const MerchantFoodDetailState({
    required this.sizes,
    required this.selectedSize,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => unitPrice * quantity;

  MerchantFoodDetailState copyWith({
    List<MerchantFoodSizeOption>? sizes,
    MerchantFoodSizeOption? selectedSize,
    int? quantity,
    double? unitPrice,
  }) {
    return MerchantFoodDetailState(
      sizes: sizes ?? this.sizes,
      selectedSize: selectedSize ?? this.selectedSize,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

class MerchantFoodDetailNotifier extends StateNotifier<MerchantFoodDetailState> {
  MerchantFoodDetailNotifier({required MerchantFoodDetailInput input})
      : super(
          MerchantFoodDetailState(
            sizes: _parseSizeOptions(input.sizes),
            selectedSize: _parseSizeOptions(input.sizes).first,
            quantity: 1,
            unitPrice: _parseDisplayPrice(input.price),
          ),
        );

  static double _parseDisplayPrice(String rawPrice) {
    return double.parse(rawPrice.replaceAll('PHP ', '').replaceAll(',', ''));
  }

  static List<MerchantFoodSizeOption> _parseSizeOptions(List<String> labels) {
    final options = labels
        .map(MerchantFoodSizeOptionX.fromLabel)
        .whereType<MerchantFoodSizeOption>()
        .toList();

    if (options.isEmpty) {
      return const [MerchantFoodSizeOption.regular];
    }

    return options;
  }

  void selectSize(MerchantFoodSizeOption size) {
    state = state.copyWith(selectedSize: size);
  }

  void incrementQuantity() {
    state = state.copyWith(quantity: state.quantity + 1);
  }

  void decrementQuantity() {
    if (state.quantity <= 1) return;
    state = state.copyWith(quantity: state.quantity - 1);
  }
}

final merchantFoodDetailProvider = StateNotifierProvider.autoDispose
    .family<MerchantFoodDetailNotifier, MerchantFoodDetailState, MerchantFoodDetailInput>(
  (ref, input) => MerchantFoodDetailNotifier(input: input),
);
