import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../provider/auth/rider_auth_provider.dart';

class MerchantProfileInfoSection extends ConsumerWidget {
  const MerchantProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(merchantProfileProvider);

    return profileAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(height: 100),
      data: (profile) {
        if (profile == null) return const SizedBox(height: 100);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info(context, 'Restaurant:', profile.name),
            _info(context, 'Contact:', profile.supportPhone ?? 'Not set'),
            _info(context, 'Email:', profile.supportEmail ?? 'Not set'),
            _statusToggle(context, ref, profile.isOpen ?? false),
            _info(
              context,
              'Referral Code:',
              profile.referralCode ?? 'LESGO${profile.name.toUpperCase().replaceAll(' ', '')}',
              valueColor: const Color(0xFFC320D6),
            ),
          ],
        );
      },
    );
  }

  Widget _info(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _statusToggle(BuildContext context, WidgetRef ref, bool isOpen) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 14),
              ),
              children: [
                TextSpan(
                  text: 'Store Status: ',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: isOpen ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    color: isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOpen,
            activeColor: Colors.green,
            onChanged: (value) async {
              try {
                final authState = ref.read(riderAuthProvider);
                final partnerId = authState.user?.partnerId;
                if (partnerId != null) {
                  final dataSource = ref.read(merchantDataSourceProvider);
                  await dataSource.updatePartnerProfile(
                    partnerId,
                    UpdatePartnerRequest(isOpen: value),
                  );
                  ref.invalidate(merchantProfileProvider);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Store is now ${value ? "OPEN" : "CLOSED"}'),
                        backgroundColor: value ? Colors.green : Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
