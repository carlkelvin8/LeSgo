import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/merchant_staff_permissions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/partner_staff_dto.dart';
import '../../../provider/main/merchantside/merchant_staff_provider.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Staff Accounts',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            color: const Color(0xFF5F2D82),
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5F2D82),
        onRefresh: () => ref.read(merchantStaffProvider.notifier).loadStaff(),
        child: state.isLoading && state.staff.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.staff.isEmpty
                ? _errorView(context, hp)
                : state.staff.isEmpty
                    ? _emptyView(context, hp)
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          left: hp,
                          right: hp,
                          top: ResponsiveUtils.spacing(context, 16),
                          bottom: ResponsiveUtils.spacing(context, 24),
                        ),
                        itemCount: state.staff.length,
                        itemBuilder: (context, index) {
                          final member = state.staff[index];
                          return _staffTile(context, member);
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Invite Staff'),
        onPressed: _showInviteDialog,
      ),
    );
  }

  Widget _errorView(BuildContext context, double hp) {
    final err = ref.read(merchantStaffProvider).error;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(hp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load staff',
              style: TextStyle(fontFamily: 'TT Fors', fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(err ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(merchantStaffProvider.notifier).loadStaff(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView(BuildContext context, double hp) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(hp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No staff yet',
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite your team members to help manage orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staffTile(BuildContext context, PartnerStaffDto member) {
    final color = member.isActive ? const Color(0xFF5F2D82) : Colors.grey;
    final roleColor = member.isAdmin
        ? const Color(0xFF5F2D82)
        : member.isCook
            ? Colors.orange.shade700
            : Colors.teal.shade700;

    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.spacing(context, 8),
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                member.name.isNotEmpty
                    ? member.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 15),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    member.email,
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 11),
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member.roleLabel,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 10),
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
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
                      Icon(Icons.swap_horiz, size: 18),
                      SizedBox(width: 8),
                      Text('Change Role'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        member.isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: member.isActive ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(member.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
  State<_InviteStaffDialogContent> createState() => _InviteStaffDialogContentState();
}

class _InviteStaffDialogContentState extends State<_InviteStaffDialogContent> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  late String _selectedRole;

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allow back button to close dialog
      onPopInvokedWithResult: (didPop, result) {
        // When back button is pressed, dialog closes with null result
        // This ensures we stay on Staff Accounts screen
      },
      child: AlertDialog(
        title: const Text(
          'Invite Staff',
          style: TextStyle(fontFamily: 'TT Fors'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'cook', child: Text('Cook')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedRole = v);
                    widget.onRoleChanged(v);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                MerchantStaffPermissions.descriptionForRole(_selectedRole),
                style: const TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog without result
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final result = {
                'name': _nameCtrl.text.trim(),
                'email': _emailCtrl.text.trim(),
                'password': _passCtrl.text.trim(),
                'role': _selectedRole,
              };
              Navigator.pop(context, result);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
            ),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}
