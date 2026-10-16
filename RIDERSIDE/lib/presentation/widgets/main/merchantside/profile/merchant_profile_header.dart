import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/media_url_utils.dart';
import '../../../../../../core/utils/responsive_utils.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../screens/main/merchantside/merchant_edit_information_screen.dart';

class MerchantProfileHeader extends ConsumerWidget {
  const MerchantProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(merchantProfileProvider);

    return profileAsync.when(
      loading: () => const SizedBox(height: 126),
      error: (_, __) => const SizedBox(height: 126),
      data: (profile) {
        if (profile == null) return const SizedBox(height: 126);

        return Container(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF4ECFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE9DDF1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'LeSgo,\nPartner!',
                  style: TextStyle(
                    fontFamily: 'TT Fors',
                    fontSize: ResponsiveUtils.fontSize(context, 36),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF5F2D82),
                    height: 0.96,
                    letterSpacing: -1.1,
                  ),
                ),
              ),
            SizedBox(width: ResponsiveUtils.spacing(context, 12)),
            GestureDetector(
              onTap: () {
                // Navigate to edit screen where they can change the logo
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MerchantEditInformationScreen(),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: ResponsiveUtils.spacing(context, 126),
                    height: ResponsiveUtils.spacing(context, 126),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.spacing(context, 16),
                      ),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: MediaUrlUtils.resolve(profile.logoUrl) != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ResponsiveUtils.spacing(context, 16),
                            ),
                            child: Image.network(
                              MediaUrlUtils.resolve(profile.logoUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultLogo(context, profile.name);
                              },
                            ),
                          )
                        : _buildDefaultLogo(context, profile.name),
                  ),
                  // Camera edit overlay
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F2D82),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultLogo(BuildContext context, String name) {
    // Extract first letters of each word (max 2 words)
    final words = name.split(' ').take(2).toList();
    final initials = words.map((w) => w.isNotEmpty ? w[0] : '').join('');

    return Center(
      child: Text(
        initials.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'TT Fors',
          fontSize: ResponsiveUtils.fontSize(context, 32),
          fontWeight: FontWeight.w900,
          color: const Color(0xFF5F2D82),
          height: 0.9,
        ),
      ),
    );
  }
}
