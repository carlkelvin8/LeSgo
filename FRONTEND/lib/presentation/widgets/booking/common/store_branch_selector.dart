import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../data/data_source/dto/partner/store_branch.dart';

/// Shows which store branch the order is picked up from and lets the
/// customer switch when the store has more than one open branch.
class StoreBranchSelector extends StatelessWidget {
  final List<StoreBranch> branches;
  final StoreBranch? selected;
  final double dropoffLat;
  final double dropoffLng;
  final ValueChanged<int> onSelected;
  final bool enabled;

  const StoreBranchSelector({
    super.key,
    required this.branches,
    required this.selected,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.onSelected,
    this.enabled = true,
  });

  static const _purple = Color(0xFF5F2D82);

  String _distanceLabel(StoreBranch b) {
    final m = b.distanceTo(dropoffLat, dropoffLng);
    if (m == null) return '';
    return m < 1000 ? '$m m away' : '${(m / 1000).toStringAsFixed(1)} km away';
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Text(
                  'Choose a branch',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Delivery fee depends on how far the branch is from you.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: branches
                      .map(
                        (b) => ListTile(
                          leading: Icon(
                            b.id == selected?.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _purple,
                          ),
                          title: Text(b.name),
                          subtitle: Text(
                            [b.address, _distanceLabel(b)]
                                .where((s) => s.isNotEmpty)
                                .join('\n'),
                          ),
                          isThreeLine: b.address.isNotEmpty,
                          onTap: () => Navigator.pop(ctx, b.id),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final branch = selected;
    if (branch == null) return const SizedBox.shrink();
    final canSwitch = enabled && branches.length > 1;
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hp),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canSwitch ? () => _openPicker(context) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: _purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup branch',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        branch.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (_distanceLabel(branch).isNotEmpty)
                        Text(
                          _distanceLabel(branch),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (canSwitch)
                  const Text(
                    'Change',
                    style: TextStyle(color: _purple, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
