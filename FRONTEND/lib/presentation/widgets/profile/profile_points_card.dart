import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfilePointsCard extends StatelessWidget {
  final int points;
  final VoidCallback? onTap;
  const ProfilePointsCard({super.key, required this.points, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface(context, Color(0xFF342441)),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface(context, Color(0xFF51405E)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFE8D0AB),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Your little rewards',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      color: AppColors.foreground(context, Color(0xFFCABCD5)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$points points',
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.6,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Explore your rewards',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 11,
                      color: Color(0xFFE8D0AB),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
