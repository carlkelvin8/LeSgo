import 'package:flutter/material.dart';
import '../../../../../provider/main/merchantside/merchant_food_detail_provider.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../common/menu_image_widget.dart';

const _brand = Color(0xFF5F2D82);
const _brandTint = Color(0xFFF4EEF8);
const _ink = Color(0xFF251A38);
const _muted = Color(0xFF7A6F88);
const _pageBg = Colors.white;

class MerchantFoodDetailContent extends StatelessWidget {
  final String foodName;
  final String? foodImage;
  final String displayPrice;
  final String description;
  final List<MerchantFoodSizeOption> sizes;
  final MerchantFoodSizeOption selectedSize;
  final ValueChanged<MerchantFoodSizeOption> onSelectSize;

  const MerchantFoodDetailContent({
    super.key,
    required this.foodName,
    required this.foodImage,
    required this.displayPrice,
    required this.description,
    required this.sizes,
    required this.selectedSize,
    required this.onSelectSize,
  });

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(foodImage: foodImage, topInset: topInset),
            Padding(
              padding: EdgeInsets.fromLTRB(hp, 20, hp, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    foodName: foodName,
                    displayPrice: displayPrice,
                    description: description,
                  ),
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    title: 'Choose a size',
                    badge: 'Required',
                  ),
                  const SizedBox(height: 12),
                  _SizeGrid(
                    sizes: sizes,
                    selectedSize: selectedSize,
                    onSelectSize: onSelectSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.foodImage, required this.topInset});
  final String? foodImage;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, topInset + 4, 20, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Item details',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.65,
              child: MenuImageWidget(
                source: foodImage,
                fit: BoxFit.cover,
                placeholder: Container(
                  color: _brandTint,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 56,
                    color: _brand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.foodName,
    required this.displayPrice,
    required this.description,
  });

  final String foodName;
  final String displayPrice;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          foodName,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 26),
            fontWeight: FontWeight.w800,
            color: _ink,
            height: 1.15,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _brandTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            displayPrice,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 17),
              fontWeight: FontWeight.w800,
              color: _brand,
            ),
          ),
        ),
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            description,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: _muted,
              height: 1.55,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.badge});

  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 17),
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _brandTint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _brand,
            ),
          ),
        ),
      ],
    );
  }
}

class _SizeGrid extends StatelessWidget {
  const _SizeGrid({
    required this.sizes,
    required this.selectedSize,
    required this.onSelectSize,
  });

  final List<MerchantFoodSizeOption> sizes;
  final MerchantFoodSizeOption selectedSize;
  final ValueChanged<MerchantFoodSizeOption> onSelectSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        // One full-width card for a single option, otherwise two columns.
        final width =
            sizes.length == 1 || MediaQuery.textScalerOf(context).scale(14) > 20
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: sizes
              .map(
                (size) => SizedBox(
                  width: width,
                  child: _SizeCard(
                    label: size.label,
                    isSelected: size == selectedSize,
                    onTap: () => onSelectSize(size),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? _brandTint : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? _brand : const Color(0xFFEAE3F2),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _brand : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _brand : const Color(0xFFCFC3DD),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 15),
                      fontWeight: FontWeight.w800,
                      color: isSelected ? _brand : _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
