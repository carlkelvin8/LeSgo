import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../presentation/provider/auth/rider_auth_provider.dart';

class RiderPackageTierView extends ConsumerWidget {
  const RiderPackageTierView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    final authState = ref.watch(riderAuthProvider);
    final user = authState.user;
    final currentTier = user?.packageTier ?? 'Standard';
    final hp = ResponsiveUtils.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hp),
      children: [
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        _TierHeader(tier: currentTier, lang: lang),
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        _SectionTitle(title: AppLocalization.translate('features', lang)),
        ..._featuresForTier(currentTier).map(
          (f) => _FeatureTile(icon: f.icon, label: f.label, included: f.included),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 24)),
        _SectionTitle(title: AppLocalization.translate('upgrade_options', lang)),
        ..._availableTiers(currentTier).map(
          (t) => _UpgradeTile(tier: t.name, price: t.price, features: t.features, current: t.name == currentTier, lang: lang),
        ),
      ],
    );
  }

  List<_TierFeature> _featuresForTier(String tier) {
    switch (tier) {
      case 'Premium':
        return const [
          _TierFeature(Icons.directions_car, 'Priority booking assignment', true),
          _TierFeature(Icons.trending_up, 'Higher earnings per trip', true),
          _TierFeature(Icons.support_agent, '24/7 priority support', true),
          _TierFeature(Icons.insights, 'Advanced earnings analytics', true),
          _TierFeature(Icons.flash_on, 'Faster payout processing', true),
          _TierFeature(Icons.local_offer, 'Exclusive promotions', true),
        ];
      case 'Elite':
        return const [
          _TierFeature(Icons.directions_car, 'Priority booking assignment', true),
          _TierFeature(Icons.trending_up, 'Highest earnings per trip', true),
          _TierFeature(Icons.support_agent, '24/7 VIP support', true),
          _TierFeature(Icons.insights, 'Advanced earnings analytics', true),
          _TierFeature(Icons.flash_on, 'Instant payout processing', true),
          _TierFeature(Icons.local_offer, 'Exclusive promotions', true),
          _TierFeature(Icons.diamond, 'Dedicated account manager', true),
          _TierFeature(Icons.airport_shuttle, 'Airport & event priority', true),
        ];
      default:
        return const [
          _TierFeature(Icons.directions_car, 'Standard booking access', true),
          _TierFeature(Icons.trending_up, 'Standard earnings per trip', true),
          _TierFeature(Icons.support_agent, 'Standard support', true),
          _TierFeature(Icons.insights, 'Basic earnings view', true),
          _TierFeature(Icons.flash_on, 'Standard payout processing', true),
          _TierFeature(Icons.lock, 'Exclusive promotions', false),
        ];
    }
  }

  List<_TierOption> _availableTiers(String current) {
    return [
      _TierOption('Standard', 'Free', const ['Basic booking access', 'Standard earnings', 'Standard support']),
      _TierOption('Premium', '₱499/mo', const ['Priority booking', 'Higher earnings', '24/7 priority support', 'Exclusive promotions']),
      _TierOption('Elite', '₱999/mo', const ['Highest earnings', 'VIP support', 'Instant payout', 'Dedicated manager']),
    ];
  }
}

class _TierHeader extends StatelessWidget {
  final String tier;
  final AppLanguage lang;

  const _TierHeader({required this.tier, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isHighTier = tier != 'Standard';
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHighTier
              ? [const Color(0xFF5F2D82), const Color(0xFF7B1FA2)]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isHighTier ? Icons.workspace_premium : Icons.person_outline,
            size: 56,
            color: Colors.white,
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 12)),
          Text(
            tier,
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 24),
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          Text(
            isHighTier ? AppLocalization.translate('premium_package', lang) : AppLocalization.translate('standard_package', lang),
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 16),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5F2D82),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool included;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.included,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: included ? const Color(0xFF5F2D82) : Colors.grey,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: included ? Colors.black87 : Colors.grey,
          ),
        ),
        trailing: Icon(
          included ? Icons.check_circle : Icons.cancel,
          color: included ? Colors.green : Colors.grey.shade400,
          size: 20,
        ),
      ),
    );
  }
}

class _UpgradeTile extends StatelessWidget {
  final String tier;
  final String price;
  final List<String> features;
  final bool current;
  final AppLanguage lang;

  const _UpgradeTile({
    required this.tier,
    required this.price,
    required this.features,
    required this.current,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 12)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: current ? const Color(0xFF5F2D82) : Colors.grey.shade200,
          width: current ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tier,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
            ...features.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 4)),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 16, color: Colors.green.shade600),
                    SizedBox(width: ResponsiveUtils.spacing(context, 8)),
                    Text(
                      f,
                      style: TextStyle(
                        fontFamily: 'TT Fors',
                        fontSize: ResponsiveUtils.fontSize(context, 13),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!current) ...[
              SizedBox(height: ResponsiveUtils.spacing(context, 12)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalization.translate('upgrade_option_soon', lang))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F2D82),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(AppLocalization.translate('upgrade_to', lang).replaceAll('{{tier}}', tier)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TierFeature {
  final IconData icon;
  final String label;
  final bool included;

  const _TierFeature(this.icon, this.label, this.included);
}

class _TierOption {
  final String name;
  final String price;
  final List<String> features;

  const _TierOption(this.name, this.price, this.features);
}
