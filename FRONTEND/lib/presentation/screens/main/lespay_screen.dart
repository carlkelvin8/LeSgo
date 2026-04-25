import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/main/lespay/lespay_provider.dart';
import '../../widgets/widgets.dart';
import '../../../core/utils/responsive_utils.dart';

class LespayScreen extends ConsumerWidget {
  const LespayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lespayState = ref.watch(lespayProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
              child: const AuthHeader(
                title: 'LesPay',
              ),
            ),

            WalletCard(
              balance: lespayState.balance,
              onTap: () {
                // TODO: Show wallet details
              },
            ),

            SizedBox(height: ResponsiveUtils.spacing(context, 16)),

            const Expanded(
              child: Column(
                children: [
                  CustomDivider(),
                  LespayActionsSection(),
                  CustomDivider(),
                  SectionHeader(title: 'Link Account'),
                  LinkAccountsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
