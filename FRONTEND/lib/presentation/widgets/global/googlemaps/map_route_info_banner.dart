import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MapRouteInfoBanner extends StatelessWidget {
  const MapRouteInfoBanner({
    super.key,
    required this.isLoadingRoute,
    this.distanceKm,
    this.durationSec,
    this.hintText = 'Tap "Confirm location" to calculate route',
    this.accentColor = const Color(0xFF4285F4),
  });

  final bool isLoadingRoute;
  final double? distanceKm;
  final int? durationSec;
  final String hintText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.white),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoadingRoute
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Calculating route...',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            )
          : distanceKm != null
              ? Row(
                  children: [
                    Icon(Icons.route, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Route: ${distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (durationSec != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${(durationSec! / 60).ceil()} min',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                )
              : Text(hintText, style: const TextStyle(fontSize: 14)),
    );
  }
}
