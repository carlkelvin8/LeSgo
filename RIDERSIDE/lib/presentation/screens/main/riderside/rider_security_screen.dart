import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_localization.dart';

class RiderSecurityScreen extends ConsumerWidget {
  const RiderSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(
          AppLocalization.translate('security', lang),
          style: const TextStyle(fontFamily: 'TT Fors'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security_update_good_outlined,
              size: 80,
              color: const Color(0xFF5F2D82).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalization.translate('coming_soon', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5F2D82),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalization.translate('coming_soon_message', lang),
              style: TextStyle(
                fontFamily: 'TT Fors',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
