import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/utils/responsive_utils.dart';
import '../../../../../core/utils/rider_commission_utils.dart';

/// Provider to track selected package during registration
final selectedRegistrationPackageProvider = StateProvider<String?>((ref) => null);

/// Package selection step shown during rider registration.
/// Rider must choose Basic, Advance, or Elite before proceeding.
class RiderPackageSelectionStep extends ConsumerWidget {
  final VoidCallback onPackageSelected;

  const RiderPackageSelectionStep({
    super.key,
    required this.onPackageSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPackage = ref.watch(selectedRegistrationPackageProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Package',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 22),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5F2D82),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 8)),
          Text(
            'Select a rider package to get started. Payment will be settled before your account is activated.',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 13),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          _PackageCard(
            tier: 'basic',
            label: 'Basic',
            price: RiderCommissionUtils.basicOneTimePrice,
            profitShare: '70/30 profit share (you keep 70%)',
            features: const ['Booking access', 'Admin support'],
            isSelected: selectedPackage == 'basic',
            onTap: () => ref.read(selectedRegistrationPackageProvider.notifier).state = 'basic',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          _PackageCard(
            tier: 'advance',
            label: 'Advance',
            price: RiderCommissionUtils.advanceOneTimePrice,
            profitShare: '80/20 profit share with free uniform and bag',
            features: const ['Booking access', 'Admin support', 'Free uniform', 'Free bag'],
            isSelected: selectedPackage == 'advance',
            isPopular: true,
            onTap: () => ref.read(selectedRegistrationPackageProvider.notifier).state = 'advance',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 14)),
          _PackageCard(
            tier: 'pro',
            label: 'Elite',
            price: RiderCommissionUtils.proOneTimePrice,
            profitShare: '90/10 profit share with free uniform and bag',
            features: const ['Booking access', 'Admin support', 'Free uniform', 'Free bag', 'Exclusive promotions'],
            isSelected: selectedPackage == 'pro',
            onTap: () => ref.read(selectedRegistrationPackageProvider.notifier).state = 'pro',
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedPackage != null ? onPackageSelected : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F2D82),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: EdgeInsets.symmetric(
                  vertical: ResponsiveUtils.spacing(context, 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                selectedPackage != null
                    ? 'Continue with ${RiderCommissionUtils.labelForPackage(selectedPackage)} Package'
                    : 'Select a package to continue',
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Center(
            child: Text(
              'Payment will be settled with admin after registration.\nAdmin approval is required before account activation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 11),
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String tier;
  final String label;
  final double price;
  final String profitShare;
  final List<String> features;
  final bool isSelected;
  final bool isPopular;
  final VoidCallback onTap;

  const _PackageCard({
    required this.tier,
    required this.label,
    required this.price,
    required this.profitShare,
    required this.features,
    required this.isSelected,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F2D82).withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F2D82) : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF5F2D82).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle, color: Color(0xFF5F2D82), size: 22),
                      ),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 18),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5F2D82),
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'POPULAR',
                          style: TextStyle(
                            fontFamily: 'TT Fors',
                            fontSize: ResponsiveUtils.fontSize(context, 9),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₱${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 14),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            Text(
              profitShare,
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: ResponsiveUtils.fontSize(context, 12),
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 10)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: features
                  .map((f) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            f,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: ResponsiveUtils.fontSize(context, 11),
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
