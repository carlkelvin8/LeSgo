import 'package:lesgo/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(appLanguageProvider);
  }

  Future<void> _select(AppLanguage language) async {
    if (language == _selected) return;
    setState(() => _selected = language);
    await ref.read(appLanguageProvider.notifier).setLanguage(language);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    SnackBarUtils.showSuccess(context, tr(context, 'language_changed'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'language')),
      ),
      body: RadioGroup<AppLanguage>(
        groupValue: _selected,
        onChanged: (v) {
          if (v != null) _select(v);
        },
        child: ListView(
          padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
          children: [
            RadioListTile<AppLanguage>(
              title: Text(tr(context, 'english')),
              subtitle: const Text('Default app language'),
              value: AppLanguage.english,
              activeColor: const Color(0xFF5F2D82),
            ),
            RadioListTile<AppLanguage>(
              title: Text(tr(context, 'filipino')),
              subtitle: const Text('Mas madaling maintindihan para sa mga user sa PH'),
              value: AppLanguage.filipino,
              activeColor: const Color(0xFF5F2D82),
            ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          Container(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 14)),
            decoration: BoxDecoration(
              color: AppColors.surface(context, Color(0xFFF8F4FF)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(context, Color(0xFFE1D4F7))),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF5F2D82), size: 20),
                SizedBox(width: ResponsiveUtils.spacing(context, 10)),
                Expanded(
                  child: Text(
                    tr(context, 'language_changed_immediately'),
                    style: TextStyle(
                      fontFamily: 'TT Fors',
                      fontSize: ResponsiveUtils.fontSize(context, 13),
                      color: AppColors.accent(context, Color(0xFF5F2D82)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}