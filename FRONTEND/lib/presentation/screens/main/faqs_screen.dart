import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../provider/main/faq/faq_provider.dart';
import '../../widgets/widgets.dart';

class FaqsScreen extends ConsumerWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faqState = ref.watch(faqProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
                    padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
                    child: const AuthHeader(
                      title: 'FAQs',
                    ),
                  ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 24)),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/images/faq/Faq.svg',
                        height: ResponsiveUtils.imageHeight(context, 300),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 32)),
                      ...faqState.faqs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final faq = entry.value;
                        return FaqItem(
                          faq: faq,
                          isFirst: index == 0,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
