import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = getIt<AppPreferencesService>().appLanguage;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await getIt<AppPreferencesService>().setAppLanguage(_selected);
    if (mounted) {
      setState(() => _saving = false);
      SnackBarUtils.showSuccess(
        context,
        _selected == 'tl'
            ? 'Nai-save ang wika. I-restart ang app kung kailangan.'
            : 'Language saved. Restart the app if labels do not update.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: const Color(0xFF5F2D82),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
        children: [
          RadioListTile<String>(
            title: const Text('English'),
            subtitle: const Text('Default app language'),
            value: 'en',
            groupValue: _selected,
            activeColor: const Color(0xFF5F2D82),
            onChanged: (v) => setState(() => _selected = v!),
          ),
          RadioListTile<String>(
            title: const Text('Filipino / Tagalog'),
            subtitle: const Text('Mas madaling maintindihan para sa mga user sa PH'),
            value: 'tl',
            groupValue: _selected,
            activeColor: const Color(0xFF5F2D82),
            onChanged: (v) => setState(() => _selected = v!),
          ),
          SizedBox(height: ResponsiveUtils.spacing(context, 24)),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5F2D82),
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save language'),
          ),
        ],
      ),
    );
  }
}
