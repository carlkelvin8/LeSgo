import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';

class RiderLanguageView extends ConsumerWidget {
  const RiderLanguageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final hp = ResponsiveUtils.horizontalPadding(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: hp),
      children: [
        SizedBox(height: ResponsiveUtils.spacing(context, 16)),
        _LangTile(
          title: 'English',
          subtitle: 'English',
          selected: currentLang == AppLanguage.english,
          onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.english),
        ),
        _LangTile(
          title: 'Filipino',
          subtitle: 'Tagalog',
          selected: currentLang == AppLanguage.filipino,
          onTap: () => ref.read(appLanguageProvider.notifier).setLanguage(AppLanguage.filipino),
        ),
      ],
    );
  }
}

class _LangTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveUtils.spacing(context, 10)),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? const Color(0xFF5F2D82) : Colors.grey.shade200, width: selected ? 2 : 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF5F2D82).withValues(alpha: 0.1),
          child: Text(
            title[0],
            style: const TextStyle(
              color: Color(0xFF5F2D82),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtils.fontSize(context, 14),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'TT Fors',
            fontSize: ResponsiveUtils.fontSize(context, 12),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFF5F2D82))
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
