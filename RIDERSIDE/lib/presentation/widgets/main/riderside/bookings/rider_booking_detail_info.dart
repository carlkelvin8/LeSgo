import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../domain/entities/rider_booking.dart';
import '../../../../../../core/utils/media_url_utils.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../../../core/utils/app_localization.dart';
import '../profile/profile_panel.dart';

class RiderBookingDetailInfo extends ConsumerWidget {
  final RiderBooking booking;

  const RiderBookingDetailInfo({super.key, required this.booking});

  bool get _isFoodOrder =>
      booking.category == BookingCategory.lesEat ||
      booking.category == BookingCategory.lesBuy;

  Future<void> _callCustomer(BuildContext context, AppLanguage lang) async {
    final phone = booking.customerPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.translate('cannot_open_dialer', lang)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    String tr(String key) => AppLocalization.translate(key, lang);
    final dark = profileDark(context);
    final accent = dark ? const Color(0xFFCFACED) : const Color(0xFF5F2D82);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF352047), Color(0xFF75459B)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 80,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/booking/services/${booking.serviceArtwork}',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('order_id').replaceAll('{{id}}', booking.id),
                        style: _textStyle(
                          context,
                          12,
                        ).copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.serviceName,
                        style: _textStyle(
                          context,
                          24,
                          bold: true,
                        ).copyWith(color: Colors.white),
                      ),
                      if (_isFoodOrder) ...[
                        const SizedBox(height: 4),
                        Text(
                          booking.restaurantName,
                          style: _textStyle(
                            context,
                            13,
                          ).copyWith(color: Colors.white),
                        ),
                      ],
                      if (booking.distance != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                booking.distance!,
                                style: _textStyle(
                                  context,
                                  12,
                                ).copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  icon: Icons.route_outlined,
                  title: tr('rb_route'),
                ),
                const SizedBox(height: 16),
                _RouteRow(
                  icon: Icons.trip_origin_rounded,
                  iconColor: const Color(0xFF27835B),
                  label: _isFoodOrder
                      ? tr('pick_up_from')
                      : tr('pick_up_label'),
                  value: booking.pickupAddress ?? tr('rb_address_unavailable'),
                  latitude: booking.pickupLat,
                  longitude: booking.pickupLng,
                  pinnedLabel: tr('rb_pickup_pin'),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 17, top: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 20,
                      color: dark
                          ? const Color(0xFF493B56)
                          : const Color(0xFFE5DEEC),
                    ),
                  ),
                ),
                _RouteRow(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFFBD4357),
                  label: tr('deliver_to'),
                  value: booking.deliveryAddress ?? booking.address,
                  latitude: booking.dropoffLat,
                  longitude: booking.dropoffLng,
                  pinnedLabel: tr('rb_dropoff_pin'),
                ),
                if ((booking.pickupAddress ?? '').startsWith('Map pin:') ||
                    (booking.deliveryAddress ?? booking.address).startsWith(
                      'Map pin:',
                    )) ...[
                  const SizedBox(height: 14),
                  Text(
                    tr('rb_pin_hint'),
                    style: _textStyle(context, 12, muted: true),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  icon: Icons.person_outline_rounded,
                  title: tr('customer'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: accent.withValues(alpha: .1),
                      child: Icon(Icons.person_outline_rounded, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        booking.customerName,
                        style: _textStyle(context, 16, bold: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (booking.customerPhone != null &&
                    booking.customerPhone!.isNotEmpty)
                  Material(
                    color: dark
                        ? const Color(0xFF30233F)
                        : const Color(0xFFF6F1FA),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _callCustomer(context, lang),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.call_outlined, size: 20, color: accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                booking.customerPhone!,
                                style: TextStyle(
                                  fontFamily: 'TT Fors',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    tr('no_contact_number'),
                    style: _textStyle(context, 13, muted: true),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  icon: Icons.receipt_long_outlined,
                  title: tr('rb_payment_details'),
                ),
                const SizedBox(height: 18),
                if (booking.itemsSubtotal != null) ...[
                  _MoneyRow(
                    label: tr('items_subtotal'),
                    value: booking.itemsSubtotal!.replaceFirst(
                      'Items subtotal ',
                      '',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (booking.deliveryFee != null) ...[
                  _MoneyRow(
                    label: tr('delivery_fee'),
                    value: booking.deliveryFee!
                        .replaceAll('Delivery fee ', '')
                        .replaceAll('LesPay hold (shipping only) ', ''),
                  ),
                  const SizedBox(height: 12),
                ],
                Divider(
                  height: 1,
                  color: dark
                      ? const Color(0xFF493B56)
                      : const Color(0xFFEDE7F2),
                ),
                const SizedBox(height: 14),
                _MoneyRow(
                  label: tr('order_total'),
                  value: booking.billingAmount.replaceFirst('Order total ', ''),
                  prominent: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: profileMuted(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.billingMethod,
                        style: _textStyle(context, 12, muted: true),
                      ),
                    ),
                  ],
                ),
                if (booking.earnings != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF30233F)
                          : const Color(0xFFF2EDF7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 22,
                          color: accent,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            booking.earnings!,
                            style: TextStyle(
                              fontFamily: 'TT Fors',
                              color: accent,
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (booking.items != null && booking.items!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    icon: Icons.list_alt_rounded,
                    title: tr('items'),
                  ),
                  const SizedBox(height: 14),
                  ...booking.items!.expand(
                    (item) => item.split('\n').map((line) {
                      final detail =
                          line.trimLeft().startsWith('Size:') ||
                          line.trimLeft().startsWith('Flavor:') ||
                          line.trimLeft().startsWith('Add-ons:');
                      return Padding(
                        padding: EdgeInsets.only(
                          left: detail ? 12 : 0,
                          bottom: 6,
                        ),
                        child: Text(
                          detail ? line : '• $line',
                          style: _textStyle(context, 13, muted: detail)
                              .copyWith(
                                fontStyle: detail
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
          if (booking.proofOfDeliveryUrls != null &&
              booking.proofOfDeliveryUrls!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              child: _ProofGrid(urls: booking.proofOfDeliveryUrls!, lang: lang),
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _textStyle(
  BuildContext context,
  double size, {
  bool bold = false,
  bool muted = false,
}) => TextStyle(
  fontFamily: 'TT Fors',
  fontSize: size,
  height: 1.45,
  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
  color: muted ? profileMuted(context) : profileText(context),
);

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: profileDark(context)
          ? const Color(0xFF241D30)
          : const Color(0xFFFAF8FC),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: 20,
        color: profileDark(context)
            ? const Color(0xFFCFACED)
            : const Color(0xFF5F2D82),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: _textStyle(context, 15, bold: true))),
    ],
  );
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });
  final String label;
  final String value;
  final bool prominent;
  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: _textStyle(context, 13, bold: prominent, muted: !prominent),
    );
    final valueWidget = Text(
      value,
      style: _textStyle(context, prominent ? 18 : 14, bold: true).copyWith(
        color: prominent
            ? (profileDark(context)
                  ? const Color(0xFFCFACED)
                  : const Color(0xFF5F2D82))
            : null,
      ),
    );
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [labelWidget, const SizedBox(height: 4), valueWidget],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: labelWidget),
        const SizedBox(width: 12),
        Flexible(
          child: SizedBox(
            width: double.infinity,
            child: Align(alignment: Alignment.centerRight, child: valueWidget),
          ),
        ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double? latitude;
  final double? longitude;
  final String pinnedLabel;

  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.latitude,
    this.longitude,
    required this.pinnedLabel,
  });

  Future<void> _openMap(BuildContext context) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPin =
        latitude != null &&
        longitude != null &&
        latitude!.isFinite &&
        longitude!.isFinite &&
        latitude!.abs() <= 90 &&
        longitude!.abs() <= 180 &&
        (latitude != 0 || longitude != 0);
    final pinOnly =
        value.trim().startsWith('Map pin:') ||
        value.trim().startsWith('Instance of ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        SizedBox(width: ResponsiveUtils.spacing(context, 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 12),
                  color: profileMuted(context),
                ),
              ),
              Text(
                pinOnly && hasPin ? pinnedLabel : value,
                style: TextStyle(
                  fontFamily: 'TT Fors',
                  fontSize: ResponsiveUtils.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: profileText(context),
                ),
              ),
            ],
          ),
        ),
        if (hasPin)
          IconButton(
            tooltip: 'Open in Maps',
            onPressed: () => _openMap(context),
            style: IconButton.styleFrom(
              backgroundColor: profileDark(context)
                  ? const Color(0xFF30233F)
                  : const Color(0xFFF3EEF8),
              foregroundColor: profileDark(context)
                  ? const Color(0xFFCFACED)
                  : const Color(0xFF63368B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.near_me_outlined, size: 20),
          ),
      ],
    );
  }
}

class _ProofGrid extends StatelessWidget {
  final List<String> urls;
  final AppLanguage lang;

  const _ProofGrid({required this.urls, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.translate('proof_of_delivery', lang),
          style: _textStyle(context, 15, bold: true),
        ),
        SizedBox(height: ResponsiveUtils.spacing(context, 8)),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final imageUrl =
                MediaUrlUtils.resolveProofImageUrl(urls[index]) ?? urls[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
