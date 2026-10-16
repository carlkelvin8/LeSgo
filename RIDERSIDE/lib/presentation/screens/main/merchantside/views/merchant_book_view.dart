import '../../../../widgets/main/merchantside/menu/merchant_menu_setup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../widgets/common/menu_image_widget.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../widgets/widgets.dart';
import '../../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../food_detail_screen.dart';

class MerchantBookView extends ConsumerStatefulWidget {
  const MerchantBookView({super.key});

  @override
  ConsumerState<MerchantBookView> createState() => _MerchantBookViewState();
}

class _MerchantBookViewState extends ConsumerState<MerchantBookView>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  late final AnimationController _emptyPulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  Widget _reveal(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((i * .10).clamp(0.0, .5), 1.0, curve: Curves.easeOut),
    );
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: fade.drive(
          Tween(begin: const Offset(0, .04), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _entrance.dispose();
    _emptyPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hp = ResponsiveUtils.horizontalPadding(context);
    final menuAsync = ref.watch(merchantMenuProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredItems = ref.watch(filteredMenuItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────
        _reveal(
          0,
          Padding(
            padding: EdgeInsets.fromLTRB(hp, 18, hp, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.6,
                    color: isDark ? Colors.white : const Color(0xFF1A0A2E),
                  ),
                ),
                Text(
                  'Browse your menu categories',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF9A85B8)
                        : const Color(0xFFAA90C0),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (menuAsync.hasValue &&
            !menuAsync.isLoading &&
            !menuAsync.hasError &&
            (menuAsync.value?.categories.isEmpty ?? true))
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hp, 4, hp, 24),
              child: _reveal(
                1,
                MerchantMenuSetupCard(
                  isDark: isDark,
                  onAction: () {
                    HapticFeedback.selectionClick();
                    ref.read(merchantNavProvider.notifier).state =
                        MerchantNavType.menu;
                  },
                ),
              ),
            ),
          )
        else ...[
          // ── Category chips ──────────────────────────────────────────────
          _reveal(
            1,
            SizedBox(
              height: 92,
              child: menuAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF5F2D82),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 16,
                        color: Color(0xFF9A85B8),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(merchantMenuProvider),
                        child: const Text(
                          'Retry',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            color: Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (menu) {
                  if (menu == null || menu.categories.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    itemCount: menu.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final cat = menu.categories[i];
                      final sel = selectedCategory == cat.id;
                      return _AnimatedCategoryChip(
                        label: cat.name,
                        icon: cat.iconEmoji ?? '🍽️',
                        imageUrl: cat.imageUrl,
                        isSelected: sel,
                        index: i,
                        entrance: _entrance,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(selectedCategoryProvider.notifier).state =
                              sel ? null : cat.id;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hp, vertical: 12),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF5F2D82).withValues(alpha: .12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Items grid ──────────────────────────────────────────────────
          Expanded(
            child: filteredItems.isEmpty
                ? _EmptyItemsState(
                    pulse: _emptyPulse,
                    isDark: isDark,
                    hasFilter: selectedCategory != null,
                  )
                : _AnimatedItemGrid(
                    items: filteredItems,
                    entrance: _entrance,
                    hp: hp,
                    onItemTap: (item) => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, anim, _) => FadeTransition(
                          opacity: anim,
                          child: FoodDetailScreen(
                            foodName: item.name,
                            foodImage: item.imageUrl,
                            price: 'PHP ${item.price.toStringAsFixed(2)}',
                            description: item.description ?? '',
                            sizes: item.options?['sizes'] != null
                                ? List<String>.from(item.options!['sizes'])
                                : ['Regular'],
                          ),
                        ),
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

// ─── Animated category chip ───────────────────────────────────────────────────
class _AnimatedCategoryChip extends StatefulWidget {
  final String label;
  final String icon;
  final String? imageUrl;
  final bool isSelected;
  final int index;
  final AnimationController entrance;
  final VoidCallback onTap;

  const _AnimatedCategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.index,
    required this.entrance,
    required this.onTap,
    this.imageUrl,
  });

  @override
  State<_AnimatedCategoryChip> createState() => _AnimatedCategoryChipState();
}

class _AnimatedCategoryChipState extends State<_AnimatedCategoryChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.isSelected;

    // Stagger entrance
    final itemAnim = CurvedAnimation(
      parent: widget.entrance,
      curve: Interval(
        (.15 + widget.index * .06).clamp(0.0, .80),
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([itemAnim, _press]),
      builder: (_, _) => Opacity(
        opacity: itemAnim.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - itemAnim.value)),
          child: Transform.scale(
            scale: 1.0 - .04 * _press.value,
            child: GestureDetector(
              onTapDown: (_) => _press.forward(),
              onTapUp: (_) => _press.reverse(),
              onTapCancel: () => _press.reverse(),
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 72,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [Color(0xFF8B3FC8), Color(0xFF5F2D82)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: sel ? null : const Color(0xFFF4F0FA),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF5F2D82,
                            ).withValues(alpha: .35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: -3,
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel
                            ? Colors.white.withValues(alpha: .22)
                            : Colors.white,
                        boxShadow: sel
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          widget.imageUrl != null &&
                              widget.imageUrl!.trim().isNotEmpty
                          ? MenuImageWidget(
                              source: widget.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: Center(
                                child: Text(
                                  widget.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.icon,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 9.5,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : const Color(0xFF4A3060),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Animated items grid ──────────────────────────────────────────────────────
class _AnimatedItemGrid extends StatelessWidget {
  final List items;
  final AnimationController entrance;
  final double hp;
  final Function(dynamic) onItemTap;

  const _AnimatedItemGrid({
    required this.items,
    required this.entrance,
    required this.hp,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 600
            ? 4
            : constraints.maxWidth >= 360
            ? 3
            : 2;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(hp, 0, hp, 24),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 10,
            childAspectRatio: .68,
          ),
          itemBuilder: (context, i) {
            final item = items[i];
            final delay = (.25 + i * .05).clamp(0.0, .80);
            final itemAnim = CurvedAnimation(
              parent: entrance,
              curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
            );
            return AnimatedBuilder(
              animation: itemAnim,
              builder: (_, child) => Opacity(
                opacity: itemAnim.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - itemAnim.value)),
                  child: child,
                ),
              ),
              child: _GridItemCard(item: item, onTap: () => onItemTap(item)),
            );
          },
        );
      },
    );
  }
}

// ─── Grid item card ───────────────────────────────────────────────────────────
class _GridItemCard extends StatefulWidget {
  final dynamic item;
  final VoidCallback onTap;
  const _GridItemCard({required this.item, required this.onTap});

  @override
  State<_GridItemCard> createState() => _GridItemCardState();
}

class _GridItemCardState extends State<_GridItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - .03 * _press.value, child: child),
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.selectionClick();
          _press.forward();
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1730) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2E2540) : const Color(0xFFF0EBF6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF5F2D82,
                ).withValues(alpha: isDark ? .08 : .05),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: -3,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child:
                      widget.item.imageUrl != null &&
                          widget.item.imageUrl!.isNotEmpty
                      ? MerchantFoodGridItem(
                          name: widget.item.name,
                          imagePath: widget.item.imageUrl,
                          onTap: widget.onTap,
                        )
                      : Container(
                          width: double.infinity,
                          color: const Color(0xFFEDD9FF),
                          child: const Center(
                            child: Icon(
                              Icons.restaurant_rounded,
                              size: 32,
                              color: Color(0xFF9B70CC),
                            ),
                          ),
                        ),
                ),
              ),
              // Info
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A0A2E),
                          height: 1.3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F2D82).withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₱${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5F2D82),
                          ),
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
    );
  }
}

// ─── Empty items state ────────────────────────────────────────────────────────
class _EmptyItemsState extends StatelessWidget {
  final AnimationController pulse;
  final bool isDark;
  final bool hasFilter;

  const _EmptyItemsState({
    required this.pulse,
    required this.isDark,
    required this.hasFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: pulse,
              builder: (_, _) => Transform.scale(
                scale: 1.0 + .04 * pulse.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFF5F2D82,
                    ).withValues(alpha: .08 + .04 * pulse.value),
                    border: Border.all(
                      color: const Color(
                        0xFF5F2D82,
                      ).withValues(alpha: .12 + .06 * pulse.value),
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF5F2D82,
                        ).withValues(alpha: .10 * pulse.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 38,
                    color: Color(0xFF6D3EA0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hasFilter ? 'Nothing here' : 'Menu is empty',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A0A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'No items in this category yet.'
                  : 'Add items to your menu from the Menu tab.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? const Color(0xFF9A85B8)
                    : const Color(0xFFAA90C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
