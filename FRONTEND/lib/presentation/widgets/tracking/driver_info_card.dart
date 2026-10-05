import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/driver_display_utils.dart';
import '../../../core/utils/media_url_utils.dart';

class DriverInfoCard extends StatelessWidget {
  final DriverInfo driverInfo;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  const DriverInfoCard({
    Key? key,
    required this.driverInfo,
    this.onCall,
    this.onChat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context, Colors.grey[50]!),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context, Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _DriverAvatar(photoUrl: driverInfo.photoUrl),
          const SizedBox(width: 16),

          // Driver info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        driverInfo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (driverInfo.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driverInfo.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (driverInfo.vehicleType != null)
                  Text(
                    driverInfo.vehicleType!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground(context, Colors.grey[600]!),
                    ),
                  ),
                if (driverInfo.vehicleNumber != null)
                  Text(
                    'Plate: ${driverInfo.vehicleNumber!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground(context, Colors.grey[600]!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              if (onCall != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onCall,
                    tooltip: 'Call Driver',
                  ),
                ),
              const SizedBox(height: 8),
              if (onChat != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chat,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onChat,
                    tooltip: 'Chat with Driver',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  final String? photoUrl;

  const _DriverAvatar({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = MediaUrlUtils.resolve(photoUrl);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[100],
      ),
      clipBehavior: Clip.antiAlias,
      child: resolvedUrl != null
          ? Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.person,
                size: 32,
                color: Colors.blue,
              ),
            )
          : const Icon(
              Icons.person,
              size: 32,
              color: Colors.blue,
            ),
    );
  }
}
