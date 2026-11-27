import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The app's own artwork for each service (the same illustrations used on
/// Home and the booking screens), so lists never fall back to generic icons.
///
/// Anything that isn't one specific service ("All Services", unknown) shows
/// the LeSgo app icon.
class ServiceIcon extends StatelessWidget {
  const ServiceIcon(this.service, {super.key, this.size = 44});

  /// "LesRide", "LesGo", "LesEat", "LesBuy", "LesPay" (case/spacing tolerant).
  final String service;
  final double size;

  static const _assets = {
    'lesride': 'assets/images/book/Lesride.svg',
    'lestransport': 'assets/images/book/Lesride.svg',
    'lesgo': 'assets/images/book/Lesgo.svg',
    'leseat': 'assets/images/book/Leseat.svg',
    'lesbuy': 'assets/images/book/Lesbuy.svg',
    'lesbuymanual': 'assets/images/book/Lesbuy.svg',
    'lesport': 'assets/images/book/Lesport.svg',
    'lespay': 'assets/images/homepage/Wallet.svg',
  };

  /// Asset path for [service], or null when it isn't one specific service.
  static String? assetFor(String service) =>
      _assets[service.toLowerCase().replaceAll(RegExp(r'[\s_]'), '')];

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(service);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: asset != null
            ? SvgPicture.asset(asset, fit: BoxFit.contain)
            : ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.28),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.apps_rounded,
                    size: size * 0.6,
                    color: const Color(0xFF5F2D82),
                  ),
                ),
              ),
      ),
    );
  }
}
