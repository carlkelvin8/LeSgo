import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/merchant_staff_permissions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/partner_staff_dto.dart';
import '../../../provider/main/merchantside/merchant_staff_provider.dart';
import '../../../widgets/common/settings_page_kit.dart';

class MerchantStaffScreen extends ConsumerStatefulWidget {
  const MerchantStaffScreen({super.key});

  @override
  ConsumerState<MerchantStaffScreen> createState() =>
      _MerchantStaffScreenState();
}

class _MerchantStaffScreenState extends ConsumerState<MerchantStaffScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(merchantStaffProvider.notifier).loadStaff();
    });
  }

  Future<void> _showInviteDialog() async {
    var selectedRole = 'cashier';

    final result = await showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: true, // Allow tapping outside to dismiss
      builder: (ctx) => _InviteStaffDialogContent(
        initialRole: selectedRole,
        onRoleChanged: (role) => selectedRole = role,
      ),
    );

    // If dialog was dismissed (null result), just return without showing error
    if (result == null || !mounted) return;

    final name = result['name'] ?? '';
    final email = result['email'] ?? '';
    final password = result['password'] ?? '';
    final role = result['role'] ?? 'cashier';

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      SnackBarUtils.showError(context, 'All fields are required');
      return;
    }

    final ok = await ref
        .read(merchantStaffProvider.notifier)
        .inviteStaff(name: name, email: email, password: password, role: role);

    if (!mounted) return;

    if (ok) {
      SnackBarUtils.showSuccess(context, 'Staff invited successfully');
    } else {
      final error = ref.read(merchantStaffProvider).error;
      SnackBarUtils.showError(context, error ?? 'Failed to invite staff');
    }
  }

  Future<void> _confirmRemove(int staffId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff', style: TextStyle(fontFamily: 'TT Fors')),
        content: Text('Remove $name from your staff? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ref.read(merchantStaffProvider.notifier).removeStaff(staffId);
      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Staff removed');
      } else {
        SnackBarUtils.showError(context, 'Failed to remove staff');
      }
    }
  }

  Future<void> _changeRole(int staffId, String currentRole) async {
    var newRole = currentRole;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Role', style: TextStyle(fontFamily: 'TT Fors')),
          content: DropdownButtonFormField<String>(
            initialValue: newRole,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'cook', child: Text('Cook')),
              DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
            ],
            onChanged: (v) {
              if (v != null) setDialogState(() => newRole = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, newRole),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != currentRole) {
      final ok = await ref
          .read(merchantStaffProvider.notifier)
          .updateStaff(staffId, role: result);
      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Role updated');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantStaffProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);
    final hasStaff = state.staff.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SettingsKit.appBar(context, ''),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsPageHeader(
            title: 'Staff Accounts',
            subtitle: 'Manage who can help run your store',
            padding: EdgeInsets.fromLTRB(hp, 0, hp, 12),
          ),
          Expanded(child: _body(state, hp, hasStaff)),
        ],
      ),
      floatingActionButton: hasStaff
          ? FloatingActionButton.extended(
              backgroundColor: SettingsKit.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Invite Staff',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: _showInviteDialog,
            )
          : null,
    );
  }

  Widget _body(MerchantStaffState state, double hp, bool hasStaff) {
    return RefreshIndicator(
        color: SettingsKit.brand,
        onRefresh: () => ref.read(merchantStaffProvider.notifier).loadStaff(),
        child: state.isLoading && !hasStaff
            ? const Center(
                child: CircularProgressIndicator(color: SettingsKit.brand),
              )
            : state.error != null && !hasStaff
                ? SettingsScrollableEmpty(
                    child: SettingsEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Failed to load staff',
                      subtitle: state.error ?? 'Please try again.',
                      actionLabel: 'Retry',
                      actionIcon: Icons.refresh_rounded,
                      onAction: () =>
                          ref.read(merchantStaffProvider.notifier).loadStaff(),
                    ),
                  )
                : !hasStaff
                    ? SettingsScrollableEmpty(
                        child: SettingsEmptyState(
                          icon: Icons.group_outlined,
                          title: 'No staff yet',
                          subtitle:
                              'Invite your team members to help you manage orders, the menu and the kitchen.',
                          actionLabel: 'Invite staff',
                          actionIcon: Icons.person_add_alt_1_rounded,
                          onAction: _showInviteDialog,
                        ),
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(hp, 8, hp, 100),
                        children: [
                          _summaryCard(state.staff),
                          const SizedBox(height: 24),
                          const SettingsSectionLabel('Team members'),
                          ...state.staff.map((m) => _staffTile(context, m)),
                        ],
                      ),
    );
  }

  Widget _summaryCard(List<PartnerStaffDto> staff) {
    final active = staff.where((m) => m.isActive).length;
    Widget stat(String value, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SettingsKit.brandLight, SettingsKit.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: SettingsKit.brand.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          stat('${staff.length}', 'Members'),
          stat('$active', 'Active'),
          stat('${staff.length - active}', 'Inactive'),
        ],
      ),
    );
  }

  Widget _staffTile(BuildContext context, PartnerStaffDto member) {
    final roleColor = member.isAdmin
        ? SettingsKit.brand
        : member.isCook
            ? SettingsKit.warning
            : SettingsKit.success;
    final roleIcon = member.isAdmin
        ? Icons.admin_panel_settings_outlined
        : member.isCook
            ? Icons.soup_kitchen_outlined
            : Icons.point_of_sale_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      decoration: SettingsKit.cardDecoration(),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: member.isActive
                    ? SettingsKit.brandTint
                    : Colors.grey.shade200,
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: member.isActive
                        ? SettingsKit.brand
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: member.isActive
                        ? SettingsKit.success
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 15),
                    fontWeight: FontWeight.w800,
                    color: member.isActive
                        ? SettingsKit.ink
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    color: SettingsKit.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(roleIcon, size: 13, color: roleColor),
                          const SizedBox(width: 4),
                          Text(
                            member.roleLabel,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!member.isActive)
                      SettingsStatusPill(
                        label: 'Inactive',
                        color: Colors.grey.shade600,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) {
              switch (value) {
                case 'role':
                  _changeRole(member.id, member.role);
                case 'toggle':
                  ref.read(merchantStaffProvider.notifier).updateStaff(
                        member.id,
                        isActive: !member.isActive,
                      );
                case 'remove':
                  _confirmRemove(member.id, member.name);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'role',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded,
                        size: 18, color: SettingsKit.brand),
                    SizedBox(width: 10),
                    Text('Change Role'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      member.isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: member.isActive
                          ? SettingsKit.warning
                          : SettingsKit.success,
                    ),
                    const SizedBox(width: 10),
                    Text(member.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: SettingsKit.danger),
                    SizedBox(width: 10),
                    Text('Remove', style: TextStyle(color: SettingsKit.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// StatefulWidget for Invite Staff Dialog
class _InviteStaffDialogContent extends StatefulWidget {
  final String initialRole;
  final Function(String) onRoleChanged;

  const _InviteStaffDialogContent({
    required this.initialRole,
    required this.onRoleChanged,
  });

  @override
  State<_InviteStaffDialogContent> createState() =>
      _InviteStaffDialogContentState();
}

class _InviteStaffDialogContentState extends State<_InviteStaffDialogContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  late String _selectedRole;
  bool _obscure = true;

  static const _roles = [
    ('admin', 'Admin', Icons.admin_panel_settings_outlined),
    ('cook', 'Cook', Icons.soup_kitchen_outlined),
    ('cashier', 'Cashier', Icons.point_of_sale_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passCtrl = TextEditingController();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: SettingsKit.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: SettingsKit.pageBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SettingsKit.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SettingsKit.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SettingsKit.brand, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SettingsIconBox(icon: Icons.person_add_alt_1_rounded),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Staff',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: SettingsKit.ink,
                        ),
                      ),
                      Text(
                        'They can sign in with these details',
                        style: TextStyle(
                          fontFamily: 'TT Fors',
                          fontSize: 12,
                          color: SettingsKit.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: SettingsKit.muted,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Full Name', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration('Email', Icons.mail_outline_rounded),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: _decoration(
                'Temporary Password',
                Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: SettingsKit.muted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Role',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: SettingsKit.ink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (value, label, icon) in _roles) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedRole = value);
                        widget.onRoleChanged(value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedRole == value
                              ? SettingsKit.brandTint
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedRole == value
                                ? SettingsKit.brand
                                : SettingsKit.border,
                            width: _selectedRole == value ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: _selectedRole == value
                                  ? SettingsKit.brand
                                  : SettingsKit.muted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'TT Fors',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _selectedRole == value
                                    ? SettingsKit.brand
                                    : SettingsKit.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (value != _roles.last.$1) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SettingsKit.pageBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: SettingsKit.brand),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MerchantStaffPermissions.descriptionForRole(
                          _selectedRole),
                      style: const TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: 12,
                        height: 1.4,
                        color: SettingsKit.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': _nameCtrl.text.trim(),
                  'email': _emailCtrl.text.trim(),
                  'password': _passCtrl.text.trim(),
                  'role': _selectedRole,
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: SettingsKit.brand,
                minimumSize: const Size(0, 50),
                textStyle: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }
}
