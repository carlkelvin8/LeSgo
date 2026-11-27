import 'package:lesgo/core/theme/app_colors.dart';
import 'package:lesgo/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../domain/entities/booking/lesbuy/store.dart';

/// Compact horizontal store row (icon tile, name, address, rating, ETA).
class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback? onTap;

  const StoreCard({super.key, required this.store, this.onTap});

  static String _titleCase(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, const Color(0xFF5F2D82));
    final tile = ResponsiveUtils.imageHeight(context, 88).clamp(80.0, 110.0);
    final typeLabel = store.storeType == null || store.storeType!.isEmpty
        ? null
        : _titleCase(store.storeType!);

    return Semantics(
      button: true,
      label: '${store.name}, rated ${store.rating.toStringAsFixed(1)}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpace.md),
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: AppCard.decoration(context, radius: AppRadius.lg),
          child: Row(
            children: [
              Container(
                width: tile,
                height: tile,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _getStoreIcon(store.categories),
                  size: 40,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.foreground(
                                context,
                                Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        if (store.isNew) ...[
                          const SizedBox(width: AppSpace.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5484D),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (typeLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        typeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: ResponsiveUtils.fontSize(context, 12),
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      store.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 12),
                        height: 1.25,
                        color: AppColors.foreground(context, Colors.grey[600]!),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          store.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground(
                              context,
                              Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          ' (${store.reviewCount}+)',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                            color: AppColors.foreground(
                              context,
                              Colors.grey[500]!,
                            ),
                          ),
                        ),
                        if (store.deliveryTime != null) ...[
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.foreground(
                              context,
                              Colors.grey[500]!,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            store.deliveryTime!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 12),
                              color: AppColors.foreground(
                                context,
                                Colors.grey[600]!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.foreground(context, Colors.grey[400]!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStoreIcon(List<String> categories) {
    if (categories.contains('pharmacy') || categories.contains('health')) {
      return Icons.local_pharmacy;
    }
    if (categories.contains('books') || categories.contains('school_supplies')) {
      return Icons.menu_book;
    }
    if (categories.contains('hardware') || categories.contains('tools')) {
      return Icons.hardware;
    }
    if (categories.contains('beauty') || categories.contains('personal_care')) {
      return Icons.spa;
    }
    if (categories.contains('pets') || categories.contains('pet_food')) {
      return Icons.pets;
    }
    return Icons.store;
  }
}
