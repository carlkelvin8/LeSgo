import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/services/api_service.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../../../data/data_source/merchant_remote_datasource.dart';
import '../../../../provider/auth/rider_auth_provider.dart';

class MerchantProfileInfoSection extends ConsumerWidget {
  const MerchantProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(merchantProfileProvider);
    final referralAsync = ref.watch(merchantReferralCodeProvider);

    return profileAsync.when(
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(height: 100),
      data: (profile) {
        if (profile == null) return const SizedBox(height: 100);

        final referralLabel = referralAsync.when(
          loading: () => 'Loading...',
          error: (_, __) => 'Not set',
          data: (code) => code.isNotEmpty ? code : 'Not set',
        );

        final prepTime = profile.estimatedDeliveryMinutes;
        final hours = profile.openingHours;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info(context, 'Restaurant:', profile.name),
            _info(context, 'Contact:', profile.supportPhone ?? 'Not set'),
            _info(context, 'Email:', profile.supportEmail ?? 'Not set'),
            if (prepTime != null && prepTime > 0)
              _info(
                context,
                'Prep Time:',
                '~$prepTime min',
                valueColor: const Color(0xFF5F2D82),
              ),
            _MerchantStoreStatusToggle(initialIsOpen: profile.isOpen ?? false),
            if (hours != null && hours.isNotEmpty)
              _OperatingHoursSummary(hours: hours),
            _info(
              context,
              'Referral Code:',
              referralLabel,
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
}

class _MerchantStoreStatusToggle extends ConsumerStatefulWidget {
  const _MerchantStoreStatusToggle({required this.initialIsOpen});

  final bool initialIsOpen;

  @override
  ConsumerState<_MerchantStoreStatusToggle> createState() =>
      _MerchantStoreStatusToggleState();
}

class _MerchantStoreStatusToggleState
    extends ConsumerState<_MerchantStoreStatusToggle> {
  late bool _isOpen;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.initialIsOpen;
  }

  @override
  void didUpdateWidget(covariant _MerchantStoreStatusToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isUpdating && oldWidget.initialIsOpen != widget.initialIsOpen) {
      _isOpen = widget.initialIsOpen;
    }
  }

  Future<void> _onChanged(bool value) async {
    if (_isUpdating) return;

    final previous = _isOpen;
    setState(() {
      _isOpen = value;
      _isUpdating = true;
    });

    try {
      final authState = ref.read(riderAuthProvider);
      final profile = ref.read(merchantProfileProvider).value;
      final partnerId = authState.user?.partnerId ?? profile?.id;

      if (partnerId == null) {
        throw Exception('Partner ID not found. Please login again.');
      }

      final dataSource = ref.read(merchantDataSourceProvider);
      final updated = await dataSource.toggleStoreStatus(partnerId, value);

      if (!mounted) return;

      setState(() {
        _isOpen = updated.isOpen ?? value;
        _isUpdating = false;
      });
      ref.invalidate(merchantProfileProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Store is now ${_isOpen ? "OPEN" : "CLOSED"}'),
          backgroundColor: _isOpen ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isOpen = previous;
        _isUpdating = false;
      });
      ref.invalidate(merchantProfileProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.extractError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  text: _isOpen ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    color: _isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOpen,
            onChanged: _isUpdating ? null : _onChanged,
            activeTrackColor: Colors.green.shade300,
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _OperatingHoursSummary extends StatelessWidget {
  final Map<String, dynamic> hours;

  const _OperatingHoursSummary({required this.hours});

  static const _dayOrder = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];

  static const _dayLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (final day in _dayOrder) {
      final data = hours[day];
      if (data == null) continue;

      final isClosed = data['closed'] as bool? ?? false;
      final open = data['open'] as String? ?? '--:--';
      final close = data['close'] as String? ?? '--:--';

      items.add(
        Padding(
          padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 4)),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  _dayLabels[day]!,
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isClosed ? 'Closed' : '$open — $close',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 12),
                    fontWeight: FontWeight.w500,
                    color: isClosed ? Colors.red.shade400 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operating Hours:',
            style: TextStyle(
              fontFamily: 'TT Fors',
              fontSize: ResponsiveUtils.fontSize(context, 14),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 4)),
          ...items,
        ],
      ),
    );
  }
}
