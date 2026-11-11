import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/data_source/dto/merchant/partner_branch.dart';
import '../../../provider/main/merchantside/merchant_branches_provider.dart';
import 'merchant_branch_form_screen.dart';
import '../../../../core/utils/dark_aware_colors.dart';

const _purple = Color(0xFF5F2D82);

/// Lists the store's branches. Each branch is a separate pickup point that
/// customers choose at checkout and riders navigate to.
class MerchantBranchesScreen extends ConsumerStatefulWidget {
  const MerchantBranchesScreen({super.key});

  @override
  ConsumerState<MerchantBranchesScreen> createState() =>
      _MerchantBranchesScreenState();
}

class _MerchantBranchesScreenState
    extends ConsumerState<MerchantBranchesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(merchantBranchesProvider.notifier).loadBranches(),
    );
  }

  Future<void> _openForm([PartnerBranch? branch]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MerchantBranchFormScreen(branch: branch)),
    );
  }

  Future<void> _run(Future<String?> action, String success) async {
    final error = await action;
    if (!mounted) return;
    if (error == null) {
      SnackBarUtils.showSuccess(context, success);
    } else {
      SnackBarUtils.showError(context, error);
    }
  }

  Future<void> _confirmDelete(PartnerBranch branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete branch', style: TextStyle(fontFamily: 'TT Fors')),
        content: Text(
          'Delete ${branch.name}? Customers will no longer be able to order from it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(
      ref.read(merchantBranchesProvider.notifier).deleteBranch(branch),
      'Branch deleted',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(merchantBranchesProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return Scaffold(
      backgroundColor: context.bg(const Color(0xFFF8F9FA)),
      appBar: AppBar(
        backgroundColor: context.surf(Colors.white),
        elevation: 0,
        iconTheme: IconThemeData(color: context.txt(Colors.black87)),
        centerTitle: true,
        title: Text(
          'Branches',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: context.txt(Colors.black87),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add Branch'),
        onPressed: state.isSaving ? null : () => _openForm(),
      ),
      body: RefreshIndicator(
        color: _purple,
        onRefresh: () => ref.read(merchantBranchesProvider.notifier).loadBranches(),
        child: state.isLoading && state.branches.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.branches.isEmpty
                ? _message(context, Icons.error_outline, state.error!)
                : state.branches.isEmpty
                    ? _message(
                        context,
                        Icons.storefront_outlined,
                        'No branches yet. Add your first pickup location.',
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(hp, 16, hp, 96),
                        children: [
                          Text(
                            'Customers pick a branch when ordering, and riders are sent to that branch for pickup.',
                            style: TextStyle(fontSize: 13, color: context.sub(Colors.grey[600]!)),
                          ),
                          const SizedBox(height: 12),
                          ...state.branches.map((b) => _branchCard(context, b, state.isSaving)),
                        ],
                      ),
      ),
    );
  }

  Widget _message(BuildContext context, IconData icon, String text) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(icon, size: 56, color: context.sub(Colors.grey[400]!)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: context.sub(Colors.grey[600]!))),
        ),
      ],
    );
  }

  Widget _branchCard(BuildContext context, PartnerBranch branch, bool busy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.brd(Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    branch.name,
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (branch.isPrimary) _chip('Primary', _purple),
                const SizedBox(width: 6),
                _chip(
                  branch.isOpen ? 'Open' : 'Closed',
                  branch.isOpen ? Colors.green.shade700 : Colors.red.shade700,
                ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  onSelected: (value) {
                    final notifier = ref.read(merchantBranchesProvider.notifier);
                    switch (value) {
                      case 'edit':
                        _openForm(branch);
                      case 'primary':
                        _run(notifier.makePrimary(branch), '${branch.name} is now your primary branch');
                      case 'delete':
                        _confirmDelete(branch);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (!branch.isPrimary)
                      const PopupMenuItem(value: 'primary', child: Text('Make primary')),
                    if (!branch.isPrimary)
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, size: 16, color: context.sub(Colors.grey[600]!)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    branch.fullAddress.isEmpty ? 'No address' : branch.fullAddress,
                    style: TextStyle(fontSize: 13, color: context.sub(Colors.grey[700]!)),
                  ),
                ),
              ],
            ),
            if (!branch.hasLocation)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'No map pin yet. Edit this branch to set its pickup point.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeThumbColor: _purple,
              title: const Text('Accepting orders'),
              value: branch.isOpen,
              onChanged: busy
                  ? null
                  : (open) => _run(
                        ref.read(merchantBranchesProvider.notifier).setOpen(branch, open),
                        open ? '${branch.name} is open' : '${branch.name} is closed',
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
