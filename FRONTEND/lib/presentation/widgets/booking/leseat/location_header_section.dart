import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/routers/app_router.dart';
import '../../../../core/constants/routers/main/main_routes.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../provider/auth/auth_provider.dart';
import '../../../provider/main/address/address_provider.dart';

class LocationHeaderSection extends StatelessWidget {
  final String userName;
  final String address;
  final VoidCallback? onTap;

  const LocationHeaderSection({
    super.key,
    required this.userName,
    required this.address,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userName,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: AppColors.foreground(context, Colors.grey[600]!),
          ),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 4)),
        Row(
          children: [
            Expanded(
              child: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground(context, Colors.black87),
                ),
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: ResponsiveUtils.spacing(context, 4)),
              SvgPicture.asset(
                'assets/images/homepage/Edit.svg',
                width: ResponsiveUtils.fontSize(context, 14),
                height: ResponsiveUtils.fontSize(context, 14),
              ),
            ],
          ],
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.spacing(context, 16),
      ),
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }
}

/// Booking screens location header — always reads the latest saved default address.
class BookingLocationHeader extends ConsumerStatefulWidget {
  final String userName;

  const BookingLocationHeader({
    super.key,
    required this.userName,
  });

  @override
  ConsumerState<BookingLocationHeader> createState() =>
      _BookingLocationHeaderState();
}

class _BookingLocationHeaderState extends ConsumerState<BookingLocationHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadAddresses());
  }

  Future<void> _reloadAddresses() async {
    final authState = ref.read(authProvider);
    final userId = int.tryParse(authState.user?.id ?? '0') ?? 0;
    if (userId > 0) {
      await ref.read(addressProvider.notifier).loadAddresses(userId);
    }
  }

  Future<void> _openSetLocation() async {
    final updated = await AppRouter.push(context, MainRoutes.setLocation);
    if (updated == true && mounted) {
      await _reloadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressProvider);

    return LocationHeaderSection(
      userName: widget.userName,
      address: addressState.deliveryAddressLabel,
      onTap: _openSetLocation,
    );
  }
}
