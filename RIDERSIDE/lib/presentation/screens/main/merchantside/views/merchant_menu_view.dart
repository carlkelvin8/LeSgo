import '../../../../widgets/main/merchantside/menu/merchant_menu_setup_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/merchant_item_inventory_utils.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/utils/screen_auto_refresh.dart';
import '../../../../mixins/auto_refresh_mixin.dart';
import '../../../../provider/main/merchantside/merchant_nav_provider.dart';
import '../../../../provider/main/merchantside/merchant_inventory_provider.dart';
import '../../../../provider/main/merchantside/merchant_menu_provider.dart';
import '../../../../widgets/main/merchantside/menu/merchant_low_stock_banner.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_inventory_badge.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_stock_controls.dart';
import 'dart:convert';

import '../merchant_menu_add_category_screen.dart';
import '../merchant_menu_edit_item_screen.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_actions.dart';
import '../../../../widgets/main/merchantside/menu/merchant_menu_item_duplicate.dart';
import '../../../../../data/data_source/dto/merchant/menu_item_dto.dart';
import '../../../../widgets/common/menu_image_widget.dart';

class MerchantMenuView extends ConsumerStatefulWidget {
  const MerchantMenuView({super.key});

  @override
  ConsumerState<MerchantMenuView> createState() => _MerchantMenuViewState();
}

class _MerchantMenuViewState extends ConsumerState<MerchantMenuView>
    with WidgetsBindingObserver, AutoRefreshMixin, TickerProviderStateMixin {
  @override
  Duration get autoRefreshInterval => kScreenAutoRefreshInterval;

  @override
  void onAutoRefresh() =>
      refreshMerchantScreen(ref, MerchantNavType.menu, silent: true);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final AnimationController _emptyPulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _entrance.dispose();
    _emptyPulse.dispose();
    super.dispose();
  }

  Future<void> _refreshMenu() async {
    _entrance.forward(from: 0);
    ref.invalidate(merchantMenuProvider);
    ref.invalidate(merchantMenuItemsProvider);
    await ref.read(merchantMenuProvider.future);
  }

  String _categoryName(List<MenuCategoryDto> cats, int? id) {
    if (id == null) return 'Unknown';
    try {
      return cats.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  MenuCategoryDto? _categoryById(List<MenuCategoryDto> cats, int? id) {
    if (id == null) return null;
    try {
      return cats.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _reveal(int i, Widget child) {
    final fade = CurvedAnimation(
      parent: _entrance,
      curve: Interval((i * .09).clamp(0.0, .5), 1.0, curve: Curves.easeOut),
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

  Future<void> _openEditCategory(MenuCategoryDto category) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MerchantMenuAddCategoryScreen(editingCategory: category),
      ),
    );
    await _refreshMenu();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(merchantMenuProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final inventoryFilter = ref.watch(merchantInventoryFilterProvider);
    final searchQuery = ref.watch(merchantMenuSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safePad = MediaQuery.of(context).padding;
    final menuSnapshot = menuAsync.valueOrNull;
    final categoryCount = menuSnapshot?.categories.length ?? 0;
    final itemCount = menuSnapshot?.categories
            .expand((category) => category.availableItems ?? const [])
            .length ??
        0;

    return RefreshIndicator(
      color: const Color(0xFF5F2D82),
      backgroundColor: isDark ? const Color(0xFF1E1730) : Colors.white,
      onRefresh: _refreshMenu,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Page header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A0A2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, safePad.top + 12, 16, 16),
              child: _reveal(
                0,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Menu',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF25232B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your food items',
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF9A85B8) : const Color(0xFF89858E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit selected category button
                        menuAsync.when(
                          data: (menu) {
                            final cat = menu == null ? null : _categoryById(menu.categories, selectedCategory);
                            if (cat == null) return const SizedBox.shrink();
                            return _PillButton(
                              label: 'Edit category',
                              icon: Icons.edit_outlined,
                              onTap: () => _openEditCategory(cat),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    
                    // Search Field
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1730) : const Color(0xFFF5F4F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E2540) : const Color(0xFFECEAF0),
                        ),
                      ),
                      child: TextField(
                        onChanged: (query) {
                          ref.read(merchantMenuSearchQueryProvider.notifier).state = query;
                        },
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF302B36),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search menu items...',
                          hintStyle: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 14,
                            color: isDark ? const Color(0xFF9A85B8) : const Color(0xFF918A98),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: isDark ? const Color(0xFF9A85B8) : const Color(0xFF918A98),
                            size: 20,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: isDark ? const Color(0xFF9A85B8) : const Color(0xFF918A98),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    ref.read(merchantMenuSearchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (categoryCount > 1)
                      Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF241638)
                            : const Color(0xFFF8F3FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3A2850)
                              : const Color(0xFFECE0F4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            size: 17,
                            color: isDark
                                ? const Color(0xFFC9A8E4)
                                : const Color(0xFF7B3FAA),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$categoryCount categor${categoryCount == 1 ? 'y' : 'ies'}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF4A3060),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '•',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF9A85B8)
                                  : const Color(0xFFB59AC8),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$itemCount item${itemCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFFBFA9CF)
                                  : const Color(0xFF8B7798),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFC9A8E4)
                                : const Color(0xFFB07BD3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (menuAsync.hasValue &&
              !menuAsync.isLoading &&
              !menuAsync.hasError &&
              (menuAsync.value?.categories.isEmpty ?? true))
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverToBoxAdapter(
                child: _reveal(
                  1,
                  MerchantMenuSetupCard(
                    isDark: isDark,
                    actionLabel: 'Add category',
                    onAction: () async {
                      HapticFeedback.selectionClick();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MerchantMenuAddCategoryScreen(),
                        ),
                      );
                      if (!mounted) return;
                      await _refreshMenu();
                    },
                  ),
                ),
              ),
            )
          else ...[
            // ── Category chips ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: isDark ? const Color(0xFF1A0A2E) : const Color(0xFFFEFDFE),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                child: _reveal(
                  1,
                  SizedBox(
                    height: 46,
                    child: menuAsync.when(
                      loading: () => const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5F2D82),
                          ),
                        ),
                      ),
                      error: (e, _) => Center(
                        child: TextButton.icon(
                          onPressed: () => ref.invalidate(merchantMenuProvider),
                          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF5F2D82)),
                          label: const Text(
                            'Retry',
                            style: TextStyle(fontFamily: 'TT Fors', color: Color(0xFF5F2D82)),
                          ),
                        ),
                      ),
                      data: (menu) {
                        if (menu == null || menu.categories.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        // A category chip is only useful when it groups more
                        // than one item. Keep the All filter and hide
                        // one-item categories so the menu stays compact.
                        final visibleCategories = menu.categories
                            .where((cat) => (cat.availableItems?.length ?? 0) > 1)
                            .toList();
                        return ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // "All" chip
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _CompactCategoryChip(
                                label: 'All',
                                icon: '🍽️',
                                isSelected: selectedCategory == null && searchQuery.isEmpty,
                                isDark: isDark,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  ref.read(selectedCategoryProvider.notifier).state = null;
                                  ref.read(merchantMenuSearchQueryProvider.notifier).state = '';
                                },
                              ),
                            ),
                            ...visibleCategories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _CompactCategoryChip(
                                  label: cat.name,
                                  icon: cat.iconEmoji ?? '🍴',
                                  imageUrl: cat.imageUrl,
                                  isSelected: selectedCategory == cat.id && searchQuery.isEmpty,
                                  isDark: isDark,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref.read(selectedCategoryProvider.notifier).state = cat.id;
                                    ref.read(merchantMenuSearchQueryProvider.notifier).state = '';
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ── Gradient divider ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5F2D82).withValues(alpha: .14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Low stock banner ─────────────────────────────────────────
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: MerchantLowStockBanner()),
            ),

            // ── "Food Menu" label + inventory filter ─────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              sliver: SliverToBoxAdapter(
                child: _reveal(
                  2,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FOOD MENU',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                          color: isDark
                              ? const Color(0xFF9A85B8)
                              : const Color(0xFFAA90C0),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InventoryFilterRow(
                        selected: inventoryFilter,
                        isDark: isDark,
                        onChanged: (f) {
                          HapticFeedback.selectionClick();
                          ref
                                  .read(
                                    merchantInventoryFilterProvider.notifier,
                                  )
                                  .state =
                              f;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Item list ────────────────────────────────────────────────
            menuAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: _ErrorState(
                  error: '$e',
                  isDark: isDark,
                  onRetry: _refreshMenu,
                ),
              ),
              data: (menu) {
                if (menu == null) {
                  return SliverFillRemaining(
                    child: _EmptyMenuState(
                      isDark: isDark,
                      pulse: _emptyPulse,
                      hasFilter: false,
                    ),
                  );
                }

                final allItems = [
                  for (final cat in menu.categories) ...?cat.availableItems,
                ];

                var filtered = selectedCategory == null
                    ? allItems
                    : allItems
                          .where((i) => i.menuCategoryId == selectedCategory)
                          .toList();

                filtered = filterMenuItemsByInventory(
                  filtered,
                  inventoryFilter,
                );

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyMenuState(
                      isDark: isDark,
                      pulse: _emptyPulse,
                      hasFilter: selectedCategory != null || inventoryFilter != MerchantInventoryFilter.all || searchQuery.isNotEmpty,
                      searchQuery: searchQuery,
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, safePad.bottom + 80),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      // Leave a little extra vertical room for the action row
                      // so fractional device pixels never trigger an
                      // overflow warning at the bottom of the card.
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final item = filtered[i];
                        final catName = _categoryName(menu.categories, item.menuCategoryId);
                        final itemAnim = CurvedAnimation(
                          parent: _entrance,
                          curve: Interval(
                            (.30 + i * .05).clamp(0.0, .85),
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
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
                          child: _GridMenuItemCard(
                            item: item,
                            categoryName: catName,
                            isDark: isDark,
                            inventoryBadge: MerchantMenuInventoryBadge(item: item),
                            stockControls: MerchantMenuStockControls(
                              item: item,
                              onStockChanged: (s) async {
                                try {
                                  await updateMerchantItemStock(ref, item: item, newStock: s);
                                  await _refreshMenu();
                                } catch (e) {
                                  if (ctx.mounted) {
                                    SnackBarUtils.showError(ctx, 'Failed: $e');
                                  }
                                }
                              },
                            ),
                            onEdit: () async {
                              await Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => MerchantMenuEditItemScreen(
                                    initialItem: menuItemToEditFormMap(item, categoryName: catName, encodeOptions: jsonEncode),
                                  ),
                                ),
                              );
                              await _refreshMenu();
                            },
                            onDelete: () => confirmAndDeleteMerchantMenuItem(ctx, ref, itemId: item.id, itemName: item.name),
                            onDuplicate: () async {
                              await duplicateMerchantMenuItem(ctx, ref, item: item);
                              await _refreshMenu();
                            },
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Compact Category Chip (smaller version) ─────────────────────────────────
class _CompactCategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final String? imageUrl;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CompactCategoryChip({
    required this.label,
    required this.icon,
    this.imageUrl,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82) : (isDark ? const Color(0xFF1E1730) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : (isDark ? const Color(0xFF2E2540) : const Color(0xFFECEAF0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF9A85B8) : const Color(0xFF302B36)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Grid Menu Item Card (vertical card for 2-column grid) ───────────────────
class _GridMenuItemCard extends StatelessWidget {
  final MenuItemDto item;
  final String categoryName;
  final bool isDark;
  final Widget inventoryBadge;
  final Widget stockControls;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _GridMenuItemCard({
    required this.item,
    required this.categoryName,
    required this.isDark,
    required this.inventoryBadge,
    required this.stockControls,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEdit();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1730) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2540) : const Color(0xFFECEAF0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1.12,
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? MenuImageWidget(
                        source: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: const Color(0xFFF5F4F7),
                          child: const Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFA49BAE),
                            size: 40,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF5F4F7),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Color(0xFFA49BAE),
                          size: 40,
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inventory badge
                    inventoryBadge,
                    const SizedBox(height: 4),

                    // Name
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF302B36),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if ((item.description ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 9,
                          color: isDark ? const Color(0xFF9A85B8) : const Color(0xFF918A98),
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const Spacer(),

                    // Price
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5F2D82),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Stock controls
                    stockControls,

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5F2D82),
                              side: const BorderSide(color: Color(0xFFE4D9EC)),
                              backgroundColor: const Color(0xFFFAF7FC),
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontFamily: 'TT Fors', fontSize: 12, fontWeight: FontWeight.w700),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          tooltip: 'More item actions',
                          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64596C)),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (action) {
                            if (action == 'duplicate') onDuplicate();
                            if (action == 'delete') onDelete();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'duplicate', child: Row(children: [
                              Icon(Icons.copy_outlined, size: 19, color: Color(0xFF64596C)),
                              SizedBox(width: 12), Text('Duplicate'),
                            ])),
                            PopupMenuItem(value: 'delete', child: Row(children: [
                              Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFB23B47)),
                              SizedBox(width: 12), Text('Delete', style: TextStyle(color: Color(0xFFB23B47))),
                            ])),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pill button ──────────────────────────────────────────────────────────────
class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _p,
    builder: (_, child) =>
        Transform.scale(scale: 1.0 - .03 * _p.value, child: child),
    child: GestureDetector(
      onTapDown: (_) => _p.forward(),
      onTapUp: (_) => _p.reverse(),
      onTapCancel: () => _p.reverse(),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF5F2D82).withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF5F2D82).withValues(alpha: .18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 14, color: const Color(0xFF5F2D82)),
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F2D82),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Inventory filter row ─────────────────────────────────────────────────────
class _InventoryFilterRow extends StatelessWidget {
  final MerchantInventoryFilter selected;
  final bool isDark;
  final ValueChanged<MerchantInventoryFilter> onChanged;

  const _InventoryFilterRow({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  static const _filters = [
    (MerchantInventoryFilter.all, 'All', Color(0xFF5F2D82)),
    (MerchantInventoryFilter.inStock, 'In Stock', Color(0xFF16A34A)),
    (MerchantInventoryFilter.lowStock, 'Low Stock', Color(0xFFD97706)),
    (MerchantInventoryFilter.soldOut, 'Sold Out', Color(0xFFDC2626)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterChip(
              label: f.$2,
              color: f.$3,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => onChanged(f.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _p = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
  );

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _p.forward(),
      onTapUp: (_) => _p.reverse(),
      onTapCancel: () => _p.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _p,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - .025 * _p.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
                    colors: [
                      Color.lerp(widget.color, Colors.white, .15)!,
                      widget.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isSelected
                ? null
                : (widget.isDark ? const Color(0xFF1E1730) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? widget.color
                  : (widget.isDark
                        ? const Color(0xFF2E2540)
                        : const Color(0xFFEDE9F2)),
              width: widget.isSelected ? 0 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: .30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: -3,
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: widget.isSelected
                  ? Colors.white
                  : (widget.isDark
                        ? const Color(0xFF9A85B8)
                        : const Color(0xFF776F80)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Menu item card ───────────────────────────────────────────────────────────
class _MenuItemCard extends StatefulWidget {
  final MenuItemDto item;
  final String categoryName;
  final bool isDark;
  final Widget inventoryBadge;
  final Widget stockControls;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _MenuItemCard({
    required this.item,
    required this.categoryName,
    required this.isDark,
    required this.inventoryBadge,
    required this.stockControls,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard>
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
    final isDark = widget.isDark;
    return AnimatedBuilder(
      animation: _press,
      builder: (_, child) =>
          Transform.scale(scale: 1.0 - .012 * _press.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onEdit();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1730) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2E2540) : const Color(0xFFEDE9F2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF5F2D82,
                ).withValues(alpha: isDark ? .08 : .04),
                blurRadius: 14,
                offset: const Offset(0, 3),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: SizedBox(
                  width: 88,
                  height: 100,
                  child:
                      widget.item.imageUrl != null &&
                          widget.item.imageUrl!.isNotEmpty
                      ? MenuImageWidget(
                          source: widget.item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: const Color(0xFFEDD9FF),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 32,
                              color: Color(0xFF9B70CC),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFEDD9FF),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            size: 32,
                            color: Color(0xFF9B70CC),
                          ),
                        ),
                ),
              ),

              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A0A2E),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5F2D82,
                              ).withValues(alpha: .09),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₱${widget.item.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5F2D82),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.categoryName,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF9A85B8)
                                : const Color(0xFFAA90C0),
                          ),
                        ),
                      ),

                      if ((widget.item.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF9A85B8)
                                : const Color(0xFFAA90C0),
                            height: 1.3,
                          ),
                        ),
                      ],

                      const SizedBox(height: 6),
                      widget.inventoryBadge,
                      const SizedBox(height: 4),

                      // Actions row
                      Row(
                        children: [
                          widget.stockControls,
                          const Spacer(),
                          _ActionBtn(
                            label: 'Edit',
                            color: const Color(0xFF5F2D82),
                            onTap: widget.onEdit,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '·',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF2E2540)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(width: 2),
                          _ActionBtn(
                            label: 'Dup',
                            color: const Color(0xFF16A34A),
                            onTap: widget.onDuplicate,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '·',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF2E2540)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(width: 2),
                          _ActionBtn(
                            label: 'Del',
                            color: Colors.red.shade600,
                            onTap: widget.onDelete,
                          ),
                        ],
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

// ─── Empty menu state ─────────────────────────────────────────────────────────
class _EmptyMenuState extends StatelessWidget {
  final bool isDark;
  final AnimationController pulse;
  final bool hasFilter;
  final String searchQuery;

  const _EmptyMenuState({
    required this.isDark,
    required this.pulse,
    required this.hasFilter,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery.isNotEmpty;
    
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
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF5F2D82).withValues(alpha: .08 + .04 * pulse.value),
                    border: Border.all(
                      color: const Color(0xFF5F2D82).withValues(alpha: .12 + .06 * pulse.value),
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5F2D82).withValues(alpha: .10 * pulse.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSearching ? Icons.search_off : Icons.restaurant_menu_rounded,
                    size: 36,
                    color: const Color(0xFF6D3EA0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching 
                  ? 'No items found'
                  : (hasFilter ? 'Nothing found' : 'Menu is empty'),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A0A2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try searching with different keywords'
                  : (hasFilter
                      ? 'No items match this filter.'
                      : 'Tap + to add your first menu item.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                height: 1.5,
                color: isDark ? const Color(0xFF9A85B8) : const Color(0xFFAA90C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Colors.red,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'TT Fors',
              fontSize: 12,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry', style: TextStyle(fontFamily: 'TT Fors')),
          ),
        ],
      ),
    ),
  );
}
