import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_utils.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import 'lespay_menu_item.dart';
import 'top_up_dialog.dart';

class LinkAccountsSection extends ConsumerWidget {
  const LinkAccountsSection({super.key});

  Future<void> _linkAccount(
    BuildContext context,
    WidgetRef ref,
    String provider,
    String label,
  ) async {
    final linked = await ref.read(lespayProvider.notifier).linkPaymentAccount(
          provider,
        );
    if (!context.mounted) return;

    if (!linked) {
      SnackBarUtils.showError(
        context,
        ref.read(lespayProvider).error ?? 'Could not link $label account.',
      );
      return;
    }

    SnackBarUtils.showSuccess(context, '$label account linked. Verify with a top-up.');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => TopUpDialog(parentContext: context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Maya.svg',
          title: 'Link PayMaya Account',
          backgroundColor: const Color(0xFF00D632),
          useColorFilter: false,
          addStroke: true,
          onTap: () => _linkAccount(context, ref, 'maya', 'PayMaya'),
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Gcash.svg',
          title: 'Link Gcash Account',
          backgroundColor: const Color(0xFF007DFF),
          useColorFilter: false,
          onTap: () => _linkAccount(context, ref, 'gcash', 'GCash'),
        ),
        LespayMenuItem(
          iconPath: 'assets/images/lespay/Bank.svg',
          title: 'Link Bank Account',
          backgroundColor: const Color(0xFF5F2D82),
          iconColor: Colors.white,
          onTap: () => _linkAccount(context, ref, 'bank', 'Bank'),
        ),
      ],
    );
  }
}
