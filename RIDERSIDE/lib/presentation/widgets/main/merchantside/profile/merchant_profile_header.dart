import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/menu_image_widget.dart';
import '../../../../provider/main/merchantside/merchant_profile_provider.dart';
import '../../../../screens/main/merchantside/merchant_edit_information_screen.dart';

class MerchantProfileHeader extends ConsumerWidget {
  const MerchantProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(merchantProfileProvider).valueOrNull;
    if (profile == null) return const SizedBox.shrink();
    void edit() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MerchantEditInformationScreen()),
    );
    final initials = profile.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR BUSINESS',
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: 10,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w700,
            color: Color(0xFF82788B),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Semantics(
              button: true,
              label: 'Edit store photo',
              child: InkWell(
                onTap: edit,
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE5F3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MenuImageWidget(
                        source: profile.logoUrl,
                        fit: BoxFit.cover,
                        placeholder: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontFamily: 'TT Fors',
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5F2D82),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F2D82),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LeSgo Partner',
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7B568F),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: 25,
                      height: 1.15,
                      letterSpacing: -.7,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF28212E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: edit,
            icon: const Icon(Icons.tune_rounded, size: 17),
            label: const Text('Edit business profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5F2D82),
              side: const BorderSide(color: Color(0xFFDFD5E6)),
              minimumSize: const Size(0, 44),
              textStyle: const TextStyle(
                fontFamily: 'TT Fors',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
