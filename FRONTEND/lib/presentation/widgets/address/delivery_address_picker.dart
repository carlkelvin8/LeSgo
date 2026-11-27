import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routers/app_router.dart';
import '../../../core/constants/routers/main/main_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/data_source/dto/address/address_dto.dart';
import '../../provider/auth/auth_provider.dart';
import '../../provider/main/address/address_provider.dart';

const _purple = Color(0xFF5F2D82);
const _ink = Color(0xFF22192B);
const _muted = Color(0xFF62586B);
const _line = Color(0xFFEAE2EF);

void showDeliveryAddressPicker(
  BuildContext context, {
  required void Function(BuildContext, AddressDto) onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: AppColors.surface(context, Colors.white),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    clipBehavior: Clip.antiAlias,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _DeliveryAddressPicker(
      onSelected: (address) => onSelected(context, address),
    ),
  );
}

class _DeliveryAddressPicker extends ConsumerStatefulWidget {
  const _DeliveryAddressPicker({required this.onSelected});

  final ValueChanged<AddressDto> onSelected;

  @override
  ConsumerState<_DeliveryAddressPicker> createState() =>
      _DeliveryAddressPickerState();
}

class _DeliveryAddressPickerState
    extends ConsumerState<_DeliveryAddressPicker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAddresses();
    });
  }

  void _loadAddresses() {
    final id = int.tryParse(ref.read(authProvider).user?.id ?? '');
    if (id != null) ref.read(addressProvider.notifier).loadAddresses(id);
  }

  void _manageAddresses() =>
      AppRouter.push(context, MainRoutes.addressManagement);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressProvider);
    final accent = AppColors.accent(context, _purple);
    final foreground = AppColors.foreground(context, _ink);
    final muted = AppColors.foreground(context, _muted);
    final ordered = [
      ...state.addresses.where((address) => address.isDefault),
      ...state.addresses.where((address) => !address.isDefault),
    ];
    final isEmpty = ordered.isEmpty;
    final failed = isEmpty && state.error != null;
    final showAdd = isEmpty && !failed && !state.isLoading;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .84,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border(context, const Color(0xFFD9CFDF)),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery address',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                      if (!isEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Where should we deliver your order?',
                          style: TextStyle(color: muted, fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.surface(
                      context,
                      const Color(0xFFF4EFF7),
                    ),
                    foregroundColor: foreground,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isLoading)
              Padding(
                padding: const EdgeInsets.all(36),
                child: Center(child: CircularProgressIndicator(color: accent)),
              )
            else if (isEmpty)
              _AddressPickerMessage(
                failed: failed,
                onAction: failed ? _loadAddresses : _manageAddresses,
              )
            else ...[
              for (final address in ordered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SavedAddressCard(
                    address: address,
                    selected: address.id == state.selectedAddress?.id,
                    onTap: () {
                      ref.read(addressProvider.notifier).selectAddress(address);
                      widget.onSelected(address);
                    },
                  ),
                ),
            ],
            if (!showAdd)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _manageAddresses,
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 19),
                  label: const Text('Manage addresses'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddressPickerMessage extends StatelessWidget {
  const _AddressPickerMessage({required this.failed, required this.onAction});

  final bool failed;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _purple);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface(context, const Color(0xFFF8F3FB)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border(context, _line)),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .07),
                  border: Border.all(color: accent.withValues(alpha: .14)),
                ),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.buttonFill(context),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Icon(
                    failed
                        ? Icons.sync_problem_rounded
                        : Icons.add_location_alt_rounded,
                    color: AppColors.onButton(context),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                failed
                    ? 'Couldn’t load your addresses'
                    : 'No saved addresses yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground(context, _ink),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                failed
                    ? 'Check your connection and try again.'
                    : 'Add an address to see your delivery fee and continue checkout.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.foreground(context, _muted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onAction,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.buttonFill(context),
            foregroundColor: AppColors.onButton(context),
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          icon: Icon(failed ? Icons.refresh_rounded : Icons.add_rounded),
          label: Text(
            failed ? 'Try again' : 'Add address',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final AddressDto address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context, _purple);
    final foreground = AppColors.foreground(context, _ink);
    final muted = AppColors.foreground(context, _muted);
    final contact = [
      address.contactName,
      address.contactPhone,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    final street = [
      address.addressLine1,
      address.addressLine2,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
    final icon = switch (address.label.trim().toLowerCase()) {
      'home' => Icons.home_outlined,
      'work' || 'office' => Icons.work_outline_rounded,
      _ => Icons.location_on_outlined,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected ? accent : AppColors.border(context, _line),
        width: selected ? 1.5 : 1,
      ),
    );

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? Color.alphaBlend(
                accent.withValues(alpha: .08),
                AppColors.surface(context, Colors.white),
              )
            : AppColors.surface(context, Colors.white),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: accent, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            address.label.trim().isEmpty
                                ? 'Saved address'
                                : address.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: foreground,
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        street,
                        style: TextStyle(color: foreground, fontSize: 14),
                      ),
                      if (contact.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: selected ? accent : muted,
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
